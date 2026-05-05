#!/bin/bash

# Variables used:
# - workdir: casE project root, inherited.
# - input_cif: AF3 model in CIF format for the current variant/type, inherited.
# - input_pdb: converted PDB path for the current variant/type, inherited.
# - outdir: output directory for the current variant/type, inherited.
# - run_container: helper function for running AMBER tools in Singularity, inherited.
# - start/end/elapsed: timestamps used for runtime reporting.

echo "Starting pdb4amber run at $(date)"
start=$(date +%s)  # Record start time in minutes

# 0/ convert cif to pdb
python -c "from prody import parsePDB, writePDB; p = parsePDB('$input_cif'); writePDB('$input_pdb', p)"

# 1/ Preparation with pdb4amber + propka3
cd $outdir
run_container pdb4amber -i $input_pdb -o $outdir/noh.pdb # Parsing our PDB file using pdb4amber
propka3 $outdir/noh.pdb --pH 7.0 # Calculating the Protonation state of residues
python3 $workdir/scripts/python/protonate_pka.py $outdir/noh.pka $outdir/noh.pdb $outdir/noh_propka.pdb # Edit the residue name based on its pKa
cd $workdir

end=$(date +%s)  # Record end time in minutes
elapsed=$((end - start))  # Compute total time

echo "pdb4amber run completed at $(date)"
report_elapsed "pdb4amber" "$elapsed"
