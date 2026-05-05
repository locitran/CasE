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


# --> 100 lines
# We run 100 ns with 50M MD steps (time step 2 femtoseconds): 2 femtoseconds * 50*10^6 steps = 100*10^6 femtosecond 
# Every 50,000 MD steps, the coordinates are written down --> 50,000,000/50,000 = 1000 snapshots (trajectory frames)
# We calculate RMSD for every 10 frames from frame 1 to last frame --> 1000/10 written frames
millisecond (ms) -> microsecond (um) -> nanosecond (ns) -> picosecond (ps) -> femtosecond (fs)
10^-3 s          -> 10^-6 s          -> 10^-9 s         -> 10^-12 s        -> 10^-15 s

2 (fs) * 50,000 = 100,000 fs = 100 ps


# Convert PDB file 
cpptraj
parm protein_solv_ions.parm7
trajin em/min0.rst
trajout em/min0.pdb PDB
run
quit
```

```bash
python /mnt/nas_1/YangLab/loci/casE/scripts/python/parseMMGBSA.py \
    /mnt/nas_1/YangLab/loci/casE/data/output/control/negative/HLA-B-16072718/md/mmgbsa/mmgbsa.do
```

## MMGBSA output summary

Example folder:

```bash
/mnt/nas_1/YangLab/loci/casE/data/output/control/negative/HLA-B-16072718/md/mmgbsa
```

Important files:

- `result_mmgbsa.dat`: main MMGBSA summary. This is the first file to read for the final binding energy.
- `mmgbsa.eo`: per-frame total energy components in CSV-like format.
- `mmgbsa.do`: per-residue decomposition output.
- `mmgbsa.deo`: detailed per-residue pair decomposition output.
- `complex.parm7`, `receptor.parm7`, `ligand.parm7`: topology files generated by `ante-MMPBSA.py`.
- `_MMPBSA_*.nc.*`, `_MMPBSA_*.mdout.*`, `_MMPBSA_*_surf.dat.*`: temporary/intermediate files from MMPBSA calculations.

For `HLA-B-16072718`, the key result is in `result_mmgbsa.dat`:

```text
Differences (Complex - Receptor - Ligand)
DELTA TOTAL = -131.3207 kcal/mol
Std. Dev.   = 9.1980
Std. Err.   = 2.9087
```

Interpretation:

- `Complex`: energy of peptide + receptor together.
- `Receptor`: energy of receptor alone.
- `Ligand`: energy of peptide alone.
- `Differences`: binding energy estimate, calculated as `Complex - Receptor - Ligand`.
- `DELTA TOTAL`: final MMGBSA binding energy estimate.
- More negative `DELTA TOTAL` means stronger predicted binding, but compare systems only when the same trajectory length, frame selection, topology setup, and MMGBSA settings are used.

For this example:

```text
DELTA TOTAL = -131.3207 kcal/mol
```

This suggests favorable binding for the selected frames. The uncertainty is about `2.9 kcal/mol` as standard error of the mean.

To parse decomposition-style outputs:

```bash
cd /mnt/nas_1/YangLab/loci/casE/data/output/control/negative/HLA-B-16072718/md/mmgbsa
python /mnt/nas_1/YangLab/loci/casE/scripts/python/parseMMGBSA.py mmgbsa.do
```

This creates files such as:

```text
mmgbsa_complex.dat
mmgbsa_receptor.dat
mmgbsa_ligand.dat
mmgbsa_complex.1.csv
mmgbsa_receptor.1.csv
mmgbsa_ligand.1.csv
```

Note: `parseMMGBSA.py` is mainly useful for decomposition output such as `mmgbsa.do`. For the final total binding energy, read `result_mmgbsa.dat` directly.




# Error 


Error: an illegal memory access was encountered launching kernel kClearForces
