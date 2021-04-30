#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import sys
import logging
from io import TextIOWrapper
from os import PathLike
from pathlib import Path
from typing import TextIO, Union, Tuple

import typer
import pandas as pd
from rich.console import Console
from rich.logging import RichHandler


aa_codes = dict(
    ALA='A',
    ARG='R',
    ASN='N',
    ASP='D',
    CYS='C',
    GLU='E',
    GLN='Q',
    GLY='G',
    HIS='H',
    ILE='I',
    LEU='L',
    LYS='K',
    MET='M',
    PHE='F',
    PRO='P',
    SER='S',
    THR='T',
    TRP='W',
    TYR='Y',
    VAL='V',
)


def parse_aa(gene: str,
             ref: str,
             alt: str,
             nt_pos: int,
             aa_pos: int,
             snpeff_aa: str,
             effect: str) -> str:
    m = re.match(r'p\.([a-zA-Z]+)(\d+)([a-zA-Z]+)', snpeff_aa)
    if snpeff_aa == '.' or m is None:
        return f'{ref}{nt_pos}{alt}'
    ref_aa, aa_pos_str, alt_aa = m.groups()
    ref_aa = get_aa(ref_aa)

    if effect == 'stop_lost':
        alt_aa = get_aa(alt_aa.replace('ext', ''))
        return f'{ref}{nt_pos}{alt}({gene}:{ref_aa}{aa_pos_str}{alt_aa}[stop_lost])'
    if effect == 'frameshift_variant':
        return f'{ref}{nt_pos}{alt}({gene}:{ref_aa}{aa_pos_str}[FRAMESHIFT])'
    if effect == 'conservative_inframe_deletion':
        return f'{ref}{nt_pos}{alt}({gene}:{ref_aa}{aa_pos_str}{alt_aa})'
    if effect == 'disruptive_inframe_deletion':
        return f'{ref}{nt_pos}{alt}({gene}:{ref_aa}{aa_pos_str}{alt_aa}[disruptive_inframe_deletion])'

    alt_aa = get_aa(alt_aa)
    return f'{ref}{nt_pos}{alt}({gene}:{ref_aa}{aa_pos_str}{alt_aa})'


def get_aa(s: str) -> str:
    out = ''
    for i in range(0, len(s), 3):
        aa = s[i: i + 3]
        try:
            aa_code = aa_codes[aa.upper()]
        except KeyError:
            aa_code = aa
        out += aa_code
    return out


def main(snpsift_input: Path = typer.Argument(None, help='SnpSift tab-delimited table of variant effects'), 
         output: Path = typer.Argument(None, help='Ouput simple SnpSift table')):
    from rich.traceback import install
    install(show_locals=True, width=120, word_wrap=True)

    logging.basicConfig(format='%(message)s',
                        datefmt='[%Y-%m-%d %X]',
                        level=logging.DEBUG,
                        handlers=[RichHandler(rich_tracebacks=True,
                                              tracebacks_show_locals=True)])

    df = pd.read_table(snpsift_input)
    series = []
    for c in df.columns:
        if c == 'AC':
            df_ac = df[c].str.split(',', n=1, expand=True)
            REF_AC = df_ac[0].astype(int)
            REF_AC.name = 'REF_AC'
            ALT_AC = df_ac[1].astype(int)
            ALT_AC.name = 'ALT_AC'
            AF = ALT_AC / (REF_AC + ALT_AC)
            AF.name = 'AF'
            series += [REF_AC, ALT_AC, AF]
            continue
        idx = c.find('[*].')
        if idx > 0:
            new_series = df[c].str.split(',', n=1, expand=True)[0]
            new_series.name = c[idx+4:].lower()
            series.append(new_series)
        else:
            series.append(df[c])
    df_out = pd.concat(series, axis=1)
    mutation_desc = []
    for row in df_out.itertuples():
        mutation_desc.append(parse_aa(gene=row.gene,
                                      ref=row.REF,
                                      alt=row.ALT,
                                      nt_pos=row.POS,
                                      aa_pos=row.aa_pos,
                                      snpeff_aa=row.aa,
                                      effect=row.effect))
    df_out['mutation'] = mutation_desc

    df_out.to_csv(output, sep='\t', index=False)


if __name__ == '__main__':
    typer.run(main)