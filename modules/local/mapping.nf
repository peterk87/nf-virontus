process MAP {
  tag "$sample VS $ref_name"
  label 'process_medium'
  publishDir "${params.outdir}/mapping/$sample",
    mode: params.publish_dir_mode
  
  input:
  tuple val(sample),
        path(fastq),
        path(ref_fasta)
  output:
  tuple val(sample),
        path(ref_fasta),
        path('*.{bam,bam.bai}'), emit: bam
  path '*.{flagstat,idxstats,stats}', emit: stats
  tuple val(sample), path('*-depths.tsv'), emit: depths

  script:
  ref_name = ref_fasta.getBaseName()
  bam = "${sample}.bam"
  """
  minimap2 \\
    -ax map-ont \\
    -t${task.cpus} \\
    $ref_fasta \\
    $fastq \\
    | samtools sort -@${task.cpus} \\
    > $bam
  samtools index $bam
  samtools stats $bam > ${sample}.stats
  samtools flagstat $bam > ${sample}.flagstat
  samtools idxstats $bam > ${sample}.idxstats
  samtools depth -a -d 0 $bam > ${sample}-depths.tsv
  """
}
