#!/usr/bin/env python3
"""Parse MMPBSA.py summary, per-frame, and decomposition outputs."""

import argparse
import csv
import json
import os
import re


def parseSummary(file):
    """Parse result_mmgbsa.dat into metadata and summary energy sections."""
    if not os.path.exists(file):
        return None

    with open(file, "r") as f:
        text = f.read()

    data = {
        "metadata": {},
        "sections": {
            "Complex": {},
            "Receptor": {},
            "Ligand": {},
            "Differences": {},
        },
    }
    metadata_patterns = {
        "run_date": r"\|\s*Run on\s+(.+)$",
        "mmpbsa_version": r"\|MMPBSA\.py Version=(.+)$",
        "solvated_complex_topology": r"\|Solvated complex topology file:\s+(.+)$",
        "complex_topology": r"\|Complex topology file:\s+(.+)$",
        "receptor_topology": r"\|Receptor topology file:\s+(.+)$",
        "ligand_topology": r"\|Ligand topology file:\s+(.+)$",
        "trajectory": r"\|Initial mdcrd\(s\):\s+(.+)$",
        "receptor_mask": r'\|Receptor mask:\s+"(.+)"$',
        "ligand_mask": r'\|Ligand mask:\s+"(.+)"$',
        "n_complex_frames": r"\|Calculations performed using\s+(.+?)\s+complex frames\.",
        "units": r"\|All units are reported in\s+(.+)\.",
    }
    section_names = {"Complex:": "Complex", "Receptor:": "Receptor", "Ligand:": "Ligand"}
    number_line = re.compile(
        r"^\s*([A-Za-z0-9][A-Za-z0-9\- ]*?)\s+"
        r"(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s*$"
    )

    for key, pattern in metadata_patterns.items():
        match = re.search(pattern, text, re.MULTILINE)
        if match:
            value = match.group(1).strip()
            data["metadata"][key] = float(value) if key == "n_complex_frames" else value

    section = None
    for line in text.splitlines():
        stripped = line.strip()
        if stripped in section_names:
            section = section_names[stripped]
            continue
        if stripped.startswith("Differences "):
            section = "Differences"
            continue
        if section is None:
            continue

        match = number_line.match(line)
        if match:
            component = "_".join(match.group(1).strip().split())
            data["sections"][section][component] = {
                "average": float(match.group(2)),
                "std_dev": float(match.group(3)),
                "std_err": float(match.group(4)),
            }

    return data


def parsePerframe(file):
    """Parse mmgbsa.eo into one CSV-ready row per frame and energy section."""
    if not os.path.exists(file):
        return None

    with open(file, "r") as f:
        text = f.read()

    rows = []
    section = None
    headers = []
    section_names = {
        "Complex Energy Terms": "Complex",
        "Receptor Energy Terms": "Receptor",
        "Ligand Energy Terms": "Ligand",
        "DELTA Energy Terms": "Differences",
    }

    for line in text.splitlines():
        stripped = line.strip()
        if stripped in section_names:
            section = section_names[stripped]
            headers = []
            continue
        if section is None or not stripped or stripped == "GENERALIZED BORN:":
            continue

        row = next(csv.reader([line]))
        if row and row[0] == "Frame #":
            headers = ["frame"] + ["_".join(item.strip().split()) for item in row[1:]]
            continue
        if not headers or not row or not row[0].strip().isdigit():
            continue

        entry = {"section": section, "frame": int(row[0])}
        for key, value in zip(headers[1:], row[1:]):
            entry[key] = float(value)
        rows.append(entry)

    return rows


def parsePerResidue(file):
    """Parse mmgbsa.do into one CSV-ready row per residue summary term."""
    if not os.path.exists(file):
        return None

    with open(file, "r") as f:
        text = f.read()

    rows = []
    section = None
    decomp = None
    section_names = {
        "Complex:": "Complex",
        "Receptor:": "Receptor",
        "Ligand:": "Ligand",
        "DELTAS:": "Differences",
    }
    decomp_names = {
        "Total Energy Decomposition:": "Total",
        "Sidechain Energy Decomposition:": "Sidechain",
        "Backbone Energy Decomposition:": "Backbone",
    }
    energy_terms = [
        "internal",
        "vdw",
        "electrostatic",
        "polar_solvation",
        "nonpolar_solvation",
        "total",
    ]

    for line in text.splitlines():
        stripped = line.strip()
        if stripped in section_names:
            section = section_names[stripped]
            decomp = None
            continue
        if stripped in decomp_names and section:
            decomp = decomp_names[stripped]
            continue
        if not section or not decomp or not stripped:
            continue

        row = next(csv.reader([line]))
        if not row or row[0] in {"Residue", ""}:
            continue

        value_start = 1
        entry = {"section": section, "decomp_type": decomp, "residue": row[0].strip(), "location": ""}
        if section == "Differences":
            value_start = 2
            entry["location"] = row[1].strip()
        if len(row) < value_start + 18:
            continue

        for i, term in enumerate(energy_terms):
            offset = value_start + i * 3
            entry[f"{term}_avg"] = float(row[offset])
            entry[f"{term}_std_dev"] = float(row[offset + 1])
            entry[f"{term}_std_err"] = float(row[offset + 2])
        rows.append(entry)

    return rows


