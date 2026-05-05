#!/bin/bash
#SBATCH --job-name=control                      # Job name
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
# - variant: control case name, used to build input/output paths.
# - input_dir: AF3 input directory for the control case.
# - output_dir: AF3 output directory for the control case.
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

workdir=/mnt/nas_1/YangLab/loci/casE
run_container() {
singularity exec --nv -B /raid -B "$workdir" /raid/images/amber20.sif \
    bash -lc "source /usr/local/amber20/amber.sh; $*"
}

# HLA-B-16072718 HLA-B-AAAAAAAAL HLA-B-EDEDEDEDE
for sample in  HLA-B-GGGGGGGGG; do
# for sample in  HLA-B-16072718; do
  input_dir=$workdir/data/input/control/negative
  output_dir=$workdir/data/output/control/negative

  # source $workdir/scripts/shell/af3.sh
  # cp -r $input_dir "$output_dir"/af3_json 
  ######################## RUN #########################
  input_cif=$workdir/data/output/control/negative/$sample/"$sample"_model.cif
  input_pdb=$workdir/data/output/control/negative/$sample/"$sample"_model.pdb

  outdir=$workdir/data/output/control/negative/$sample/md
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

  ###############################################################################
  # System preparation
  # source $workdir/scripts/shell/pdb4amber.sh
  # source $workdir/scripts/shell/selection.sh  # $complex_range $peptide_range
  # source $workdir/scripts/shell/tleap.sh

  # # # Create configuration files (.in)
  # python $workdir/scripts/python/create_config.py -n $config -p $topfile -c $coordfile -s $outdir/noh_propka.pdb

  # # Run MD
  # cd $md_NPT
  # source $workdir/scripts/shell/md.sh

  # Run check MD results
  source $workdir/scripts/shell/check.sh

  # # Run Analysis
  # cd $analysis
  # source $workdir/scripts/shell/analysis.sh

  # # Run MMGBSA
  # cd $mmgbsa
  # source $workdir/scripts/shell/mmgbsa.sh

done

# bash /mnt/nas_1/YangLab/loci/casE/scripts/shell/control.sh > test.log 2>&1
