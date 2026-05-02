import MDAnalysis as mda
from MDAnalysis.analysis import align
from Bio import pairwise2
import itertools

three2one = {
    'ALA': 'A', 'ARG': 'R', 'ASN': 'N', 'ASP': 'D', 'CYS': 'C',
    'GLN': 'Q', 'GLU': 'E', 'GLY': 'G', 'HIS': 'H', 'ILE': 'I',
    'LEU': 'L', 'LYS': 'K', 'MET': 'M', 'PHE': 'F', 'PRO': 'P',
    'SER': 'S', 'THR': 'T', 'TRP': 'W', 'TYR': 'Y', 'VAL': 'V'
}

def superimpose(mobile, reference, out='superimposed.pdb'):
    """Align a mobile structure to a reference using matched protein CA atoms.
    Flow:
    1. Load the mobile and reference structures, then keep only protein CA atoms.
    2. For each segment/chain, convert residue names to a one-letter sequence.
    3. Align reference and mobile sequences chain by chain in the order they appear.
       If the protein has two chains, the first reference chain is paired with the
       first mobile chain, and the second reference chain is paired with the second.
    4. Concatenate the per-chain alignments, keep only matched aligned residues, and
       use those CA atoms to calculate the rotation/translation.
    5. Apply the transform to all atoms in the mobile structure and write it out.
    Logic note:
    This works well when the two structures have the same chain order and comparable
    chain composition. If chain order differs, zip() may pair the wrong chains.
    """
    mobile = mda.Universe(mobile)
    reference = mda.Universe(reference)

    # Select protein and CA atoms 
    ref_ca = reference.select_atoms('protein and name CA').copy()
    mob_ca = mobile.select_atoms('protein and name CA').copy()

    # Extract sequences
    ref_seqs = []
    for segment in ref_ca.segments:
        chain_id = segment.segid 
        seq = ''.join([three2one[r.resname]for r in segment.residues])
        ref_seqs.append((chain_id, seq))

    mob_seqs = []
    for segment in mob_ca.segments:
        chain_id = segment.segid
        seq = ''.join([three2one[r.resname]for r in segment.residues])
        mob_seqs.append((chain_id, seq))
        
    # Perform Global pairwise alignment
    alignments = []
    # ali_indication = ''
    for (ref_chain_id, refseq), (mob_chain_id, mobseq) in zip(ref_seqs, mob_seqs):
        alignment = pairwise2.align.globalms(refseq, mobseq, 2, -1, -3, -2)
        alignment = alignment[0]
        alignment = pairwise2.format_alignment(*alignment).split('\n')
        alignments.append(
            (ref_chain_id, mob_chain_id, alignment)
        )

    # Concatenate the aligned sequences: all to 1 chain
    ref_ali = ''.join([x[2][0] for x in alignments])
    idc_ali = ''.join([x[2][1] for x in alignments])
    mob_ali = ''.join([x[2][2] for x in alignments])
    ref_ali, idc_ali, mob_ali

    # Create a list of residue indices
    counter = itertools.count()
    ref_ali_residx = [next(counter) if c != '-' else -1 for c in ref_ali]
    counter = itertools.count()
    mob_ali_residx = [next(counter) if c != '-' else -1 for c in mob_ali]

    # Matching and non-matching residue indices
    match_residx = []
    nonmatch_residx = []
    for c, x1, x2 in zip(idc_ali, ref_ali_residx, mob_ali_residx):
        if (c in [' ', '.']) or (-1 in [x1, x2]):
            nonmatch_residx.append((x1, x2))
        else:
            match_residx.append((x1, x2))

    # Matching residue indices
    match_residx_ref=[]
    match_residx_mob=[]
    i=0
    while i < len(match_residx):
        match_residx_ref.append(match_residx[i][0])
        match_residx_mob.append(match_residx[i][1])
        i +=1

    # Select atoms
    ref_sel = ref_ca[match_residx_ref]
    mob_sel = mob_ca[match_residx_mob]

    # Superimpose
    ref0 = ref_sel.positions - ref_sel.center_of_mass()
    mob0 = mob_sel.positions - mob_sel.center_of_mass()
    R, rmsd = align.rotation_matrix(mob0, ref0)
    print('RMSD after superimposition:', rmsd)

    mobile.atoms.translate(-mob_sel.center_of_mass())
    mobile.atoms.rotate(R)
    mobile.atoms.translate(ref_sel.center_of_mass())

    mobile.atoms.write(out)

if __name__ == '__main__':
    import sys
    mobile_pdb = sys.argv[1]
    reference_pdb = sys.argv[2]
    out_pdb = sys.argv[3]
    superimpose(mobile_pdb, reference_pdb, out_pdb)
