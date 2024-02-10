process TIFFSERIES_TO_N5 {
    tag "${meta.id}"
    container "ghcr.io/janeliascicomp/n5-tools-spark:9097071"
    cpus { spark.driver_cores }
    memory { spark.driver_memory }

    input:
    tuple val(meta),
          path(input_path),
          path(output_path),
          val(output_name),
          val(output_dataset),
          val(spark)

    output:
    tuple val(meta),
          path(input_path), 
          path(output_n5),
          val(output_dataset), 
          val(spark), 
          emit: results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    extra_args = task.ext.args ?: ''
    output_n5 = "${output_path}/${output_name}"
    executor_memory = spark.executor_memory.replace(" KB",'k').replace(" MB",'m').replace(" GB",'g').replace(" TB",'t')
    driver_memory = spark.driver_memory.replace(" KB",'k').replace(" MB",'m').replace(" GB",'g').replace(" TB",'t')
    """
    INPUT_PATH=\$(realpath ${input_path})
    OUTPUT_N5=\$(realpath ${output_n5})
    /opt/scripts/runapp.sh "$workflow.containerEngine" "$spark.work_dir" "$spark.uri" \
        /app/app.jar org.janelia.saalfeldlab.n5.spark.SliceTiffToN5Spark \
        $spark.parallelism $spark.worker_cores "$executor_memory" $spark.driver_cores "$driver_memory" \
        -i \$INPUT_PATH -n \$OUTPUT_N5 -o ${output_dataset} ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spark: \$(cat /opt/spark/VERSION)
        n5-spark: \$(cat /app/VERSION)
    END_VERSIONS
    """
}
