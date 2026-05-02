#!/bin/bash
#SBATCH --job-name=CasE_14_P2V1
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=user@gmail.com
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=20gb
#SBATCH --gres=gpu:1g.5gb:1
#SBATCH --output=out.log
#SBATCH --partition=COMPUTE1Q
#SBATCH --account=yanglab

topfile=/mnt/nas_1/YangLab/loci/casE/data/output/CasE_14_P2V1_25-299/wt_md/protein_solv_ions.parm7
coordfile=/mnt/nas_1/YangLab/loci/casE/data/output/CasE_14_P2V1_25-299/wt_md/protein_solv_ions.crd

#Energy Minimization
singularity exec --nv --bind /raid:/raid /raid/images/amber20.sif pmemd.cuda_DPFP -O -i min0.in -p $topfile -c $coordfile -o min0.out -r min0.rst -ref $coordfile -x min0.nc -inf min0.info

singularity exec --nv --bind /raid:/raid /raid/images/amber20.sif pmemd.cuda_DPFP -O -i min1.in -p $topfile -c min0.rst -o min1.out -r min1.rst -ref min0.rst -x min1.nc -inf min1.info

singularity exec --nv --bind /raid:/raid /raid/images/amber20.sif pmemd.cuda_DPFP -O -i min2.in -p $topfile -c min1.rst -o min2.out -r min2.rst -ref min1.rst -x min2.nc -inf min2.info

#NVT Heating
singularity exec --nv --bind /raid:/raid /raid/images/amber20.sif pmemd.cuda_SPFP -O -i heating.in -p $topfile -c min2.rst -o heat.out -r heat.rst -ref min2.rst -x heat.nc -inf heat.info

#NVT Equilibration
singularity exec --nv --bind /raid:/raid /raid/images/amber20.sif pmemd.cuda_SPFP -O -i equi_NVT.in -p $topfile -c heat.rst -o equi_NVT.out -r equi_NVT.rst -ref heat.rst -x equi_NVT.nc -inf equi_NVT.info

#NPT Equilibration
singularity exec --nv --bind /raid:/raid /raid/images/amber20.sif pmemd.cuda_SPFP -O -i equi_NPT.in -p $topfile -c equi_NVT.rst -o equi_NPT.out -r equi_NPT.rst -ref equi_NVT.rst -x equi_NPT.nc -inf equi_NPT.info

#Production Run
singularity exec --nv --bind /raid:/raid /raid/images/amber20.sif pmemd.cuda_SPFP -O -i md_NPT.in -p $topfile -c equi_NPT.rst -o md_NPT.out -r md_NPT.rst -ref equi_NPT.rst -x md_NPT.nc -inf md_NPT.info
 