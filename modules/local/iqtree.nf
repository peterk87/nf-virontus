process IQTREE {
  label 'process_medium'
  container 'peterk87/iqtree:v2.1.2'

  publishDir "${params.outdir}/iqtree",
             mode: params.publish_dir_mode

  input:
  path("mafft.fasta")
  val(model)

  output:
  path('tree-*')

  script:
  """
  OUTGROUP=\$(head -n1 mafft.fasta | sed -r 's/>(\\S+)/\\1/')
  iqtree \\
    -s mafft.fasta \\
    -o \$OUTGROUP \\
    -T ${task.cpus} \\
    -ninit 2 \\
    -n 5 \\
    -me 1.0 \\
    -nt 4 \\
    -experimental \\
    -t NJ-R \\
    --no-opt-gamma-inv \\
    -m $model \\
    --prefix tree-\$OUTGROUP-${model}_model
  """
}
