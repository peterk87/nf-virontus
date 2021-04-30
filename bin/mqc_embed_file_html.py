#!/usr/bin/env python

from typing import List
import base64
from pathlib import Path

import typer

# Header with HTML comment that MultiQC can parse to create new section in 
# MultiQC report.
header = '''
<!--
id: '{id}'
section_name: '{name}'
description: '{desc}'
-->

<ul>
'''

# closing ul tag
footer = '''
</ul>
'''


def to_html_li(p: Path) -> str:
    b64 = base64.encodebytes(p.read_bytes())
    return f'''
    <li>
    <a
      download="{p.name}"
      href="data:text/plain;base64,{b64.decode()}">
        Download {p.name}
    </a>
    </li>
    '''


def main(output_html: Path,
         files: List[Path],
         id: str = typer.Option('id'),
         name: str = typer.Option('name'),
         desc: str = typer.Option('desc')):
    """Embed content of files into HTML for inclusion in MultiQC report"""
    with open(output_html, 'w') as fout:
        fout.write(header.format(id=id, name=name, desc=desc))
        for f in files:
            fout.write(to_html_li(f))
        fout.write(footer)


if __name__ == '__main__':
    typer.run(main)
