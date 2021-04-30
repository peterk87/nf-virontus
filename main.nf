#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include {
  checkFileExists;
  checkKraken2Db;
  check_sample_sheet;
} from './lib/helpers'

def json_schema = "$projectDir/nextflow_schema.json"
// Show help message if --help specified
if (params.help){
  def command = "nextflow run peterk87/nf-virontus --input samplesheet.csv --genome 'MN908947.3' --artic_v3 -profile docker"
  log.info NfcoreSchema.params_help(workflow, params, json_schema, command)
  exit 0
}

//=============================================================================
// CHECK PARAMS
//=============================================================================

if (params.validate_params) {
  NfcoreSchema.validateParameters(params, json_schema, log)
}

if (workflow.profile == 'slurm' && params.slurm_queue == "") {
  log.error "You must specify a valid SLURM queue (e.g. '--slurm_queue <queue name>' (see `\$ sinfo` output for available queues)) to run this workflow with the 'slurm' profile!"
  exit 1
}

if (params.kraken2_db) {
  checkKraken2Db(params.kraken2_db)
}

// Has the run name been specified by the user?
//  this has the bonus effect of catching both -name and --name
custom_runName = params.name
if( !(workflow.runName ==~ /[a-z]+_[a-z]+/) ){
  custom_runName = workflow.runName
}

// courtesy of nf-core/viralrecon (https://github.com/nf-core/viralrecon)
genome = params.genome
fasta = params.fasta
gff = params.gff
primer_bed = params.primer_bed
// Viral reference files
if (params.scov2) {
  genome = 'MN908947.3'
  fasta = params.genomes[genome].fasta
  gff = params.genomes[genome].gff
}
if (params.genomes && genome && !params.genomes.containsKey(genome)) {
  exit 1, "The provided genome '${genome}' is not available in the Genome file. Currently the available genomes are ${params.genomes.keySet().join(", ")}"
}
if (!fasta || fasta == null) {
  fasta = genome ? params.genomes[genome].fasta : false
}
if (!gff || gff == null) { 
  gff = genome ? params.genomes[genome].gff : false
}
if (fasta) {
  file(fasta, checkIfExists: true)

  lastPath = fasta.lastIndexOf(File.separator)
  lastExt = fasta.lastIndexOf(".")
  fasta_base = fasta.substring(lastPath+1)
  index_base = fasta.substring(lastPath+1,lastExt)
  if (fasta.endsWith('.gz')) {
      fasta_base = fasta.substring(lastPath+1,lastExt)
      index_base = fasta_base.substring(0,fasta_base.lastIndexOf("."))
  }
} else {
  exit 1, "Viral genome fasta file not specified!"
}

if (genome == 'MN908947.3' && !primer_bed) {
  if (params.artic_v3) {
    primer_bed = params.genomes[genome]['primer_schemes']['artic_v3']
  } else if (params.freed) {
    primer_bed = params.genomes[genome]['primer_schemes']['freed']
  } else {
    log.warn "Using SARS-CoV-2 ${genome} as reference genome with no primer BED file. Primers will not be trimmed since they are not specified. You can specify a custom primer scheme in BED file format or use one of the built-in primer schemes: ${params.genomes[genome]['schemes'].keySet().join(', ')}"
  }
}

def modules = params.modules.clone()

//=============================================================================
// LOG PARAMS SUMMARY
//=============================================================================

def summary_params = NfcoreSchema.params_summary_map(workflow, params, json_schema)
log.info NfcoreSchema.params_summary_log(workflow, params, json_schema)


//=============================================================================
// PROCESSES
//=============================================================================
// TODO: update paths, process names, etc
include { SOFTWARE_VERSIONS             } from './modules/local/docs'
include { CHECK_SAMPLE_SHEET; CAT_FASTQ } from './modules/local/misc'

include { MAP                           } from './modules/local/mapping'
include { MOSDEPTH_GENOME               } from './modules/local/mosdepth'
include { IVAR_TRIM                     } from './modules/local/ivar'
include {
  MEDAKA_LONGSHOT;
  VARIANT_FILTER as VARIANT_FILTER_MAJOR;
  VARIANT_FILTER as VARIANT_FILTER_MINOR;
  BCFTOOLS_STATS as BCFTOOLS_STATS_PRE_FILTER;
  BCFTOOLS_STATS as BCFTOOLS_STATS_POST_FILTER
} from './modules/local/variants'
include { MAKE_SNPEFF_DB; SNPEFF             } from './modules/local/snpeff'
include { CONSENSUS                          } from './modules/local/consensus'
include { COVERAGE_PLOT                      } from './modules/local/plots'
include { MULTIQC; CONSENSUS_TO_MULTIQC_HTML } from './modules/local/multiqc'

