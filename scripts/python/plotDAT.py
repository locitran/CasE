"""
python ≥3.10
Example code:
python scripts/python/plotDAT.py \
  -i md_NPT_all.dat \
  -o temp.png \
  --x-column "#Time" \
  --y-column "md_NPT_out_TEMP" \
  -t "Temperature vs Time"
"""

import os
import argparse
from typing import Union
import matplotlib.pyplot as plt

PathLike = Union[str, os.PathLike]
def readDAT(path: PathLike):
    path = os.fspath(path)

    with open(path) as handle:
        header = handle.readline().strip().split()
        if not header:
            raise ValueError(f"No header found in {path}")

        rows = []
        for line in handle:
            parts = line.strip().split()
            if not parts:
                continue
            rows.append(parts)

    if not rows:
        raise ValueError(f"No data rows found in {path}")

    expected_width = len(header)
    columns = {name: [] for name in header}

    for row_number, parts in enumerate(rows, start=2):
        if len(parts) != expected_width:
            raise ValueError(
                f"Row {row_number} in {path} has {len(parts)} columns, expected {expected_width}"
            )

        for name, value in zip(header, parts):
            columns[name].append(float(value))

    return columns


def plotDAT(
    input_path: PathLike,
    output_path: PathLike,
    x_column: str,
    y_column: str,
    title: str | None = None,
    xlabel: str | None = None,
    ylabel: str | None = None,
    save: bool = True
):
    input_path = os.fspath(input_path)
    output_path = os.fspath(output_path)

    columns = readDAT(input_path)

    x_values = columns[x_column]
    y_values = columns[y_column]

    plt.plot(x_values, y_values)
    plt.xlabel(xlabel or x_column)
    plt.ylabel(ylabel or y_column)
    if title:
        plt.title(title)
    plt.tight_layout()
    if save:
        plt.savefig(output_path, dpi=300)
        plt.close()
        print(f"Saved plot to {output_path}")
    else:
        plt.show()


def main():
    parser = argparse.ArgumentParser(description="Plot columns from an AMBER-style .dat table.")
    parser.add_argument("-i", "--input", type=str, required=True, help="Input .dat file")
    parser.add_argument("-o", "--output", type=str, default="dat_plot.png", help="Output image path")
    parser.add_argument("-t", "--title", type=str, default=None, help="Optional plot title")
    parser.add_argument("--x-column", type=str, required=True, help="Column name for the x-axis")
    parser.add_argument("--y-column", type=str, required=True, help="Column name for the y-axis")
    parser.add_argument("--xlabel", type=str, default=None, help="Optional x-axis label override")
    parser.add_argument("--ylabel", type=str, default=None, help="Optional y-axis label override")
    args = parser.parse_args()

    plotDAT(
        input_path=args.input,
        output_path=args.output,
        x_column=args.x_column,
        y_column=args.y_column,
        title=args.title,
        xlabel=args.xlabel,
        ylabel=args.ylabel,
    )


if __name__ == "__main__":
    main()
