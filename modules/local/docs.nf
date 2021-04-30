process SOFTWARE_VERSIONS {
  tag "Parse software version numbers"
  publishDir "${params.outdir}/pipeline_info", mode: params.publish_dir_mode,
      saveAs: { filename ->
                  if (filename.indexOf(".csv") > 0) filename
                  else null
              }

  output:
  path 'software_versions_mqc.yaml', emit: software_versions_yaml
  path "software_versions.csv"

  script:
  """
  echo $workflow.manifest.version > v_pipeline.txt
  echo $workflow.nextflow.version > v_nextflow.txt
  python --version > v_python.txt
  multiqc --version > v_multiqc.txt
  minimap2 --version > v_minimap2.txt
  ivar version > v_ivar.txt
  kraken2 --version > v_kraken2.txt
  medaka --version > v_medaka.txt
  longshot --version > v_longshot.txt
  samtools --version > v_samtools.txt
  bcftools --version > v_bcftools.txt
  snpEff -version > v_snpeff.txt
  set +e
  SnpSift &> v_snpsift.txt
  set -e
  pigz --version 2> v_pigz.txt
  scrape_software_versions.py &> software_versions_mqc.yaml
  """
}
