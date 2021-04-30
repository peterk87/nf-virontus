process PREPARE_FASTA_FOR_PANGOLIN {
  input:
  tuple val(sample), path(fasta)

  output:
  path(output)

  script:
  output = "${sample}.fasta"
  """
  cat $fasta > $output
  sed -i 's/^>.*/>${sample}/g' $output
  """
}

process PANGOLIN {
  label 'process_low'

  conda (params.enable_conda ? 'bioconda::pangolin=2.3.6' : null)
  if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
    container 'https://depot.galaxyproject.org/singularity/pangolin:2.3.6--py_0'
  } else {
    container 'quay.io/biocontainers/pangolin:2.3.6--py_0'
  }

  publishDir "${params.outdir}/pangolin",
             mode: params.publish_dir_mode

  input:
  path(fasta)

  output:
  path(output), emit: lineage_report
  path('pangolin.log')
  path('pangolin.version.txt')

  script:
  output = "pangolin.lineage_report.csv"
  """
  pangolin \\
    --verbose \\
    $fasta \\
    --outfile $output
  pangolin --version | sed "s/pangolin //g" > pangolin.version.txt
  ln -s .command.log pangolin.log
  """
}

process PANGOLIN_SUMMARY_FOR_MULTIQC {
  input:
  path(input)

  output:
  path("pangolin_mqc.txt")

  script:
  """
  summarize_pangolin_results.py ./ pangolin_mqc.txt
  """
}
