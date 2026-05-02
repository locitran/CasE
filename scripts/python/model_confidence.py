#!/usr/bin/env python

# model_confidence.py

def extract_residues_by_bfactor(pdb_filename, cutoff=70.0):
    residue_bfactors = {}

    with open(pdb_filename, 'r') as pdb_file:
        for line in pdb_file:
            if line.startswith(("ATOM", "HETATM")):
                bfactor = float(line[60:66].strip())
                residue = line[17:20].strip()
                residue_number = int(line[22:26].strip())
                chain = line[21].strip()

                key = (chain, residue_number)

                residue_bfactors.setdefault(key, []).append(bfactor)

    high_res = []
    low_res = []

    for (chain, resnum), bfactors in residue_bfactors.items():
        avg_b = sum(bfactors) / len(bfactors)
        if avg_b > cutoff:
            high_res.append(resnum)
        else:
            low_res.append(resnum)

    return sorted(high_res), sorted(low_res)


def create_residue_ranges(resnums, gap=1):
    if not resnums:
        return []

    ranges = []
    start = prev = resnums[0]

    for r in resnums[1:]:
        if r - prev > gap:
            ranges.append((start, prev))
            start = r
        prev = r

    ranges.append((start, prev))

    amber_lines = []
    for s, e in ranges:
        if s == e:
            amber_lines.append(f"RES {s}")
        else:
            amber_lines.append(f"RES {s} {e}")

    return amber_lines


def get_amber_res_blocks(pdb_filename, cutoff=70.0):
    high, low = extract_residues_by_bfactor(pdb_filename, cutoff)

    high_block = create_residue_ranges(high)
    low_block  = create_residue_ranges(low)

    return high_block, low_block

