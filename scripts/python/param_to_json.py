#!/usr/bin/env python3
"""
Parse AMBER-style .in files in a folder into a JSON summary.

Example:
  python param_to_json.py /mnt/nas_1/YangLab/loci/casE/data/param \
    -o /mnt/nas_1/YangLab/loci/casE/data/param/params.json
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


KEY_VAL_RE = re.compile(r"([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^,]+)")


def _coerce_value(raw: str) -> Any:
    raw = raw.strip()
    if raw.startswith(("'", '"')) and raw.endswith(("'", '"')) and len(raw) >= 2:
        return raw[1:-1]
    # Try int, then float
    try:
        if re.match(r"^[+-]?\d+$", raw):
            return int(raw)
        if re.match(r"^[+-]?\d*\.\d+(?:[Ee][+-]?\d+)?$", raw) or re.match(
            r"^[+-]?\d+(?:[Ee][+-]?\d+)$", raw
        ):
            return float(raw)
    except ValueError:
        pass
    return raw


def parse_amber_in(path: Path) -> dict[str, Any]:
    data: dict[str, Any] = {}
    in_cntrl = False

    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.lower().startswith("&cntrl"):
            in_cntrl = True
            continue
        if in_cntrl and stripped.startswith("/"):
            in_cntrl = False
            continue

        # Remove inline comments starting with "!"
        if "!" in stripped:
            stripped = stripped.split("!", 1)[0].strip()
        if not stripped:
            continue

        # Only parse key=value pairs (typically within &cntrl)
        for match in KEY_VAL_RE.finditer(stripped):
            key = match.group(1)
            value = _coerce_value(match.group(2))
            data[key] = value

    return data


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert AMBER .in files to JSON.")
    parser.add_argument("folder", type=Path, help="Folder containing .in files")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="Output JSON path (defaults to <folder>/params.json)",
    )
    args = parser.parse_args()

    folder = args.folder
    output = args.output or folder / "params.json"

    result: dict[str, Any] = {}
    for infile in sorted(folder.glob("*.in")):
        result[infile.stem] = parse_amber_in(infile)

    output.write_text(json.dumps(result, indent=2, sort_keys=True))
    print(f"Wrote {output}")


if __name__ == "__main__":
    main()
