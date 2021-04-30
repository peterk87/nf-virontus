process MOSDEPTH_GENOME {
  tag "$sample"
  label 'process_medium'

  conda (params.enable_conda ? 'bioconda::mosdepth=0.3.1' : null)
  if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
      container "https://depot.galaxyproject.org/singularity/mosdepth:0.3.1--ha7ba039_0"
  } else {
      container "quay.io/biocontainers/mosdepth:0.3.1--ha7ba039_0"
  }

  publishDir "${params.outdir}/mosdepth", 
             mode: params.publish_dir_mode,
             saveAs: { filename ->
               if (filename.endsWith(".pdf")) "plots/$filename"
               else if (filename.endsWith(".tsv")) "plots/$filename"
               else filename
             }

  input:
  tuple val(sample), path(bam)

  output:
  tuple val(sample), path("*.per-base.bed.gz"), emit: bedgz
  path "*.global.dist.txt", emit: mqc
  path "*.{txt,gz,csi,tsv}"

  script:
  """
  mosdepth \\
      --fast-mode \\
      $sample \\
      ${bam[0]}
  """
}
