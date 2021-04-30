process COVERAGE_PLOT {
  publishDir "${params.outdir}/plots/coverage",
    mode: params.publish_dir_mode

  input:
  tuple val(sample),
        path(ref_fasta),
        path(vcf),
        path(depths)
  
  output:
  path("*.pdf")

  script:
  ref_name = ref_fasta.getBaseName()
  prefix = "${sample}.${ref_name}.coverage"
  """
  # coverage plot with variants
  plot_coverage.py \\
    -d $depths \\
    -v $vcf \\
    --sample-name $sample \\
    --no-highlight \\
    --low-coverage ${params.low_coverage} \\
    -o ${prefix}.variants.pdf

  plot_coverage.py \\
    -d $depths \\
    -v $vcf \\
    --sample-name $sample \\
    --log-scale-y \\
    --no-highlight \\
    --low-coverage ${params.low_coverage} \\
    -o ${prefix}.variants.log-scale-y.pdf

  # coverage plot highlighting low/no coverage regions
  plot_coverage.py \\
    -d $depths \\
    --sample-name $sample \\
    --log-scale-y \\
    --low-coverage ${params.low_coverage} \\
    -o ${prefix}.log-scale-y.highlight-no-low-cov.pdf

  plot_coverage.py \\
    -d $depths \\
    --sample-name $sample \\
    --low-coverage ${params.low_coverage} \\
    -o ${prefix}.highlight-no-low-cov.pdf

  # coverage plot no highlighting
  plot_coverage.py \\
    -d $depths \\
    --sample-name $sample \\
    --log-scale-y \\
    --no-highlight \\
    --low-coverage ${params.low_coverage} \\
    -o ${prefix}.log-scale-y.pdf

  plot_coverage.py \\
    -d $depths \\
    --sample-name $sample \\
    --no-highlight \\
    --low-coverage ${params.low_coverage} \\
    -o ${prefix}.pdf
  """
}

process BASIC_TREE_PLOT {
  publishDir "${params.outdir}/plots/tree",
             mode: params.publish_dir_mode
  input:
  path(iqtree_output)
  path(pangolin_report)

  output:
  path(output)

  script:
  output = 'IQ-TREE_Maximum-Likelihood_Phylogenetic_Tree_mqc.png'
  pangolin_report_arg = pangolin_report ? "--pangolin-report $pangolin_report" : ""
  """
  plot_basic_tree.py tree-*.treefile $output $pangolin_report_arg
  """
}
