#!/usr/bin/env python

from pathlib import Path

import pandas as pd
import typer
from rich.console import Console
from rich.logging import RichHandler


def main(input_path: Path,
         output_sample_sheet: Path):
    """Check and reformat sample sheet into CSV"""
    
    print(f'input_sample_sheet="{input_path}"')
    ext = input_path.suffix.lower()
    print(f'ext={ext}')
    try:
        if ext in ['.tsv', '.txt', '.tab']:
            df = pd.read_table(input_path)
        elif ext == '.csv':
            df = pd.read_csv(input_path)
        elif ext in ['.xls', '.xlsx', '.ods']:
            df = pd.read_excel(input_path)
        else:
            raise ValueError(f'Unknown file format for sample sheet "{input_path}"')
    except Exception as ex:
        print(ex)
        raise ex
    print(df)
    assert df.shape[1] == 2, f'Two columns expected in sample sheet, but {df.shape[1]} found!'
    df.columns = ['sample', 'reads_path']
    reads_paths = []
    for fp in df.reads_path:
        if fp.startswith('http') or fp.startswith('ftp'):
            reads_paths.append(fp)
        else:
            path = Path(fp)
            reads_paths.append(str(path.resolve().absolute()))
    df.reads_path = reads_paths
    df.to_csv(output_sample_sheet, index=False)
    print(f'Wrote reformatted sample sheet CSV to "{output_sample_sheet}"')


if __name__ == '__main__':
    typer.run(main)
