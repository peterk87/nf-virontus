#!/usr/bin/env python

from typing import List, Optional
from pathlib import Path
import re

from Bio import Phylo
from seaborn.palettes import color_palette
import matplotlib.pyplot as plt
import pandas as pd
import typer


def main(treefile: Path,
         tree_viz_out: Path,
         pangolin_report: Optional[Path] = typer.Option(None)):
    """Create basic tree with ete3 optionally adding Pangolin lineage"""
    tree = Phylo.read(treefile, format='newick')
    if pangolin_report:
        df_pangolin = pd.read_csv(pangolin_report)
        df_pangolin.set_index('taxon', inplace=True)
        lineage_counts = df_pangolin.lineage.value_counts()
        palette = color_palette('Pastel1', n_colors=lineage_counts.size)

        lineage_to_color = {lineage: color for (lineage, count), color in zip(lineage_counts.items(), palette.as_hex())}

        fig = plt.figure(figsize=(10,6))
        ax_tree, ax_md = fig.subplots(ncols=2, sharey=True, gridspec_kw=dict(wspace=0,width_ratios=(0.8,0.2)))
        plt.setp(ax_tree.spines.values(), linewidth=0)
        plt.setp(ax_md.spines.values(), linewidth=0)

        Phylo.draw(tree, axes=ax_tree, do_show=False, show_confidence=False)
        ax_tree.set_ylabel(None)
        ax_md.tick_params(axis='both', which='both', left=False, labelleft=False, bottom=False, labelbottom=False)
        ax_tree.tick_params(axis='both', which='both', left=False, labelleft=False)

        tree_names = [x.name for x in tree.get_terminals()]
        lineage_faces = {}
        for sample, lineage in df_pangolin.lineage.to_dict().items():
            bg_color = lineage_to_color[lineage]
            lineage_faces[sample] = dict(col=bg_color, label=lineage)

        for y, sample in enumerate(tree_names):
            try:
                sample = re.sub(r'[^\w\-]', '_', sample)
                label = lineage_faces[sample]['label']
                col = lineage_faces[sample]['col']
                ax_md.text(0, y+1, label, bbox=dict(facecolor=col, ec=(1., 1., 1.)))
            except KeyError:
                pass
    else:
        fig = plt.figure(figsize=(10,6))
        ax_tree = fig.subplots()
        Phylo.draw(tree, axes=ax_tree, do_show=False, show_confidence=False)
    fig.savefig(tree_viz_out)



if __name__ == '__main__':
    typer.run(main)
