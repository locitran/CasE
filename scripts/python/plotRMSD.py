from pathlib import Path

import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

def readRMSD(path):
    frames = []
    values = []

    with path.open() as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            if line.startswith("#"):
                continue

            frame_str, value_str = line.split()[:2]
            frames.append(int(frame_str))
            values.append(float(value_str))

    if not frames:
        raise ValueError(f"No data rows found in {path}")

    return frames, values

# one snapshot is 100 ps
def main():
    parser = argparse.ArgumentParser(description="Plot RMSD from a cpptraj output table.")
    parser.add_argument("-i", "--input", type=Path, required=True, help="Input RMSD table, e.g. md_rmsd_ca.csv")
    parser.add_argument("-o", "--output", type=Path, default="rmsd.png", help="Output image path. Defaults to 'rmsd.png'",)
    parser.add_argument("-t", "--title", type=str, default=None, help="Image title",)
    parser.add_argument("-y", "--ylabel", type=str, default="CA RMSD (Å)", help="Y-axis title. Defaults to 'CA RMSD (Å)'",)
    parser.add_argument("-x", "--timeframe", type=int, default=100, help="Time period between two frames. Defaults to 100 ps",)
    args = parser.parse_args()

    output = args.output
    title = args.title
    ylabel = args.ylabel
    timeframe = args.timeframe
    frames, y = readRMSD(args.input)

    # Convert frame to time (ns)
    x = np.array(frames) * timeframe / 1000

    plt.figure(figsize=(8, 4.5))
    plt.plot(x, y, linewidth=1.5)
    plt.xlabel("Time (ns)")
    plt.ylabel(ylabel)
    plt.title(title)
    plt.savefig(output, dpi=300)
    plt.close()

    print(f"Saved plot to {output}")


if __name__ == "__main__":
    main()
