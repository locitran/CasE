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

run_md_stage() {
    local stage_name=$1
    local log_file=$2
    local input_count=3
    local missing=0
    local input_file
    shift 2

    echo ">>> Starting MD stage: $stage_name"
    echo "    Log: $log_file"

    for (( i=0; i<input_count; i++ )); do
        input_file=$1
        shift
        if [[ ! -f "$input_file" ]]; then
        echo "ERROR: missing required input file for $stage_name: $input_file" >&2
        missing=1
        fi
    done

    if (( missing )); then
        return 1
    fi

    if [[ ${1:-} == "--" ]]; then
        shift
    fi

    run_container "$@" > "$log_file" 2>&1

    echo ">>> Finished MD stage: $stage_name"
}

run_md_stage "min0" "$em/min0.log" "$config/min0.in" "$topfile" "$coordfile" -- \
  pmemd.cuda_DPFP -O -i "$config/min0.in" -p "$topfile" -c "$coordfile" -ref "$coordfile" -o "$em/min0.out" -r "$em/min0.rst" -x "$em/min0.nc" -inf "$em/min0.info"

run_md_stage "min1" "$em/min1.log" "$config/min1.in" "$topfile" "$em/min0.rst" -- \
  pmemd.cuda_DPFP -O -i "$config/min1.in" -p "$topfile" -c "$em/min0.rst" -ref "$em/min0.rst" -o "$em/min1.out" -r "$em/min1.rst" -x "$em/min1.nc" -inf "$em/min1.info"

run_md_stage "min2" "$em/min2.log" "$config/min2.in" "$topfile" "$em/min1.rst" -- \
  pmemd.cuda_DPFP -O -i "$config/min2.in" -p "$topfile" -c "$em/min1.rst" -ref "$em/min1.rst" -o "$em/min2.out" -r "$em/min2.rst" -x "$em/min2.nc" -inf "$em/min2.info"

run_md_stage "heating" "$heat/heat.log" "$config/heating.in" "$topfile" "$em/min2.rst" -- \
  pmemd.cuda_SPFP -O -i "$config/heating.in" -p "$topfile" -c "$em/min2.rst" -ref "$em/min2.rst" -o "$heat/heat.out" -r "$heat/heat.rst" -x "$heat/heat.nc" -inf "$heat/heat.info"

run_md_stage "equi_NVT" "$equi_NVT/equi_NVT.log" "$config/equi_NVT.in" "$topfile" "$heat/heat.rst" -- \
  pmemd.cuda_SPFP -O -i "$config/equi_NVT.in" -p "$topfile" -c "$heat/heat.rst" -ref "$heat/heat.rst" -o "$equi_NVT/equi_NVT.out" -r "$equi_NVT/equi_NVT.rst" -x "$equi_NVT/equi_NVT.nc" -inf "$equi_NVT/equi_NVT.info"

run_md_stage "equi_NPT" "$equi_NPT/equi_NPT.log" "$config/equi_NPT.in" "$topfile" "$equi_NVT/equi_NVT.rst" -- \
  pmemd.cuda_SPFP -O -i "$config/equi_NPT.in" -p "$topfile" -c "$equi_NVT/equi_NVT.rst" -ref "$equi_NVT/equi_NVT.rst" -o "$equi_NPT/equi_NPT.out" -r "$equi_NPT/equi_NPT.rst" -x "$equi_NPT/equi_NPT.nc" -inf "$equi_NPT/equi_NPT.info"

run_md_stage "md_NPT" "$md_NPT/md_NPT.log" "$config/md_NPT.in" "$topfile" "$equi_NPT/equi_NPT.rst" -- \
  pmemd.cuda_SPFP -O -i "$config/md_NPT.in" -p "$topfile" -c "$equi_NPT/equi_NPT.rst" -ref "$equi_NPT/equi_NPT.rst" -o "$md_NPT/md_NPT.out" -r "$md_NPT/md_NPT.rst" -x "$md_NPT/md_NPT.nc" -inf "$md_NPT/md_NPT.info"

end=$(date +%s)  # Record end time in minutes
elapsed=$((end - start))  # Compute total time

echo "MD run completed at $(date)"
report_elapsed "MD" "$elapsed"
