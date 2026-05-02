#!/bin/bash
#SBATCH --job-name=CasE                      # Job name
#SBATCH --mail-type=BEGIN                   # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=xxx@gmail.com  # Where to send mail
#SBATCH --ntasks=4                          # MPI tasks
#SBATCH --cpus-per-task=10                  # CPUs per task
#SBATCH --mem=64gb                          # Job memory request
#SBATCH --gres=gpu:3g.20gb:1                 # Use 2 GPUs
#SBATCH --output=/mnt/nas_1/YangLab/loci/casE/slurm_log/run_%j.out
#SBATCH --error=/mnt/nas_1/YangLab/loci/casE/slurm_log/run_%j.err
#SBATCH --partition=COMPUTE1Q               # The partition that job submit to
#SBATCH --account=YangLab                   # The account name

#####################################################################################
echo "> SLURM job resources"
echo "ntasks         = ${SLURM_NTASKS:-N/A}"
echo "cpus-per-task  = ${SLURM_CPUS_PER_TASK:-N/A}"
echo "mem-per-node   = ${SLURM_MEM_PER_NODE:-N/A} MB"
echo "gpus           = ${SLURM_GPUS_ON_NODE:-${SLURM_GPUS:-N/A}}"
echo "cuda devices   = ${CUDA_VISIBLE_DEVICES:-N/A}"
#####################################################################################

set -euo pipefail # stops on the first failure.

# Variables used:
# - workdir: casE project root.
# - variant: AF3 case name such as CasE_14_P2V1, loop variable in this script.
# - input_dir/output_dir: AF3 input and output directories for the current variant.
# - type: structure subtype, usually wt or mut, loop variable in this script.
# - report_elapsed: shared helper to print human-readable elapsed time.
# - run_container: shared helper to run AMBER tools inside Singularity.

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

run_container() {
singularity exec --nv -B /raid -B "$workdir" /raid/images/amber20.sif \
    bash -lc "source /usr/local/amber20/amber.sh; $*"
}

########################Set up environment#########################
workdir=/mnt/nas_1/YangLab/loci/casE


# CasE_14_P2V2 CasE_14_P2V3 CasE_14_P2V4 CasE_14_P2V5
for variant in CasE_14_P2V1; do
  export variant
  input_dir=$workdir/data/input/af/$variant
  output_dir=$workdir/data/output/$variant
  source $workdir/scripts/shell/af3.sh

  for type in wt mut; do
    source $workdir/scripts/shell/single_variant.sh
  done
done
