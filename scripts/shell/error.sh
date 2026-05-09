#!/bin/bash
#SBATCH --job-name=error                      # Job name
#SBATCH --mail-type=BEGIN                   # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=xxx@gmail.com  # Where to send mail
#SBATCH --ntasks=2                          # MPI tasks
#SBATCH --cpus-per-task=1                  # CPUs per task
#SBATCH --mem=10gb                          # Job memory request
#SBATCH --output=/mnt/nas_1/YangLab/loci/casE/slurm_log/run_%j.out
#SBATCH --error=/mnt/nas_1/YangLab/loci/casE/slurm_log/run_%j.err
#SBATCH --partition=COMPUTE1Q               # The partition that job submit to
#SBATCH --account=YangLab                   # The account name

workdir=/mnt/nas_1/YangLab/loci/casE
run_container() {
singularity exec --nv -B /raid -B "$workdir" /raid/images/amber20.sif \
    bash -lc "source /usr/local/amber20/amber.sh; $*"
}

sample=HLA-B-GGGGGGGGG
input_dir=$workdir/data/input/control/negative
output_dir=$workdir/data/output/control/negative

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

run_container mpirun -np 2 pmemd.MPI -O \
  -i "$config/min0.in" -p "$topfile" -c "$coordfile" -ref "$coordfile" \
  -o "$em/min0.out" -r "$em/min0.rst" -x "$em/min0.nc" -inf "$em/min0.info"
