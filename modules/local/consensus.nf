process CONSENSUS {
  tag "$sample"
  publishDir "${params.outdir}/consensus",
    mode: params.publish_dir_mode

  input:
  tuple val(sample),
        path(ref_fasta),
        path(vcf),
        path(mosdepth_per_base)
  val(low_coverage)

  output:
  tuple val(sample), path(consensus)

  script:
  consensus = "${sample}.consensus.fasta"
  """
  bgzip -c $vcf > ${vcf}.gz
  tabix ${vcf}.gz
  zcat $mosdepth_per_base | awk '\$4<${low_coverage}' > low_cov.bed
  bcftools consensus \\
    -f $ref_fasta \\
    -m low_cov.bed \\
    ${vcf}.gz > $consensus
  sed -i -E "s/^>(.*)/>$sample/g" $consensus
  """
}
