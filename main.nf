#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    JaneliaSciComp/nf-n5-spark
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/JaneliaSciComp/nf-n5-spark
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl=2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE & PRINT PARAMETER SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { validateParameters; paramsHelp } from 'plugin/nf-validation'

// Print help message if needed
if (params.help) {
    def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
    def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
    def String command = "nextflow run ${workflow.manifest.name} --indir /path/to/tiffs --outdir ./output -profile singularity"
    log.info logo + paramsHelp(command) + citation + NfcoreTemplate.dashedLine(params.monochrome_logs)
    System.exit(0)
}

// Validate input parameters
if (params.validate_params) {
    validateParameters()
}

def final_params = WorkflowMain.initialise(workflow, params, log)

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SPARK_START                 } from './subworkflows/janelia/spark_start/main'
include { SPARK_STOP                  } from './subworkflows/janelia/spark_stop/main'
include { TIFFSERIES_TO_N5            } from './modules/local/tiffseries-to-n5/main'
include { N5_TO_TIFFSERIES            } from './modules/local/n5-to-tiffseries/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './modules/nf-core/custom/dumpsoftwareversions/main'

workflow N5SPARK {
    ch_versions = Channel.empty()

    meta = [:]
    meta.id = "input"
    meta.spark_work_dir = "${final_params.outdir}/spark/${workflow.sessionId}/${meta.id}"
    ch_input = Channel.of([meta])
    spark_mounted_dirs = [final_params.indir, final_params.outdir]

    SPARK_START(
        ch_input,
        spark_mounted_dirs,
        params.spark_cluster,
        params.spark_workers as int,
        params.spark_worker_cores as int,
        params.spark_gb_per_core as int,
        params.spark_driver_cores as int,
        params.spark_driver_memory
    )

    def n5_attr = file(params.indir).resolve('attributes.json')
    if (n5_attr.exists()) {
        convert_out = N5_TO_TIFFSERIES(SPARK_START.out.map {
            def (meta, files, spark) = it
            [meta, final_params.indir, params.input_dataset, final_params.outdir, spark]
        })
        ch_versions = ch_versions.mix(N5_TO_TIFFSERIES.out.versions)
    }
    else {
        convert_out = TIFFSERIES_TO_N5(SPARK_START.out.map {
            def (meta, files, spark) = it
            [meta, final_params.indir, final_params.outdir, params.output_name, params.output_dataset, spark]
        })
        ch_versions = ch_versions.mix(TIFFSERIES_TO_N5.out.versions)
    }

    done = SPARK_STOP(convert_out.results.map {
        def (meta, input_path, output_n5, output_dataset, spark) = it
        [meta, spark_mounted_dirs, spark]
    })

    //
    // MODULE: Pipeline reporting
    //
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
}

workflow {
    N5SPARK()
}

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}
