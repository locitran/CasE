#!/bin/bash

# Pre-defined variables:
# - workdir: casE project root, inherited from the caller.
# - input_dir: AF3 input directory for this variant, inherited from the caller.
# - output_dir: AF3 output directory for this variant, inherited from the caller.

af3dir=/mnt/nas_1/YangLab/alphafold3

echo "> Starting AlphaFold 3 run at $(date)"
start=$(date +%s)  # Record start time in minutes
# --json_path=/af_input/MHC-CasE_peptide.json \
singularity exec \
  --nv \
  --bind $af3dir:/root \
  --bind $workdir:$workdir \
  --bind $workdir/data/input:/input \
  --bind $workdir/data/output:/output \
  $af3dir/alphafold3_2026Apr6.sif \
  /alphafold3_venv/bin/python /root/run_alphafold.py \
  --input_dir=$input_dir \
  --model_dir=/root/models \
  --db_dir=/root/db \
  --output_dir=$output_dir

end=$(date +%s)  # Record end time in minutes
elapsed=$((end - start))  # Compute total time
echo "> AlphaFold 3 run completed at $(date)"
report_elapsed "AlphaFold 3" "$elapsed"
########################################################
