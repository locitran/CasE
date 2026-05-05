#!/bin/bash
#SBATCH --job-name=case_wt_md
#SBATCH --account=def-mikeuoft          # <-- change to your allocation
#SBATCH --time=0-4:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=10000M
#SBATCH --gres=gpu:nvidia_h100_80gb_hbm3_1g.10gb:1
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

#####################################################################################
echo "> SLURM job resources"
echo "ntasks         = ${SLURM_NTASKS:-N/A}"
echo "cpus-per-task  = ${SLURM_CPUS_PER_TASK:-N/A}"
echo "mem-per-node   = ${SLURM_MEM_PER_NODE:-N/A} MB"
echo "gpus           = ${SLURM_GPUS_ON_NODE:-${SLURM_GPUS:-N/A}}"
echo "cuda devices   = ${CUDA_VISIBLE_DEVICES:-N/A}"
#####################################################################################

# -------------------------
# Environment setup
# -------------------------
module purge
module load apptainer
module load StdEnv/2023 gcc/12.3 openmpi/4.1.5 cuda/12.6 amber-pmemd/24.3

echo "> Amber tool paths"
which pmemd.cuda_DPFP || true
which pmemd.cuda_SPFP || true
which tleap || true
which cpptraj || true
which pdb4amber || true
which ante-MMPBSA.py || true
which MMPBSA.py.MPI || true
which mpirun || true

set -euo pipefail # stops on the first failure.

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
workdir=/home/locitran/scratch/CasE

run_container() {
  if [[ $# -eq 1 ]]; then
    bash -lc "$1"
  else
    "$@"
  fi
}

for variant in CasE_14_P2V1 CasE_14_P2V2 CasE_14_P2V3 CasE_14_P2V4 CasE_14_P2V5; do
  export variant
  input_dir=$workdir/data/input/af/$variant
  output_dir=$workdir/data/output/$variant

  for type in wt mut; do
    input_cif=$workdir/data/output/$variant/$type/"$type"_model.cif
    input_pdb=$workdir/data/output/$variant/$type/"$type"_model.pdb

    outdir=$workdir/data/output/$variant/"$type"_md
    mkdir -p "$output_dir"

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
    cd $mmgbsa
    source $workdir/scripts/shell/mmgbsa.sh
    
  done
done
