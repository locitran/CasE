#!/bin/bash

# Variables used:
# - config: directory containing generated AMBER .in control files, inherited.
# - topfile: AMBER topology file (.parm7), inherited.
# - coordfile: initial coordinate file for the system, inherited.
# - em/heat/equi_NVT/equi_NPT/md_NPT: stage-specific output directories, inherited.
# - run_container: helper function for running AMBER tools in Singularity, inherited.
# - start/end/elapsed: timestamps used for runtime reporting.

echo "Starting MD run at $(date)"
start=$(date +%s)  # Record start time in minutes

run_container pmemd.cuda_DPFP -O -i "$config/min0.in" -p "$topfile" -c "$coordfile"   -ref "$coordfile"   -o "$em/min0.out"   -r "$em/min0.rst"      -x "$em/min0.nc"   -inf "$em/min0.info"   > "$em/min0.log" 2>&1
run_container pmemd.cuda_DPFP -O -i "$config/min1.in" -p "$topfile" -c "$em/min0.rst" -ref "$em/min0.rst" -o "$em/min1.out"   -r "$em/min1.rst"    -x "$em/min1.nc"   -inf "$em/min1.info"   > "$em/min1.log" 2>&1
run_container pmemd.cuda_DPFP -O -i "$config/min2.in" -p "$topfile" -c "$em/min1.rst" -ref "$em/min1.rst" -o "$em/min2.out"   -r "$em/min2.rst"    -x "$em/min2.nc"   -inf "$em/min2.info"   > "$em/min2.log" 2>&1
run_container pmemd.cuda_SPFP -O -i "$config/heating.in"   -p "$topfile" -c "$em/min2.rst" -ref "$em/min2.rst" -o "$heat/heat.out" -r "$heat/heat.rst"  -x "$heat/heat.nc" -inf "$heat/heat.info" > "$heat/heat.log" 2>&1
run_container pmemd.cuda_SPFP -O -i "$config/equi_NVT.in"  -p "$topfile" -c "$heat/heat.rst"         -ref "$heat/heat.rst"         -o "$equi_NVT/equi_NVT.out" -r "$equi_NVT/equi_NVT.rst"         -x "$equi_NVT/equi_NVT.nc" -inf "$equi_NVT/equi_NVT.info" > "$equi_NVT/equi_NVT.log" 2>&1
run_container pmemd.cuda_SPFP -O -i "$config/equi_NPT.in"  -p "$topfile" -c "$equi_NVT/equi_NVT.rst" -ref "$equi_NVT/equi_NVT.rst" -o "$equi_NPT/equi_NPT.out" -r "$equi_NPT/equi_NPT.rst" -x "$equi_NPT/equi_NPT.nc" -inf "$equi_NPT/equi_NPT.info" > "$equi_NPT/equi_NPT.log" 2>&1
run_container pmemd.cuda_SPFP -O -i "$config/md_NPT.in"    -p "$topfile" -c "$equi_NPT/equi_NPT.rst" -ref "$equi_NPT/equi_NPT.rst" -o "$md_NPT/md_NPT.out"     -r "$md_NPT/md_NPT.rst"     -x "$md_NPT/md_NPT.nc"     -inf "$md_NPT/md_NPT.info"   > "$md_NPT/md_NPT.log" 2>&1

end=$(date +%s)  # Record end time in minutes
elapsed=$((end - start))  # Compute total time

echo "MD run completed at $(date)"
report_elapsed "MD" "$elapsed"
