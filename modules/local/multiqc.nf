process MULTIQC {
  publishDir "${params.outdir}/MultiQC", mode: params.publish_dir_mode

  input:
  path(multiqc_config)
  path('samtools/*')
  path('mosdepth/*')
  path('bcftools/*')
  path('snpeff/*')
  path('consensus/*')
  path('pangolin/*')
  path('tree/*')
  path('software_versions/*')
  path(workflow_summary)

  output:
  path "*multiqc_report.html", emit: multiqc_report
  path "*_data"
  path "multiqc_plots"

  script:
  custom_runName = params.name
  if (!(workflow.runName ==~ /[a-z]+_[a-z]+/)) {
    custom_runName = workflow.runName
  }
  rtitle = custom_runName ? "--title \"$custom_runName\"" : ''
  rfilename = custom_runName ? "--filename " + custom_runName.replaceAll('\\W','_').replaceAll('_+','_') + "_multiqc_report" : ''
  custom_config_file = params.multiqc_config ? "--config $mqc_custom_config" : ''
  """
  multiqc -f $rtitle $rfilename $custom_config_file .
  """
}

process CONSENSUS_TO_MULTIQC_HTML {
  input:
  path(fastas)

  output:
  path('consensus_mqc.html')

  script:
  """
  mqc_embed_file_html.py \\
    --id consensus \\
    --name 'Consensus sequence FASTA files' \\
    --desc 'This section contains the consensus sequences FASTA files for each sample.' \\
    consensus_mqc.html \\
    $fastas
  """
}
