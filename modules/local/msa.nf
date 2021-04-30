process MAFFT_MSA {
  label 'process_medium'

  conda (params.enable_conda ? "bioconda::mafft=7.475" : null)
  if (workflow.containerEngine == 'singularity') {
    container "https://depot.galaxyproject.org/singularity/mafft:7.475--h779adbc_1"
  } else {
    container 'quay.io/biocontainers/mafft:7.475--h779adbc_1'
  }

  publishDir "${params.outdir}",
      mode: params.publish_dir_mode,
      saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:[:], publish_by_meta:[]) }

  input:
  path(fastas)
  path(ref_fasta)

  output:
  path('mafft.fasta'), emit: msa
  path('*.version.txt'), emit: version

  script:
  """
  # keep only the seq id; remove all other text after fasta seq id
  cat $fastas | sed -r 's/^>(\\S+)\\s.*/>\\1/g' > input.fasta
  mafft \\
    --thread ${task.cpus} \\
    --6merpair \\
    --addfragments input.fasta \\
    $ref_fasta > mafft.fasta

  """
}
