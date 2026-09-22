#!/usr/bin/env python3
"""Plot the perf_test CSVs produced by parse_perftest.sh.

Finds every CSV under $HOME/perftest (index column "Size", one value
column per iteration) and renders it as a line plot (one line per
iteration, Size on the x-axis), saved next to the CSV with the same
name but a .png extension.
"""

import os
import sys
from pathlib import Path

import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# Marker changes only once the color cycle wraps around, so e.g. with the
# default 10-color cycle: blue-o, orange-o, green-o, ... cyan-o (10),
# blue-s, orange-s, ... cyan-s (20), blue-^, ...
MARKERS = ["o", "s", "^", "D", "v", "P", "X", "*", "<", ">"]

def plot_csv(csv_path: Path) -> None:
    df = pd.read_csv(csv_path, index_col="Size")

    colors = plt.rcParams["axes.prop_cycle"].by_key()["color"]
    ncolors = len(colors)

    fig, ax = plt.subplots()
    for i, col in enumerate(df.columns):
        color = colors[i % ncolors]
        marker = MARKERS[(i // ncolors) % len(MARKERS)]
        ax.plot(df.index, df[col], marker=marker, color=color, label=col)

    ax.set_xlabel("Size (bytes)")
    ax.set_ylabel("Mbytes/sec")
    ax.set_xscale("log", base=2)
    ax.set_title(csv_path.stem)
    plt.grid(True, alpha=0.5)
    ax.legend(title="Iteration", fontsize="small", ncol=2)
    fig.tight_layout()

    out_path = csv_path.with_suffix(".png")
    fig.savefig(out_path)
    plt.close(fig)
    print(f"Wrote {out_path}")


def main(pdir) -> None:
    csvs = sorted(pdir.rglob("*.csv"))
    if not csvs:
        print(f"No CSV files found under {pdir}")
        return
    for csv_path in csvs:
        plot_csv(csv_path)


if __name__ == "__main__":
    pdir = Path(os.environ.get("HOME", "")) / "perftest"
    if len(sys.argv) > 1:
        pdir = Path(sys.argv[1])
    main(pdir)
