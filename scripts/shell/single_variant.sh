#!/bin/bash

# Variables used:
# - workdir: casE project root, inherited from run.sh or control.sh.
# - variant: AF3 case name such as CasE_14_P2V1, inherited.
# - type: structure subtype, usually wt or mut, inherited.
# - input_cif/input_pdb: AF3 model paths for this variant/type.
# - outdir: output directory for this variant/type.
# - cpptraj/analysis/mmgbsa/tleap/config/em/heat/equi_NVT/equi_NPT/md_NPT:
#   stage-specific working directories under outdir.
# - topfile/coordfile/output_pdb: final AMBER topology, coordinates, and PDB paths.


input_cif=$workdir/data/output/$variant/$type/"$type"_model.cif
input_pdb=$workdir/data/output/$variant/$type/"$type"_model.pdb
outdir=$workdir/data/output/$variant/"$type"_md
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
source $workdir/scripts/shell/pdb4amber.sh
source $workdir/scripts/shell/selection.sh  # $complex_range $peptide_range
source $workdir/scripts/shell/tleap.sh

# # Create configuration files (.in)
python $workdir/scripts/python/create_config.py -n $config -p $topfile -c $coordfile -s $outdir/noh_propka.pdb

# # Run MD
source $workdir/scripts/shell/md.sh

# # Run Analysis
source $workdir/scripts/shell/analysis.sh

# Run MMGBSA
source $workdir/scripts/shell/mmgbsa.sh
