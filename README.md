# peterk87/nf-virontus

Oxford Nanopore viral sequence analysis pipeline.

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A520.04.0-brightgreen.svg)](https://www.nextflow.io/)
<!-- TODO: add badge for github actions -->
[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg)](http://bioconda.github.io/)

[![Docker](https://img.shields.io/docker/automated/peterk87/nf-virontus.svg)](https://hub.docker.com/r/peterk87/nf-virontus)

## Introduction

This pipeline performs read mapping and variant calling with [Minimap2] and [Medaka] with [Longshot] variant annotation. A consensus sequence is generated from major variants and variants that would not cause potential frameshift mutations using [Bcftools] with masking of low coverage depth regions with `N` characters.

Optionally, amplicon primers can be trimmed with [iVar] if a BED file of primer coordinates is supplied.

If read mapping against the SARS-CoV-2 reference genome Wuhan-Hu-1 ([MN908947.3](https://www.ncbi.nlm.nih.gov/nuccore/MN908947.3/)) is being performed, then [Pangolin] global SARS-CoV-2 lineage assignment will be performed.

## Installation

You will need to install [Nextflow] in order to run the Virontus pipeline.

> **NB:** [Singularity] or [Docker] is recommended for portable and reproducible execution of the pipeline with the `-profile singularity` or `-profile docker` command-line argument.

### 1) Install [Nextflow]

If you have [Conda] installed, you can install [Nextflow] with the following command:

```bash
conda install -c bioconda -c conda-forge nextflow
```

### 2) Install [Docker][] and/or [Singularity][]

Installing [Docker][] and/or [Singularity] is optional but recommended for portability and reproducibility of results.

### 3) Install Virontus

Nextflow will automatically download the latest version of Virontus. You can show the Virontus help message with usage information with:

```bash
nextflow run peterk87/nf-virontus --help
```

## Usage

Basic usage for mapping to SARS-CoV-2 reference genome [MN908947.3](https://www.ncbi.nlm.nih.gov/nuccore/MN908947.3/) and [ARTIC V3 protocol](https://github.com/artic-network/artic-ncov2019/tree/master/primer_schemes/nCoV-2019/V3) primers:

```bash
nextflow run peterk87/nf-virontus \
  --input samplesheet.csv \
  --genome MN908947.3 \
  --bed artic-ncov2019/primer_schemes/nCoV-2019/V3/nCoV-2019.bed
```

Can be simplified with:

```bash
nextflow run peterk87/nf-virontus \
  --input samplesheet.csv \
  --scov2 \
  --artic_v3
  # or `--freed` for Freed et al (2020) 1200bp amplicon method
```

Show usage information with

```bash
nextflow run peterk87/nf-virontus --help
```

> **NB:** See the [usage docs](docs/usage.md) for more info.

## Output

* [Concatenated FASTQ Reads](docs/output.md#concatenated-fastq-reads) - Concatenation and Gzip compression of FASTQ reads
* [Read Mapping](docs/output.md#read-mapping) - Read mapping using [Minimap2][] and read mapping stats calculation with [Samtools][]
* [Mosdepth](docs/output.md#mosdepth) - Coverage stats calculated by [Mosdepth][]
* [Variant Calling](docs/output.md#variant-calling) - Variant calling using the Oxford Nanopore Technologies variant caller [Medaka] with annotation by [Longshot].
* [Variant Filtering](docs/output.md#variant-filtering) - Variant filtering for major/minor variants is performed for SnpEff variant effect analysis, consensus sequence generation and high confidence variant statistics for MultiQC report.
* [SnpEff](docs/output.md#snpeff) - SnpEff variant effect analysis on major and minor variants.
* [Consensus Sequence](docs/output.md#consensus-sequence) - Consensus sequence with `N` masking of low/no coverage positions.
* [Pangolin](docs/output.md#pangolin) - SARS-CoV-2 global lineage assignment using [Pangolin][] if using SARS-CoV-2 Wuhan-Hu-1 MN908947.3 as reference.
* [Coverage Plots](docs/output.md#coverage-plots) - Coverage plots with/without low/no coverage and/or variants highlighted with linear and log10 scaling of y-axis depth values.
* [Phylogenetic Tree](docs/output.md#phylogenetic-tree) - [IQ-TREE] maximum-likelihood phylogenetic tree from [MAFFT] multiple sequence alignment of sample consensus sequences and user provided sequences with reference sequence set as outgroup.
* [MultiQC](docs/output.md#multiqc) - Aggregate report describing results from the whole pipeline
* [Pipeline information](docs/output.md#pipeline-information) - Report metrics generated during the workflow execution

See the [output docs](docs/output.md) for more info.

## Credits

peterk87/nf-virontus was originally written by Peter Kruczkiewicz.

Bootstrapped with [nf-core/tools](https://github.com/nf-core/tools) `nf-core create`.

Thank you to the [nf-core/tools](https://github.com/nf-core/tools) team for a great tool for bootstrapping creation of a production ready Nextflow workflows.

[Bcftools]: https://samtools.github.io/bcftools/bcftools.html
[Centrifuge]: https://ccb.jhu.edu/software/centrifuge/manual.shtml
[Conda]: https://conda.io/
[Docker]: https://www.docker.com/
[IQ-TREE]: http://www.iqtree.org/
[iVar]: https://github.com/andersen-lab/ivar
[Kraken2]: https://ccb.jhu.edu/software/kraken2/
[Longshot]: https://www.nature.com/articles/s41467-019-12493-y
[MAFFT]: https://mafft.cbrc.jp/alignment/software/
[Matplotlib]: https://matplotlib.org/
[Medaka]: https://github.com/nanoporetech/medaka
[Minimap2]: https://github.com/lh3/minimap2
[Mosdepth]: https://github.com/brentp/mosdepth
[MultiQC]: http://multiqc.info
[Nextflow]: https://www.nextflow.io
[Pangolin]: https://github.com/cov-lineages/pangolin/
[pigz]: https://www.zlib.net/pigz/
[Samtools]: https://www.htslib.org/
[seaborn]: https://seaborn.pydata.org/
[Singularity]: https://sylabs.io/guides/3.5/user-guide/
[SnpEff]: https://pcingola.github.io/SnpEff/
[SnpSift]: https://pcingola.github.io/SnpEff/ss_introduction/
[Unicycler]: https://github.com/rrwick/Unicycler
[vcf_consensus_builder]: https://github.com/peterk87/vcf_consensus_builder
