// check and convert user specified sample sheet into CSV for reading by Nextflow
// splitCsv channel operator
process CHECK_SAMPLE_SHEET {
  tag "$samplesheet"
  publishDir "${params.outdir}/pipeline_info", mode: params.publish_dir_mode

  input:
  path samplesheet

  output:
  path "samplesheet_reformat.csv" 

  script:
  """
  check_sample_sheet.py $samplesheet samplesheet_reformat.csv
  """
}

// Concatenate FASTQ files into single file and gzip compress with pigz if not
// already gzipped.
process CAT_FASTQ {
  tag "$sample"

  if (params.save_cat_reads) {
    publishDir "${params.outdir}/reads",
      pattern: "*.fastq.gz",
      mode: params.publish_dir_mode
  }
  
  input:
  tuple val(sample), path(reads)

  output:
  tuple val(sample), path(output)

  script:
  reads_list = reads.collect { it.toString() }
  output = "${sample}.fastq.gz"
  if (reads_list.size > 1) {
    if (reads_list[0].endsWith(".gz")) {
      """
      cat $reads > $output
      """
    } else {
      """
      cat $reads | pigz -ck > $output
      """
    }
  } else {
    if (reads_list[0].endsWith(".gz")) {
      """
      ln -s $reads $output
      """
    } else {
      """
      pigz -ck $reads > $output
      """
    }
  }
}
