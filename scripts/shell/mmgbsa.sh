#!/bin/bash
echo "Starting MMGBSA run at $(date)"
start=$(date +%s)  # Record start time in minutes

# Wrapping the trajectory
# ========wrap.in=============
cat > "$cpptraj/wrap.in" <<EOF
parm $topfile
trajin $md_NPT/md_NPT.nc
autoimage :$complex_range
trajout $mmgbsa/trajectory_wrapped.dcd DCD nobox
run
quit
EOF
# ==========================
run_container "cpptraj -i $cpptraj/wrap.in" > "$cpptraj/wrap.log" 2>&1

rm -f "$mmgbsa/complex.parm7" "$mmgbsa/receptor.parm7" "$mmgbsa/ligand.parm7"

run_container "ante-MMPBSA.py -p $topfile \
  -c $mmgbsa/complex.parm7 -r $mmgbsa/receptor.parm7 -l $mmgbsa/ligand.parm7 \
  -s '!(:$complex_range)' -m '!(:$peptide_range)'" \
  > "$mmgbsa/ante-MMPBSA.log" 2>&1
# -s '!(:1-383)'  This is the mask for creating the complex file without the solvent
# -m '!(:276-284)' This is the mask for creating the ligand part and the remaining for the receptor part

# Fail fast if the parm7 files were not produced
for parm7 in "$mmgbsa/complex.parm7" "$mmgbsa/receptor.parm7" "$mmgbsa/ligand.parm7"; do
  if [[ ! -s "$parm7" ]]; then
    echo "ERROR: Expected file not created: $parm7" >&2
    exit 1
  fi
done

run_container "mpirun -np ${SLURM_NTASKS:-4} MMPBSA.py.MPI -O \
  -i $param/mmgbsa.in -o $mmgbsa/result_mmgbsa.dat -sp $topfile \
  -cp $mmgbsa/complex.parm7 -rp $mmgbsa/receptor.parm7 -lp $mmgbsa/ligand.parm7 \
  -y $mmgbsa/trajectory_wrapped.dcd \
  -do $mmgbsa/mmgbsa.do -eo $mmgbsa/mmgbsa.eo -deo $mmgbsa/mmgbsa.deo" \
  > "$mmgbsa/mmgbsa.log" 2>&1

echo "Parsing MMGBSA output files at $(date)"
python "$workdir/scripts/python/parseMMGBSA.py" -i "$mmgbsa/result_mmgbsa.dat"  --kind summary          -o "$mmgbsa/result_mmgbsa.json"
python "$workdir/scripts/python/parseMMGBSA.py" -i "$mmgbsa/mmgbsa.eo"          --kind per-frame        -o "$mmgbsa/per-frame.csv"
python "$workdir/scripts/python/parseMMGBSA.py" -i "$mmgbsa/mmgbsa.do"          --kind per-residue      -o "$mmgbsa/per-residue.csv"
python "$workdir/scripts/python/parseMMGBSA.py" -i "$mmgbsa/mmgbsa.deo"         --kind per-residue-pair -o "$mmgbsa/per-residue-pair.csv"

end=$(date +%s)  # Record end time in minutes
elapsed=$((end - start))  # Compute total time

echo "MMGBSA run completed at $(date)"
report_elapsed "MMGBSA" "$elapsed"
