process MEDAKA_LONGSHOT {
  tag "$sample - $ref_name"
  label "process_low"
  publishDir "${params.outdir}/variants", 
    mode: params.publish_dir_mode

  input:
  tuple val(sample),
        path(ref_fasta),
        path(bam)
  
  output:
  tuple val(sample),
        path(ref_fasta),
        path(vcf)
  
  script:
  ref_name = ref_fasta.getBaseName()
  vcf = "${sample}-${ref_name}.longshot.vcf"
  """
  samtools faidx $ref_fasta
  medaka consensus \\
    --chunk_len $params.medaka_chunk_len \\
    --chunk_ovlp $params.medaka_chunk_overlap \\
    ${bam[0]} \\
    medaka.hdf
  medaka variant \\
    $ref_fasta \\
    medaka.hdf \\
    medaka.vcf
  longshot \\
    -P 0 \\
    -F \\
    -A \\
    --no_haps \\
    --potential_variants medaka.vcf \\
    --bam ${bam[0]} \\
    --ref $ref_fasta \\
    --out $vcf
  """
}

process BCFTOOLS_STATS {
  tag "$sample - $ref_name"
  publishDir "${params.outdir}/variants/bcftools_stats", 
    mode: params.publish_dir_mode
  
  input:
  tuple val(sample),
        path(ref_fasta),
        path(vcf)

  output:
  path("*.bcftools_stats.txt")

  script:
  """
  bcftools stats -F $ref_fasta $vcf > ${sample}.bcftools_stats.txt
  """
}

process VARIANT_FILTER {
  tag "$sample - $ref_name"

  publishDir "${params.outdir}/variants",
    pattern: "*.filt.vcf",
    mode: params.publish_dir_mode

  input:
  tuple val(sample),
        path(ref_fasta),
        path(vcf)
  val allele_fraction
  
  output:
  tuple val(sample),
        path(ref_fasta),
        path(filt_vcf)
  script:
  ref_name = ref_fasta.getBaseName()
  filt_vcf = "${file(vcf).getBaseName()}.norm.${allele_fraction}AF.filt.vcf"
  """
  # split multiallelic calls into multiple rows
  bcftools norm \\
    -Ov \\
    -m- \\
    -f $ref_fasta \\
    $vcf \\
    > norm.vcf
  # filter for major alleles 
  bcftools filter \\
    -e 'AF < $allele_fraction' \\
    norm.vcf \\
    -Ov \\
    -o filt.vcf
  # filter out variants introducing potential frameshifts
  vcf_filter_frameshift.py filt.vcf $filt_vcf
  """
}