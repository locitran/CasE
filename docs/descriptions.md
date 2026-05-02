# Descriptions of important files

`MHC-protein-sequences.json`

- `HLA-A*01:01`: Full nucleotide sequence record for the HLA-A*01:01 allele.
- `HLA-A*03:01`: Full nucleotide sequence record for the HLA-A*03:01 allele.
- `HLA-B*07:02`: Full nucleotide sequence record for the HLA-B*07:02 allele.
- `HLA-B*08:01`: Full nucleotide sequence record for the HLA-B*08:01 allele.
- `sequence`: Full nucleotide sequence for the allele.
- `url`: Source link to the corresponding IPD-IMGT/HLA allele page.
- `Nomenclature`: Formal allele nomenclature string.
- `Aliases`: Alternative allele names used in other references.

`CasE-mutated-peptides.csv`

- `Peptide ID`: Unique identifier for each designed CasE mutant peptide.
- `Peptide`: Mutated peptide sequence.
- `HLA restriction`: HLA allele used for the peptide design or restriction context.
- `Peptide Length`: Length of the peptide sequence.
- `anchor position`: Peptide position selected for anchor-residue mutation.
- `aaWT`: Wild-type amino acid at the mutated position.
- `residue number`: Residue index of the mutated position in the source CasE protein.
- `aaMUT`: Mutant amino acid introduced at that position.

# **Evaluate peptide-HLA’s MHC protein interaction**

1. Check for the specific MHC to be used

HLA- A*01:01, HLA- A*03:01, HLA- B*07:02, and HLA- B*08:01

Specific peptides below (Supplementary table 5, List of CasE mutated peptides)

2. Predict the structure of peptide-MHC complex using Alphafold. In the case that the predicted peptide binding site is at the transmembrane domain of MHC, use a truncated MHC which only has the extracellular part.

For peptide binding, I think simulating just the extra cellular domain is sufficient

3. Run MD simulations (10-20ns) with the tip of the transmembrane domain (say, just one residue) restrained in space without the need of setting up the membrane in the system.

Sounds good to me

4. Calculate the binding energy of the peptides as well as per residue binding energy of the MHC using MMGBSA

Sounds good

---

# Run

Set up environment
```bash
pwd=/mnt/nas_1/YangLab/loci/casE
singularity exec --nv -B /raid -B $pwd /raid/images/amber20.sif bash

pwd=/mnt/nas_1/YangLab/loci/casE
pid=CasE_14_P2V1 # Need to change
type=wt # Need to change

pdbfile=$pwd/data/output/$pid/$type/$pid.pdb
outdir=$pwd/data/output/$pid/"$type"_md
param=$pwd/data/param
console=$outdir/console
cpptraj=$outdir/cpptraj
analysis=$outdir/analysis
mmgbsa=$outdir/mmgbsa

config=$outdir/config
em=$outdir/em
heat=$outdir/heat
equi_NVT=$outdir/equi_NVT
equi_NPT=$outdir/equi_NPT
md_NPT=$outdir/md_NPT

config=/mnt/nas_1/YangLab/loci/casE/data/output/CasE_14_P2V1_25-299/config

topfile=$outdir/protein_solv_ions.parm7
coordfile=$outdir/protein_solv_ions.crd
```

```bash
# Test
/mnt/nas_1/YangLab/loci/casE/data/output/CasE_14_P2V1_25-299/wt/CasE_14_P2V1.pdb

/mnt/nas_1/YangLab/loci/casE/data/output/CasE_14_P2V1_25-299/wt_md/protein_solv_ions.crd
/mnt/nas_1/YangLab/loci/casE/data/output/CasE_14_P2V1_25-299/wt_md/protein_solv_ions.parm7

python $pwd/create_config.py \
    -n $config \
    -p /mnt/nas_1/YangLab/loci/casE/data/output/CasE_14_P2V1_25-299/wt_md/protein_solv_ions.parm7 \
    -c /mnt/nas_1/YangLab/loci/casE/data/output/CasE_14_P2V1_25-299/wt_md/protein_solv_ions.crd \
    -s /mnt/nas_1/YangLab/loci/casE/data/output/CasE_14_P2V1_25-299/wt/CasE_14_P2V1_renumber.pdb 
    # can change
sbatch job...


python /mnt/nas_1/YangLab/loci/casE/mmgbsa_parse.py \
    /mnt/nas_1/YangLab/loci/casE/data/output/CasE_14_P2V1_25-299/wt_md/mmgbsa/mmgbsa.dat
```

