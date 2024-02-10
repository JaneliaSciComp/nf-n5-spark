//
// This file holds several functions specific to the main.nf workflow in the JaneliaSciComp/nf-n5-spark pipeline
//

import nextflow.Nextflow
import java.io.File

class WorkflowMain {

    //
    // Citation string for pipeline
    //
    public static String citation(workflow) {
        return "If you use ${workflow.manifest.name} for your analysis please cite:\n\n" +
            "* The N5 Spark tools\n" +
            "  https://github.com/saalfeldlab/n5-spark\n\n" +
            "* The nf-core framework\n" +
            "  https://doi.org/10.1038/s41587-020-0439-x\n\n" +
            "* Software dependencies\n" +
            "  https://github.com/${workflow.manifest.name}/blob/master/CITATIONS.md"
    }

    //
    // Validate parameters and print summary to screen
    //
    public static Tuple<String> initialise(workflow, params, log) {

        // Print workflow version and exit on --version
        if (params.version) {
            String workflow_version = NfcoreTemplate.version(workflow)
            log.info "${workflow.manifest.name} ${workflow_version}"
            System.exit(0)
        }

        // Check that a -profile or Nextflow config has been provided to run the pipeline
        NfcoreTemplate.checkConfigProvided(workflow, log)

        // Check AWS batch settings
        NfcoreTemplate.awsBatch(workflow, params)

        if (params.spark_workers > 1 && !params.spark_cluster) {
            Nextflow.error("You must enable --spark_cluster if --spark_workers is greater than 1.")
        }

        def indir_d = new File(params.indir)

        // Make indir absolute
        def indir = indir_d.toPath().toAbsolutePath().normalize().toString()

        def outdir_d = new File(params.outdir)
        if (!outdir_d.exists()) {
            Nextflow.error("The path specified by --outdir does not exist: "+params.outdir)
        }
        def output_n5_d = new File(outdir_d, params.output_name)
        if (output_n5_d.exists()) {
            Nextflow.error("The output N5 already exists: "+output_n5_d)
        }

        // Make outdir absolute
        def outdir = outdir_d.toPath().toAbsolutePath().normalize().toString()

        def Map final_params = [
            'indir': indir,
            'outdir': outdir
        ]

        return final_params
    }
}
