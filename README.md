# nf-n5-spark

Nextflow pipeline wrapper for [saalfeldlab/n5-spark](https://github.com/saalfeldlab/n5-spark/). Currently it only supports converting a TIFF series into an N5.

## Quick Start

The only software requirements for running this pipeline are [Nextflow](https://www.nextflow.io) (version 20.10.0 or greater) and [Singularity](https://sylabs.io) (version 3.5 or greater). If you are running in an HPC cluster, ask your system administrator to install Singularity on all the cluster nodes.

To [install Nextflow](https://www.nextflow.io/docs/latest/getstarted.html):

    curl -s https://get.nextflow.io | bash 

Alternatively, you can install it as a conda package:

    conda create --name nextflow -c bioconda nextflow

To [install Singularity](https://sylabs.io/guides/3.7/admin-guide/installation.html) on CentOS Linux:

    sudo yum install singularity

Now you can run the pipeline and it will download everything else it needs:

    nextflow run JaneliaSciComp/nf-n5-spark --indir /path/to/tiffs --outdir ./output -profile singularity
