#!/bin/bash

# Variables used:
# - cpptraj: directory for generated cpptraj input/log files, inherited.
# - topfile: AMBER topology file (.parm7), inherited.
# - md_NPT: production MD output directory containing md_NPT.nc, inherited.
# - analysis: directory for analysis outputs such as CSV/PNG files, inherited.
# - workdir: casE project root, inherited.
# - complex_range: residue range for the whole complex, inherited from selection.sh.
# - peptide_range: residue range for the peptide chain, inherited from selection.sh.
# - run_container: helper function for running AMBER tools in Singularity, inherited.
# - start/end/elapsed: timestamps used for runtime reporting.

echo "Starting Analysis run at $(date)"
start=$(date +%s)  # Record start time in minutes

# RMSD Calculation every frame: CasE-derived pepide
cat > $cpptraj/calRMSD_peptide_ca.in <<EOF
parm $topfile
trajin $md_NPT/md_NPT.nc 1 last
autoimage :$complex_range
rms ToFirst1 :$peptide_range@CA first out $analysis/rmsd_peptide_ca.csv
run
quit
EOF
run_container cpptraj -i $cpptraj/calRMSD_peptide_ca.in > "$analysis/calRMSD_peptide_ca.log" 2>&1

python $workdir/scripts/python/plotRMSD.py \
    -i $analysis/rmsd_peptide_ca.csv \
    -o $analysis/rmsd_peptide_ca.png \
    -t "RMSD" \
    -y $'CA RMSD (Å)\nof CasE-derived peptide (to 1st frame)' \
    -x 100

# RMSD Calculation every frame: complex
cat > $cpptraj/calRMSD_complex_ca.in <<EOF
parm $topfile
trajin $md_NPT/md_NPT.nc 1 last
autoimage :$complex_range
rms ToFirst1 :$complex_range@CA first out $analysis/rmsd_complex_ca.csv
run
quit
EOF
run_container cpptraj -i $cpptraj/calRMSD_complex_ca.in > "$analysis/calRMSD_complex_ca.log" 2>&1

python $workdir/scripts/python/plotRMSD.py \
    -i $analysis/rmsd_complex_ca.csv \
    -o $analysis/rmsd_complex_ca.png \
    -t "RMSD" \
    -y $'CA RMSD (Å)\nof peptide-MHC class I complex (to 1st frame)' \
    -x 100

end=$(date +%s)  # Record end time in minutes
elapsed=$((end - start))  # Compute total time

echo "Analysis run completed at $(date)"
report_elapsed "Analysis" "$elapsed"