def parsePerResiduePair(file):
    """Parse mmgbsa.deo into one CSV-ready row per frame/residue-pair term."""
    if not os.path.exists(file):
        return None

    with open(file, "r") as f:
        text = f.read()

    rows = []
    section = None
    decomp = None
    headers = []
    section_names = {
        "Complex:": "Complex",
        "Receptor:": "Receptor",
        "Ligand:": "Ligand",
        "DELTAS:": "Differences",
    }
    decomp_names = {
        "Total Energy Decomposition:": "Total",
        "Sidechain Energy Decomposition:": "Sidechain",
        "Backbone Energy Decomposition:": "Backbone",
        "DELTA,Total Energy Decomposition:": "Total",
        "DELTA,Sidechain Energy Decomposition:": "Sidechain",
        "DELTA,Backbone Energy Decomposition:": "Backbone",
    }

    for line in text.splitlines():
        stripped = line.strip()
        if stripped in section_names:
            section = section_names[stripped]
            decomp = None
            headers = []
            continue
        if stripped in decomp_names and section:
            decomp = decomp_names[stripped]
            headers = []
            continue
        if not section or not decomp or not stripped:
            continue

        row = next(csv.reader([line]))
        if not row:
            continue
        if row[0] == "Frame #":
            headers = ["_".join(item.strip().split()) for item in row]
            headers = ["nonpolar_solvation" if item == "Non-Polar_Solv." else item for item in headers]
            continue
        if not headers or not row[0].strip().isdigit():
            continue

        entry = {"section": section, "decomp_type": decomp}
        for key, value in zip(headers, row):
            clean_key = key.lower().replace("#", "num")
            if clean_key == "frame_num":
                clean_key = "frame"
            if clean_key in {"frame", "residue", "location"}:
                entry[clean_key] = int(value) if clean_key == "frame" and value.isdigit() else value.strip()
            else:
                entry[clean_key] = float(value)
        rows.append(entry)

    return rows


def main():
    """Choose the parser from --kind, write JSON for summary or CSV otherwise."""
    parser = argparse.ArgumentParser(description="Parse MMPBSA.py output files.")
    parser.add_argument("-i", "--input", required=True, help="Input MMGBSA output file.")
    parser.add_argument("-o", "--output", help="Output file.")
    parser.add_argument(
        "-k",
        "--kind",
        required=True,
        choices=["summary", "per-frame", "per-residue", "per-residue-pair"],
        help="Parser type.",
    )
    args = parser.parse_args()

    kind = args.kind
    default_names = {
        "summary": "result_mmgbsa.json",
        "per-frame": "mmgbsa_energy_frames.csv",
        "per-residue": "mmgbsa_decomp.csv",
        "per-residue-pair": "mmgbsa_frame_decomp.csv",
    }
    output = args.output or os.path.join(os.path.dirname(args.input), default_names[kind])

    if kind == "summary":
        data = parseSummary(args.input)
        if data is None:
            print(f"Input file does not exist, skipped: {args.input}")
            return
        with open(output, "w") as f:
            f.write(json.dumps(data, indent=2) + "\n")
    else:
        if kind == "per-frame":
            rows = parsePerframe(args.input)
        elif kind == "per-residue":
            rows = parsePerResidue(args.input)
        else:
            rows = parsePerResiduePair(args.input)

        if rows is None:
            print(f"Input file does not exist, skipped: {args.input}")
            return

        with open(output, "w", newline="") as f:
            if rows:
                fieldnames = []
                for row in rows:
                    for key in row:
                        if key not in fieldnames:
                            fieldnames.append(key)
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(rows)

    print(f"Wrote {output}")


if __name__ == "__main__":
    main()