include { PYCOQC      } from './modules/nf-core/software/pycoqc/main'         addParams( options: modules['pycoqc'] )
include { NANOPLOT    } from './modules/nf-core/software/nanoplot/main'       addParams( options: modules['nanoplot'] )
include { KRAKEN2_RUN } from './modules/nf-core/software/kraken2/run'         addParams( options: modules['kraken2'] )

//=============================================================================
// MAIN WORKFLOW
//=============================================================================
workflow {

  ch_software_versions = Channel.empty()
  // If sample sheet table provided, 
  //   - validate and write to CSV sample sheet
  //   - use 'check_sample_sheet' method to fetch files for each sample 
  //     (e.g. all FASTQ files within a Guppy barcoding output directory like 
  //     'barcode01/')
  //   - concatenate multiple FASTQs and gzip compress into single fastq.gz 
  //     per sample
  //   - add in reads specified by '--reads' CLI parameter
  Channel.from(file(params.input, checkIfExists: true)) \
    | CHECK_SAMPLE_SHEET \
    | splitCsv(header: ['sample', 'reads'], sep: ',', skip: 1) \
    | map { check_sample_sheet(it) } \
    | CAT_FASTQ \
    | map { sample, reads -> [[id: sample, single_end: true], reads]}
    | set {ch_reads}

  if (params.sequencing_summary && !params.skip_pycoqc) {
    PYCOQC(ch_sequencing_summary)
  }
  ch_software_versions = ch_software_versions.mix(PYCOQC.out.version.ifEmpty(null))

  // Nanoplot read level QC
  if (!params.skip_nanoplot) {
    NANOPLOT(ch_reads)
    NANOPLOT.out.version | view
  }
  ch_software_versions = ch_software_versions.mix(NANOPLOT.out.version.ifEmpty(null))

  // reference fasta into channel
  ch_fasta = Channel.value(file(fasta))
  // if reference GFF specified, create SnpEff DB
  if (gff) {
    MAKE_SNPEFF_DB(Channel.value([index_base, file(fasta), file(gff)]))
  }
  // Optional host subtraction with Kraken2
  if (params.kraken2_db && !params.skip_kraken2) {
    KRAKEN2_RUN(file(params.kraken2_db), ch_reads)
    if (params.subtract_host) {
      KRAKEN2_RUN.out.unclassified | combine(ch_fasta) | MAP
    } else {
      ch_reads | combine(ch_fasta) | MAP
    }
  } else {
    // Map reads to reference
    ch_reads | combine(ch_fasta) | MAP
  }

  // Trim primer sequences from read alignments if primer scheme BED file provided 
  if (primer_bed) {
    IVAR_TRIM(Channel.value(file(primer_bed)), MAP.out.bam)
    ch_bam = IVAR_TRIM.out.bam
    ch_depths = IVAR_TRIM.out.depths
  } else {
    ch_bam = MAP.out.bam
    ch_depths = MAP.out.depths
  }
  // only interested in sample name [0] and bam [2] for mosdepth
  ch_bam | map {[it[0], it[2]]} | MOSDEPTH_GENOME
  // variant calling and stats
  MEDAKA_LONGSHOT(ch_bam)
  VARIANT_FILTER_MINOR(MEDAKA_LONGSHOT.out, params.minor_allele_fraction) \
    | BCFTOOLS_STATS_PRE_FILTER
  if (gff) {
    SNPEFF(VARIANT_FILTER_MINOR.out, MAKE_SNPEFF_DB.out)
    ch_snpeff = SNPEFF.out.csv | collect
  } else {
    ch_snpeff = Channel.from([])
  }
  VARIANT_FILTER_MAJOR(MEDAKA_LONGSHOT.out, params.major_allele_fraction)
  VARIANT_FILTER_MAJOR.out | BCFTOOLS_STATS_POST_FILTER
  VARIANT_FILTER_MAJOR.out | join(ch_depths) | COVERAGE_PLOT

  ch_consensus_input = VARIANT_FILTER_MAJOR.out | join(MOSDEPTH_GENOME.out.bedgz)
  CONSENSUS(ch_consensus_input, params.low_coverage)

  CONSENSUS.out | map { it[1] } | collect | CONSENSUS_TO_MULTIQC_HTML

  if (genome == 'MN908947.3') {
    include {
      PREPARE_FASTA_FOR_PANGOLIN;
      PANGOLIN;
      PANGOLIN_SUMMARY_FOR_MULTIQC
    } from './processes/pangolin'
    if (params.tree_extra_fasta) {
      ch_extra_fasta_with_sample_name = Channel.fromPath(params.tree_extra_fasta).splitFasta(file: true) \
        | map {
          f = file(it)
          m = f.text =~ /^>(\S+).*/
          sample = m[0][1]
          sample = sample.replaceAll(/[^\w\-]/, "_")
          [sample, it]
        }
      ch_fasta_for_pangolin = CONSENSUS.out | mix(ch_extra_fasta_with_sample_name)
    } else {
      ch_fasta_for_pangolin = CONSENSUS.out
    }
    ch_fasta_for_pangolin \
      | PREPARE_FASTA_FOR_PANGOLIN \
      | collectFile(name: "sequences.fasta", newLine: true) \
      | PANGOLIN 
    PANGOLIN_SUMMARY_FOR_MULTIQC(PANGOLIN.out.lineage_report)
    ch_pangolin = PANGOLIN.out.lineage_report
    ch_pangolin_mqc = PANGOLIN_SUMMARY_FOR_MULTIQC.out
  } else {
    ch_pangolin = Channel.from([])
    ch_pangolin_mqc = Channel.from([])
  }

  if (params.tree) {
    include { MAFFT_MSA } from './processes/msa'
    include { IQTREE } from './processes/iqtree'
    include { BASIC_TREE_PLOT } from './processes/plots'
    // TODO: only run tree when number of samples is at least 2; IQ-TREE will only run if at least 3 sequences are provided as input
    ch_consensi = CONSENSUS.out | map { it[1] }
    if (params.tree_extra_fasta) {
      ch_extra_fasta = Channel.fromPath(params.tree_extra_fasta).splitFasta(file: true)
      ch_fasta_for_mafft = ch_consensi | mix(ch_extra_fasta) | collect
    } else {
      ch_fasta_for_mafft = ch_consensi | collect
    }
    MAFFT_MSA(ch_fasta_for_mafft, ch_fasta)
    IQTREE(MAFFT_MSA.out, Channel.value(params.iqtree_model))
    BASIC_TREE_PLOT(IQTREE.out, ch_pangolin)
    ch_basic_tree_plot = BASIC_TREE_PLOT.out
    // TODO: shiptv
    // TODO: merge optionally specified metadata
  } else {
    ch_basic_tree_plot = Channel.from([])
  }

  workflow_summary    = Schema.params_summary_multiqc(workflow, summary_params)
  ch_workflow_summary = Channel.value(workflow_summary)
  SOFTWARE_VERSIONS()
  ch_multiqc_config = Channel.fromPath("$projectDir/assets/multiqc_config.yaml")
  MULTIQC(
   ch_multiqc_config,
   MAP.out.stats.collect().ifEmpty([]),
   MOSDEPTH_GENOME.out.mqc.collect().ifEmpty([]),
   BCFTOOLS_STATS_POST_FILTER.out.collect().ifEmpty([]),
   ch_snpeff.ifEmpty([]),
   CONSENSUS_TO_MULTIQC_HTML.out.collect().ifEmpty([]),
   ch_pangolin_mqc.ifEmpty([]),
   ch_basic_tree_plot.ifEmpty([]),
   SOFTWARE_VERSIONS.out.software_versions_yaml.collect(),
   ch_workflow_summary.collectFile(name: "workflow_summary_mqc.yaml")
  )
}

//=============================================================================
// INTROSPECTION
//=============================================================================
workflow.onComplete {
    println """
    Pipeline execution summary
    ---------------------------
    Completed at : ${workflow.complete}
    Duration     : ${workflow.duration}
    Success      : ${workflow.success}
    Results Dir  : ${file(params.outdir)}
    Work Dir     : ${workflow.workDir}
    Exit status  : ${workflow.exitStatus}
    Error report : ${workflow.errorReport ?: '-'}
    """.stripIndent()
}

workflow.onError {
    println "Oops... Pipeline execution stopped with the following message: ${workflow.errorMessage}"
}
