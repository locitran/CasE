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

echo "Starting Check run at $(date)"
echo "This step is to check output of each stage of MD simulation"
start=$(date +%s)  # Record start time in minutes

# check data of our system
mdout_files=("$em/min0.out" "$em/min1.out" "$em/min2.out" "$heat/heat.out" "$equi_NVT/equi_NVT.out" "$equi_NPT/equi_NPT.out" "$md_NPT/md_NPT.out")
count=0

for input_file in "${mdout_files[@]}"; do
  if [[ -f "$input_file" ]]; then
    ((count += 1))
    base=$(basename "$input_file" .out)
    stage_input="$cpptraj/readOut_${base}.in"
    stage_log="$cpptraj/readOut_${base}.log"

    cat > "$stage_input" <<EOF
readdata $input_file name ${base}_out
writedata ${input_file%.out}_all.dat ${base}_out[*]
run
quit
EOF

    echo "run cpptraj of $stage_input"
    if ! run_container cpptraj -i "$stage_input" > "$stage_log" 2>&1; then
      echo "Warning: cpptraj failed for $input_file; see $stage_log"
    fi
  fi
done

if (( count == 0 )); then
  echo "Warning: no mdout files found"
fi

plotDAT() {
  local input_file=$1
  local output_file=$2
  local x_column=$3
  local y_column=$4

  if [[ -f "$input_file" ]]; then
    python "$workdir/scripts/python/plotDAT.py" -i "$input_file" -o "$output_file" --x-column "$x_column" --y-column "$y_column"
  else
    echo "Warning: missing file, skipping plot: $input_file"
  fi
}
# em
plotDAT "$em/min0_all.dat" "$em/min0_all.png" "#Nstep" "min0_out_EPtot"
plotDAT "$em/min1_all.dat" "$em/min1_all.png" "#Nstep" "min1_out_EPtot"
plotDAT "$em/min2_all.dat" "$em/min2_all.png" "#Nstep" "min2_out_EPtot"
# heat
plotDAT "$heat/heat_all.dat" "$heat/heat_all_TEMP.png" "#Time" "heat_out_TEMP"
plotDAT "$heat/heat_all.dat" "$heat/heat_all_Etot.png" "#Time" "heat_out_Etot"
plotDAT "$heat/heat_all.dat" "$heat/heat_all_EPtot.png" "#Time" "heat_out_EPtot"
plotDAT "$heat/heat_all.dat" "$heat/heat_all_EKtot.png" "#Time" "heat_out_EKtot"
# equi_NVT
plotDAT "$equi_NVT/equi_NVT_all.dat" "$equi_NVT/equi_NPV_all_Etot.png" "#Time" "equi_NVT_out_Etot"
plotDAT "$equi_NVT/equi_NVT_all.dat" "$equi_NVT/equi_NPV_all_EPtot.png" "#Time" "equi_NVT_out_EPtot"
plotDAT "$equi_NVT/equi_NVT_all.dat" "$equi_NVT/equi_NPV_all_EKtot.png" "#Time" "equi_NVT_out_EKtot"
plotDAT "$equi_NVT/equi_NVT_all.dat" "$equi_NVT/equi_NPV_all_TEMP.png" "#Time" "equi_NVT_out_TEMP"
plotDAT "$equi_NVT/equi_NVT_all.dat" "$equi_NVT/equi_NPV_all_PRESS.png" "#Time" "equi_NVT_out_PRESS"
# equi_NPT
plotDAT "$equi_NPT/equi_NPT_all.dat" "$equi_NPT/equi_NPT_all_Etot.png" "#Time" "equi_NPT_out_Etot"
plotDAT "$equi_NPT/equi_NPT_all.dat" "$equi_NPT/equi_NPT_all_EPtot.png" "#Time" "equi_NPT_out_EPtot"
plotDAT "$equi_NPT/equi_NPT_all.dat" "$equi_NPT/equi_NPT_all_EKtot.png" "#Time" "equi_NPT_out_EKtot"
plotDAT "$equi_NPT/equi_NPT_all.dat" "$equi_NPT/equi_NPT_all_VOLUME.png" "#Time" "equi_NPT_out_VOLUME"
plotDAT "$equi_NPT/equi_NPT_all.dat" "$equi_NPT/equi_NPT_all_TEMP.png" "#Time" "equi_NPT_out_TEMP"
plotDAT "$equi_NPT/equi_NPT_all.dat" "$equi_NPT/equi_NPT_all_PRESS.png" "#Time" "equi_NPT_out_PRESS"
# md
plotDAT "$md_NPT/md_NPT_all.dat" "$md_NPT/md_NPT_all_Etot.png" "#Time" "md_NPT_out_Etot"
plotDAT "$md_NPT/md_NPT_all.dat" "$md_NPT/md_NPT_all_EPtot.png" "#Time" "md_NPT_out_EPtot"
plotDAT "$md_NPT/md_NPT_all.dat" "$md_NPT/md_NPT_all_EKtot.png" "#Time" "md_NPT_out_EKtot"
plotDAT "$md_NPT/md_NPT_all.dat" "$md_NPT/md_NPT_all_VOLUME.png" "#Time" "md_NPT_out_VOLUME"
plotDAT "$md_NPT/md_NPT_all.dat" "$md_NPT/md_NPT_all_TEMP.png" "#Time" "md_NPT_out_TEMP"
plotDAT "$md_NPT/md_NPT_all.dat" "$md_NPT/md_NPT_all_PRESS.png" "#Time" "md_NPT_out_PRESS"

end=$(date +%s)  # Record end time in minutes
elapsed=$((end - start))  # Compute total time

echo "Analysis run completed at $(date)"
report_elapsed "Analysis" "$elapsed"
