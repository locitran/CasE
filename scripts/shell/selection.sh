#!/bin/bash

# Variables used:
# - outdir: output directory for the current variant/type, inherited.
# - complex_range: computed residue range for the whole complex; exported by this script.
# - peptide_range: computed residue range for the peptide chain; exported by this script.
# - start/end/elapsed: timestamps used for runtime reporting.

echo "Starting selection run at $(date)"
start=$(date +%s)  # Record start time in minutes


read -r complex_range peptide_range < <(
python - <<PY
from prody import parsePDB

pdbfile = "$outdir/noh_propka.pdb"
p = parsePDB(pdbfile)

chains = list(dict.fromkeys(p.ca.getChids()))
starts = {}
ends = {}

for ch in chains:
    ca = p.ca.select(f'chain {ch}')
    resnums = ca.getResnums()
    starts[ch] = int(min(resnums))
    ends[ch] = int(max(resnums))

# CasE peptide: chain C
complex_range = f"{starts[chains[0]]}-{ends[chains[2]]}"
peptide_range = f"{starts[chains[2]]}-{ends[chains[2]]}"

print(complex_range, peptide_range)
PY
)

echo "complex_range=$complex_range"
echo "peptide_range=$peptide_range"

end=$(date +%s)  # Record end time in minutes
elapsed=$((end - start))  # Compute total time

echo "selection run completed at $(date)"
report_elapsed "Selection" "$elapsed"
