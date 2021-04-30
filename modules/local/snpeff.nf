// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process SNPEFF_BUILD {
    tag "$fasta"
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ? 'bioconda::snpeff=5.0' : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container 'https://depot.galaxyproject.org/singularity/snpeff:5.0--0'
    } else {
        container 'quay.io/biocontainers/snpeff:5.0--0'
    }

    input:
    path fasta
    path gff

    output:
    path 'snpeff_db'    , emit: db
    path '*.config'     , emit: config
    path '*.version.txt', emit: version

    script:
    def software = getSoftwareName(task.process)
    def basename = fasta.baseName
    """
    mkdir -p snpeff_db/genomes/
    cd snpeff_db/genomes/
    ln -s ../../$fasta ${basename}.fa
    cd ../../
    mkdir -p snpeff_db/${basename}/
    cd snpeff_db/${basename}/
    ln -s ../../$gff genes.gff
    cd ../../
    echo "${basename}.genome : ${basename}" > snpeff.config
    snpEff build -config snpeff.config -dataDir ./snpeff_db -gff3 -v ${basename}
    echo \$(snpEff -version 2>&1) | sed 's/^.*SnpEff //; s/ .*\$//' > ${software}.version.txt
    """
}

// TODO: split snpsift and simpler_snpsift.py into processes
process SNPEFF_ANN {
  tag "$sample"
  label 'process_medium'
  publishDir "${params.outdir}/variants/snpeff",
    mode: params.publish_dir_mode

  conda (params.enable_conda ? 'bioconda::snpeff=5.0' : null)
  if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
    container 'https://depot.galaxyproject.org/singularity/snpeff:5.0--0'
  } else {
    container 'quay.io/biocontainers/snpeff:5.0--0'
  }

  input:
  tuple val(sample),
        path(ref_fasta),
        path(vcf)
  tuple val(index_base),
        path(db),
        path(config)

  output:
  path "${sample}.snpEff.csv", emit: csv
  path "*.vcf.gz*", emit: vcfgz
  path "*.{txt,html}", emit: report
  tuple val(sample), path("*.tsv"), emit: table

  script:
  """
  snpEff ${index_base} \\
    -config $config \\
    -dataDir $db \\
    ${vcf} \\
    -csvStats ${sample}.snpEff.csv \\
    | bgzip -c > ${sample}.snpEff.vcf.gz
  tabix -p vcf -f ${sample}.snpEff.vcf.gz
  mv snpEff_summary.html ${sample}.snpEff.summary.html

  echo \$(snpEff -version 2>&1) | sed 's/^.*SnpEff //; s/ .*\$//' > ${software}.version.txt

  SnpSift extractFields -s "," \\
    -e "." \\
    ${sample}.snpEff.vcf.gz \\
    CHROM POS REF ALT DP AC \\
    "ANN[*].GENE" "ANN[*].GENEID" \\
    "ANN[*].IMPACT" "ANN[*].EFFECT" \\
    "EFF[*].CODON" "EFF[*].AA" \\
    "ANN[*].CDNA_POS" "ANN[*].CDNA_LEN" \\
    "ANN[*].CDS_POS" "ANN[*].CDS_LEN" "ANN[*].AA_POS" \\
    "ANN[*].AA_LEN" \\
    > ${sample}.snpSift.table.txt
  simpler_snpsift.py ${sample}.snpSift.table.txt ${sample}.snpSift.simple.tsv
  """
}
