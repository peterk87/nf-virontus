#!/usr/bin/env python

import re


regexes = {
    "peterk87/nf-virontus": ["v_pipeline.txt", r"(\S+)"],
    "Nextflow": ["v_nextflow.txt", r"(\S+)"],
    "MultiQC": ["v_multiqc.txt", r"multiqc, version (\S+)"],
    "Minimap2": ["v_minimap2.txt", r"(\S+)"],
    "iVar": ["v_ivar.txt", r"iVar version (\S+)"],
    "samtools": ["v_samtools.txt", r"samtools (\S+)"],
    "bcftools": ["v_bcftools.txt", r"bcftools (\S+)"],
    "Medaka": ["v_medaka.txt", r"medaka (\S+)"],
    "Longshot": ["v_longshot.txt", r"Longshot (\S+)"],
    "Python": ["v_python.txt", r"Python (\S+)"],
    "SnpSift": ["v_snpsift.txt", r"SnpSift version (\S+)"],
    "SnpEff": ["v_snpeff.txt", r"SnpEff\s+(\S+)"],
    "pigz": ["v_pigz.txt", r"pigz (\S+)"],
}
results = {k: '<span style="color:#999999;">N/A</span>' for k, v in regexes.items()}

# regex to remove ANSI escape sequences from strings
reaesc = re.compile(r'\x1b[^m]*m')

# Search each file using its regex
for k, (fname, regex) in regexes.items():
    try:
        with open(fname) as x:
            versions = x.read()
            versions = reaesc.sub('', versions)
            match = re.search(regex, versions)
            if match:
                results[k] = f"v{match.group(1)}"
    except IOError:
        results[k] = False

# Remove software set to false in results
for k in list(results):
    if not results[k]:
        del results[k]

# Dump to YAML
print(
    """
id: 'software_versions'
section_name: 'peterk87/nf-virontus Software Versions'
section_href: 'https://github.com/peterk87/nf-virontus'
plot_type: 'html'
description: 'are collected at run time from the software output.'
data: |
    <dl class="dl-horizontal">
"""
)
# adjust width and left margin of dt and dd elements to fit text content without ellipsis
for k, v in results.items():
    print(f"""        <dt style=\"width:200px !important;\">
        {k}
        </dt>
        <dd style=\"margin-left:220px !important;\"><samp>
        {v}
        </samp></dd>""")
print("    </dl>")

# Write out regexes as csv file:
with open("software_versions.csv", "w") as f:
    for k, v in results.items():
        f.write(f"{k}\t{v}\n")
