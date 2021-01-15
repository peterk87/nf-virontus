process COVERAGE_PLOT {
  publishDir "${params.outdir}/plots", 
    pattern: '*.pdf',
    mode: 'copy'

  input:
  tuple val(sample),
        path(ref_fasta),
        path(filt_vcf),
        path(depths)
  
  output:
  path("*.pdf")

  script:
  ref_name = ref_fasta.getBaseName()
  plot_filename = "coverage_plot-${sample}-VS-${ref_name}.pdf"
  log_scale_plot_filename = "coverage_plot-${sample}-VS-${ref_name}-log_scale.pdf"
  """
  plot_coverage.py -d $depths -v $filt_vcf -o $plot_filename
  plot_coverage.py -d $depths -v $filt_vcf -o $log_scale_plot_filename --log-scale-y
  """
}