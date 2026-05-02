#!/bin/bash
#SBATCH --job-name=CasE                      # Job name
#SBATCH --mail-type=BEGIN                   # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=xxx@gmail.com  # Where to send mail
#SBATCH --ntasks=1                          # MPI tasks
#SBATCH --cpus-per-task=10                  # CPUs per task
#SBATCH --mem=64gb                          # Job memory request
#SBATCH --gres=gpu:1g.5gb:1                 # Use 2 GPUs
#SBATCH --output=/mnt/nas_1/YangLab/loci/casE/slurm_log/run_%j.out
#SBATCH --error=/mnt/nas_1/YangLab/loci/casE/slurm_log/run_%j.err
#SBATCH --partition=COMPUTE1Q               # The partition that job submit to
#SBATCH --account=YangLab                   # The account name

# Variables used:
# - af3dir: local AlphaFold 3 installation/container directory.
# - workdir: casE project root.
# - report_elapsed: helper to print human-readable elapsed time.
# - start/end/elapsed: timestamps used for runtime reporting.

report_elapsed() {
  local label=$1
  local elapsed=$2
  local elapsed_text

  if (( elapsed >= 3600 )); then
    elapsed_text=$(awk -v s="$elapsed" 'BEGIN { h = s / 3600; unit = (h < 1.5 ? "hour" : "hours"); printf "%.2f %s", h, unit }')
  elif (( elapsed >= 60 )); then
    elapsed_text=$(awk -v s="$elapsed" 'BEGIN { m = s / 60; unit = (m < 1.5 ? "minute" : "minutes"); printf "%.2f %s", m, unit }')
  else
    if (( elapsed == 1 )); then
      elapsed_text="1 second"
    else
      elapsed_text="${elapsed} seconds"
    fi
  fi

  echo "==================================="
  echo "Elapsed Time of \"$label\": $elapsed_text"
  echo "==================================="
}

af3dir=/mnt/nas_1/YangLab/alphafold3
workdir=/mnt/nas_1/YangLab/loci/casE


echo "> Starting AlphaFold 3 run at $(date)"
start=$(date +%s)  # Record start time in minutes
# --json_path=/af_input/MHC-CasE_peptide.json \
singularity exec \
  --nv \
  --bind $af3dir:/root \
  --bind $workdir/data/input:/input \
  --bind $workdir/data/output:/output \
  $af3dir/alphafold3_2026Apr6.sif \
  /alphafold3_venv/bin/python /root/run_alphafold.py \
  --json_path=/input/af/HLA-B-full.json \
  --model_dir=/root/models \
  --db_dir=/root/db \
  --output_dir=/output/

end=$(date +%s)  # Record end time in minutes
elapsed=$((end - start))  # Compute total time
echo "> AlphaFold 3 run completed at $(date)"
report_elapsed "AlphaFold 3" "$elapsed"
########################################################