## 0. superimposition

```bash
$pwd/align.py \
    $pwd/data/output/CasE_14_P2V1_25-299/wt/CasE_14_P2V1.pdb \
    $pwd/data/pdb/3BP7.pdb \
    $pwd/data/pdb/CasE_14_P2V1wt_to_3BP7.pdb

```

## 1. MD 

```bash
# 1/ Preparation with pdb4amber + propka3
cd $outdir
pdb4amber -i $pdbfile -o $outdir/noh.pdb # Parsing our PDB file using pdb4amber
propka3 $outdir/noh.pdb # Calculating the Protonation state of residues

cd $pwd
python3 protonate_pka.py $outdir/noh.pka $outdir/noh.pdb $outdir/noh_propka.pdb # Edit the residue name based on its pKa
cd $outdir

# 2/ Preparation with tleap
tleap
# set default PBRadii mbondi3: nucleic acid
source leaprc.protein.ff14SB # Load protein force field
source leaprc.water.tip3p # Load water and ions force field
protein = loadpdb noh_propka.pdb # Load your PDB file: contains ligands and water
solvatebox protein TIP3PBOX 10 iso # Solvate your protein TIP3P water model
# Added 26404 residues.

charge protein # Check the overall charge of the system
addIons protein Na+ 0 # Add ion identity to neutralize the system
addIons protein Cl- 0 # Add ion identity to neutralize the system



# N_(Na^+ )=C_(Na^+ )*N_(H_2 O)/55.5=0.15*26404/55.5=~71
addIons protein Na+ 71 Cl- 71 # Add ions to achieve 0.15M Salt Concentration

# Save topology and coordinate files
saveamberparm protein protein_solv_ions.parm7 protein_solv_ions.crd
savepdb protein protein_solv_ions.pdb
quit

# 3/ Energy Minimization Stage 1/2/3
pmemd.cuda_DPFP -O -i $param/min0.in -p $topfile -c $coordfile -o $outdir/min0.out -r $outdir/min0.rst -ref $coordfile -x $outdir/min0.nc -inf $outdir/min0.info > $outdir/min0.console.log 2>&1
pmemd.cuda_DPFP -O -i $param/min1.in -p $topfile -c $outdir/min0.rst -o $outdir/min1.out -r $outdir/min1.rst -ref $outdir/min0.rst -x $outdir/min1.nc -inf $outdir/min1.info > $outdir/min1.console.log 2>&1
pmemd.cuda -O -i $param/min2.in -p $topfile -c $outdir/min1.rst -o $outdir/min2.out -r $outdir/min2.rst -ref $outdir/min1.rst -x $outdir/min2.nc -inf $outdir/min2.info > $outdir/min2.console.log 2>&1
# 4/ NVT Heating
python3 $pwd/temp_inc.py $param/heat.in $outdir/heating.in
pmemd.cuda -O -i "$outdir/heating.in"  -p "$topfile" -c "$outdir/min2.rst" -o "$outdir/heat.out" -r "$outdir/heat.rst" -ref "$outdir/min2.rst" -x "$outdir/heat.nc" -inf "$outdir/heat.info" > "$outdir/heat.console.log" 2>&1
# 5/ NVT Equilibration
pmemd.cuda -O -i "$param/equi_NVT.in" -p $topfile -c "$outdir/heat.rst" -o $outdir/equi_NVT.out -r $outdir/equi_NVT.rst -ref $outdir/heat.rst -x $outdir/equi_NVT.nc -inf $outdir/equi_NVT.info > "$outdir/equi_NVT.console.log" 2>&1
# 6/ NPT Equilibration
pmemd.cuda -O -i $param/equi_NPT.in -p $topfile -c $outdir/equi_NVT.rst -o $outdir/equi_NPT.out -r $outdir/equi_NPT.rst -ref $outdir/equi_NVT.rst -x $outdir/equi_NPT.nc -inf $outdir/equi_NPT.info > "$outdir/equi_NPT.console.log" 2>&1
# 7/ NPT Production run
pmemd.cuda -O -i $param/md_NPT.in -p $topfile -c $outdir/equi_NPT.rst -o $outdir/md_NPT.out -r $outdir/md_NPT.rst -ref $outdir/equi_NPT.rst -x $outdir/md_NPT.nc -inf $outdir/md_NPT.inf> "$outdir/md_NPT.console.log" 2>&1
```

