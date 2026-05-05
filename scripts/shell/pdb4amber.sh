#!/bin/bash

echo "Starting pdb4amber run at $(date)"
start=$(date +%s)  # Record start time in minutes

if [[ -s "$outdir/noh_propka.pdb" ]]; then
    echo "Found existing $outdir/noh_propka.pdb; skipping pdb4amber.sh"
    end=$(date +%s)
    elapsed=$((end - start))
    report_elapsed "pdb4amber" "$elapsed"
    return 0
fi

# 0/ convert cif to pdb
python -c "from prody import parsePDB, writePDB; p = parsePDB('$input_cif'); writePDB('$input_pdb', p)"

# 1/ Preparation with pdb4amber + propka3
cd $outdir
run_container pdb4amber -i $input_pdb -o $outdir/noh.pdb # Parsing our PDB file using pdb4amber
propka3 $outdir/noh.pdb --pH 7.0 # Calculating the Protonation state of residues
python $workdir/scripts/python/protonate_pka.py $outdir/noh.pka $outdir/noh.pdb $outdir/noh_propka.pdb # Edit the residue name based on its pKa
cd $workdir

end=$(date +%s)  # Record end time in minutes
elapsed=$((end - start))  # Compute total time

echo "pdb4amber run completed at $(date)"
report_elapsed "pdb4amber" "$elapsed"
