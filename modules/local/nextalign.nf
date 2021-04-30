// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process NEXTALIGN {
  label 'process_high'

  publishDir "${params.outdir}",
      mode: params.publish_dir_mode,
      saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:[:], publish_by_meta:[]) }

  conda (params.enable_conda ? 'bioconda::nextalign=0.2.0' : null)
  if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
    container 'https://depot.galaxyproject.org/singularity/nextalign:0.2.0--h9ee0642_1'
  } else {
    container 'quay.io/biocontainers/nextalign:0.2.0--h9ee0642_1'
  }

  input:
  path(fastas)
  path(ref_fasta)

  output:
  path('nextalign.aligned.fasta'), emit: msa
  path('nextalign.insertions.csv'), emit: insertions
  path('*.version.txt'), emit: version

  script:
  def software = getSoftwareName(task.process)
  """
  # keep only the seq id; remove all other text after fasta seq id
  cat $fastas | sed -r 's/^>(\\S+)\\s.*/>\\1/g' > input.fasta
  nextalign \\
    -j ${task.cpus} \\
    --sequences=input.fasta \\
    --reference=$ref_fasta \\
    --output-dir=./ \\
    --output-basename=nextalign

  nextalign --version > ${software}.version.txt
  """
}