## 2. Analysis

```bash
# cpptraj
# check the structure after minimization
cpptraj
parm $topfile
trajin $em/min0.rst
trajout $em/min0.pdb PDB
run
quit 
# check data of our system
cat > $cpptraj/readOut.in <<EOF
readdata $em/min0.out name min0_out
readdata $em/min1.out name min1_out
readdata $em/min2.out name min2_out
readdata $heat/heat.out name heat_out
readdata $equi_NVT/equi_NVT.out name equi_NVT_out
readdata $equi_NPT/equi_NPT.out name equi_NPT_out
readdata $md_NPT/md_NPT.out name md_NPT_out

writedata $em/min0_all.dat min0_out[*]
writedata $em/min1_all.dat min1_out[*]
writedata $em/min2_all.dat min2_out[*]
writedata $heat/heat_all.dat heat_out[*]
writedata $equi_NVT/equi_NVT_all.dat equi_NVT_out[*]
writedata $equi_NPT/equi_NPT_all.dat equi_NPT_out[*]
writedata $md_NPT/md_NPT_all.dat md_NPT_out[*]
run
quit
EOF
cpptraj -i $cpptraj/readOut.in > "$cpptraj/cpptraj_readOut.log" 2>&1

# check our NPT production run trajectory
cat > $cpptraj/readMDtraj.in <<EOF
parm $topfile
trajin $md_NPT/md_NPT.nc
autoimage :1-383
trajout $md_NPT/md_NPT.dcd DCD
run
quit
EOF
cpptraj -i $cpptraj/readMDtraj.in > "$md_NPT/readMDtraj.log" 2>&1

# RMSD Calculation every 10 frames
cat > $cpptraj/calRMSD_each10.in <<EOF
parm $topfile
trajin $md_NPT/md_NPT.nc 1 last 10
autoimage :1-383
rms ToFirst1 :1-383@CA first out $analysis/rmsd_ca_each10.csv
run
quit
EOF
cpptraj -i $cpptraj/calRMSD_each10.in > "$analysis/calRMSD_each10.log" 2>&1
# --> 100 lines
# We run 100 ns with 50M MD steps (time step 2 femtoseconds): 2 femtoseconds * 50*10^6 steps = 100*10^6 femtosecond 
# Every 50,000 MD steps, the coordinates are written down --> 50,000,000/50,000 = 1000 snapshots (trajectory frames)
# We calculate RMSD for every 10 frames from frame 1 to last frame --> 1000/10 written frames
millisecond (ms) -> microsecond (um) -> nanosecond (ns) -> picosecond (ps) -> femtosecond (fs)
10^-3 s          -> 10^-6 s          -> 10^-9 s         -> 10^-12 s        -> 10^-15 s

2 (fs) * 50,000 = 100,000 fs = 100 ps

# RMSD Calculation every 10 frames / 1frame / pepide 276:284
cat > $cpptraj/calRMSD_peptide_ca_each1.in <<EOF
parm $topfile
trajin $md_NPT/md_NPT.nc 1 last
autoimage :1-383
rms ToFirst1 :276-284@CA first out $md_NPT/rmsd_peptide_ca_each1.csv
run
quit
EOF
cpptraj -i $cpptraj/calRMSD_peptide_ca_each1.in > "$md_NPT/calRMSD_peptide_ca_each1.log" 2>&1
python $pwd/plot_rmsd_csv.py $md_NPT/rmsd_peptide_ca_each1.csv -o $md_NPT/rmsd_peptide_ca_each1.png ##########

# RMSD Calculation every 10 frames
cat > $cpptraj/calRMSD_each1.in <<EOF
parm $topfile
trajin $md_NPT/md_NPT.nc 1 last
autoimage :1-383
rms ToFirst1 :1-383@CA first out $md_NPT/rmsd_ca_each1.csv
run
quit
EOF
cpptraj -i $cpptraj/cpptraj_calRMSD_each1.in > "$md_NPT/calRMSD_each1.log" 2>&1

python $pwd/plot_rmsd_csv.py $md_NPT/rmsd_ca_each10.csv -o $md_NPT/rmsd_ca_each10.png
python $pwd/plot_rmsd_csv.py $md_NPT/rmsd_ca_each1.csv -o $md_NPT/rmsd_ca_each1.png

# RMS Fluctuation
cat > $outdir/cpptraj_calRMSF_each1.in <<EOF
parm $outdir/protein_solv_ions.parm7
trajin $outdir/md_NPT.nc 1 last
autoimage :1-383
rms ToFirst1 :1-383@CA first out $outdir/md_rmsd_ca_each1.csv
run
quit
EOF


parm sample.prmtop
trajin md_NPT.nc
autoimage :1-129
rms first :1-129@CA,C,N,O
atomicfluct out rmsf_backbone.csv :1-129@CA,C,N,O byres 
run


# Convert PDB file 
cpptraj
parm protein_solv_ions.parm7
trajin em/min0.rst
trajout em/min0.pdb PDB
run
quit
```

