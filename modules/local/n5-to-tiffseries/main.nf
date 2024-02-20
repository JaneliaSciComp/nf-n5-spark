process N5_TO_TIFFSERIES {
    tag "${meta.id}"
    container "ghcr.io/janeliascicomp/n5-tools-spark:9097071"
    cpus { spark.driver_cores }
    memory { spark.driver_memory }

    input:
    tuple val(meta),
          path(input_n5),
          val(input_dataset),
          path(output_path),
          val(spark)

    output:
    tuple val(meta),
          path(input_n5),
          val(input_dataset),
          path(output_path),
          val(spark), 
          emit: results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    extra_args = task.ext.args ?: ''
    executor_memory = spark.executor_memory.replace(" KB",'k').replace(" MB",'m').replace(" GB",'g').replace(" TB",'t')
    driver_memory = spark.driver_memory.replace(" KB",'k').replace(" MB",'m').replace(" GB",'g').replace(" TB",'t')
    """
    INPUT_N5=\$(realpath ${input_n5})
    OUTPUT_PATH=\$(realpath ${output_path})
    /opt/scripts/runapp.sh "$workflow.containerEngine" "$spark.work_dir" "$spark.uri" \
        /app/app.jar org.janelia.saalfeldlab.n5.spark.N5ToSliceTiffSpark \
        $spark.parallelism $spark.worker_cores "$executor_memory" $spark.driver_cores "$driver_memory" \
        -n \$INPUT_N5 -i ${input_dataset} -o \$OUTPUT_PATH ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spark: \$(cat /opt/spark/VERSION)
        n5-spark: \$(cat /app/VERSION)
    END_VERSIONS
    """
}
