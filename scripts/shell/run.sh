#!/bin/bash
#SBATCH --job-name=CasE                      # Job name
#SBATCH --mail-type=BEGIN                   # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=xxx@gmail.com  # Where to send mail
#SBATCH --ntasks=4                          # MPI tasks
#SBATCH --cpus-per-task=10                  # CPUs per task
#SBATCH --mem=64gb                          # Job memory request
#SBATCH --gres=gpu:2g.10gb:2                 # Use 2 GPUs
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

########################Set up environment#########################
workdir=/mnt/nas_1/YangLab/loci/casE

run_container() {
singularity exec --nv -B /raid -B "$workdir" /raid/images/amber20.sif \
    bash -lc "source /usr/local/amber20/amber.sh; $*"
}

# CasE_14_P2V2 CasE_14_P2V3 CasE_14_P2V4 CasE_14_P2V5
for variant in CasE_14_P2V1 CasE_14_P2V2 CasE_14_P2V3 CasE_14_P2V4 CasE_14_P2V5; do
  export variant
  input_dir=$workdir/data/input/af/$variant
  output_dir=$workdir/data/output/$variant
  source $workdir/scripts/shell/af3.sh

  for type in wt mut; do
    input_cif=$workdir/data/output/$variant/$type/"$type"_model.cif
    input_pdb=$workdir/data/output/$variant/$type/"$type"_model.pdb

    outdir=$workdir/data/output/$variant/"$type"_md
    mkdir -p $output_dir

    console=$outdir/console
    cpptraj=$outdir/cpptraj
    analysis=$outdir/analysis
    mmgbsa=$outdir/mmgbsa
    param=$workdir/data/param

    tleap=$outdir/tleap
    config=$outdir/config
    em=$outdir/em
    heat=$outdir/heat
    equi_NVT=$outdir/equi_NVT
    equi_NPT=$outdir/equi_NPT
    md_NPT=$outdir/md_NPT

    topfile=$outdir/protein_solv_ions.parm7
    coordfile=$outdir/protein_solv_ions.crd
    output_pdb=$outdir/protein_solv_ions.pdb

    # Create folder if not exist
    mkdir -p "$outdir" "$cpptraj" "$analysis" "$mmgbsa" "$em" "$heat" "$equi_NVT" "$equi_NPT" "$md_NPT" "$config" "$tleap"
    export outdir cpptraj analysis mmgbsa topfile coordfile em heat equi_NVT equi_NPT md_NPT tleap config

    ##############################################################################
    # System preparation
    source $workdir/scripts/shell/pdb4amber.sh
    source $workdir/scripts/shell/selection.sh  # $complex_range $peptide_range
    source $workdir/scripts/shell/tleap.sh

    # # Create configuration files (.in)
    python $workdir/scripts/python/create_config.py -n $config -p $topfile -c $coordfile -s $outdir/noh_propka.pdb

    # Run MD
    cd $md_NPT
    source $workdir/scripts/shell/md.sh

    # Run check MD results
    source $workdir/scripts/shell/check.sh

    # Run Analysis
    cd $analysis
    source $workdir/scripts/shell/analysis.sh

    # Run MMGBSA
    mkdir -p $mmgbsa/temp
    cd $mmgbsa/temp
    source $workdir/scripts/shell/mmgbsa.sh
    
  done
done