## 3. MMGBSA

```bash
# Wrapping the trajectory
# ========wrap.in=============
cat > $cpptraj/wrap.in <<EOF
parm $outdir/protein_solv_ions.parm7
trajin $outdir/md_NPT.nc
autoimage :1-383
trajout $outdir/trajectory_wrapped.dcd DCD nobox
run
quit
EOF
# ==========================
cpptraj -i $cpptraj/wrap.in > "$console/wrap.log" 2>&1

ls /usr/local/amber20/bin/ante-MMPBSA.py
source /usr/local/amber20/amber.sh
ante-MMPBSA.py -p $outdir/protein_solv_ions.parm7 -c $outdir/cmp.parm7 -r $outdir/rcp.parm7 -l $outdir/lgd.parm7 -s '!(:1-383)' -m '!(:276-284)'
# -s '!(:1-700)'  This is the mask for creating the complex file without the solvent
# -m '!(:600-700)' This is the mask for creating the ligand part and the remaining for the receptor part

/usr/local/amber20/bin/MMPBSA.py  /usr/local/amber20/bin/MMPBSA.py.MPI
mpirun -np 8 /usr/local/amber20/bin/MMPBSA.py.MPI -O -i $param/mmgbsa.in -o $mmgbsa/result_mmgbsa.dat \

MMPBSA.py -O -i $param/mmgbsa.in -o $mmgbsa/result_mmgbsa.dat \
-sp $outdir/protein_solv_ions.parm7 -cp $outdir/cmp.parm7 -rp $outdir/rcp.parm7 -lp $outdir/lgd.parm7 \
-y  $outdir/trajectory_wrapped.dcd \
-do $mmgbsa/mmgbsa.do -eo $mmgbsa/mmgbsa.eo -deo $mmgbsa/mmgbsa.deo

# 2:39
# CPUs 10
```
