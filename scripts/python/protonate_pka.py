#!/usr/bin/env python
import sys
import re
import itertools

input_pka = str(sys.argv[1])
input_pdb = str(sys.argv[2])
output_pdb = str(sys.argv[3])

def Propka_load_propka(pka_file):
    
    with open(pka_file, 'r') as f:
        pka_text = f.read()
    
    pat_begin = '''\
---------  -----   ------   ---------------------    --------------    --------------    --------------
                            DESOLVATION  EFFECTS       SIDECHAIN          BACKBONE        COULOMBIC
 RESIDUE    pKa    BURIED     REGULAR      RE        HYDROGEN BOND     HYDROGEN BOND      INTERACTION
---------  -----   ------   ---------   ---------    --------------    --------------    --------------
'''

    pat_end = '''\
--------------------------------------------------------------------------------------------------------
SUMMARY OF THIS PREDICTION
'''

    pattern = re.compile(r'(?<={pat_begin})([\s\S.]+?)(?={pat_end})'.format(pat_begin=pat_begin, pat_end=pat_end))
    match = re.finditer(pattern, pka_text)
    data = list(match)[0].group().split('\n')
    data = filter(lambda x: len(x) == 103, data)
    
    ########################################################################################
    column_RESIDUE = slice(0,9)
    column_pKa = slice(10,16)
    column_BURIED = slice(17,25)
    column_DESOLVATION_EFFECTS = slice(26,49)
    column_SIDECHAIN_HYDROGEN_BOND = slice(50,67)
    column_BACKBONE_HYDROGEN_BOND = slice(68,85)
    column_COULOMBIC_INTERACTION = slice(86,103)
    
    data = [(line[column_RESIDUE].strip(),
             line[column_pKa].strip(),
             line[column_BURIED].strip(),
             line[column_DESOLVATION_EFFECTS].strip(),
             line[column_SIDECHAIN_HYDROGEN_BOND].strip(),
             line[column_BACKBONE_HYDROGEN_BOND].strip(),
             line[column_COULOMBIC_INTERACTION].strip(),
            ) for line in data]
    
    def gen_parse_data(data):
        data = [list(g) for k, g in itertools.groupby(data, lambda x: x[0])]
        collections = []
        for group in data:
            RESIDUE = group[0][0]
            pKa = group[0][1]
            BURIED = group[0][2]
            DESOLVATION_EFFECTS = group[0][3]
            SIDECHAIN_HYDROGEN_BOND = list(filter(lambda x: x.split()[1] != 'XXX', [item[4] for item in group]))
            BACKBONE_HYDROGEN_BOND = list(filter(lambda x: x.split()[1] != 'XXX', [item[5] for item in group]))
            COULOMBIC_INTERACTION = list(filter(lambda x: x.split()[1] != 'XXX', [item[6] for item in group]))
            collections.append(
                (RESIDUE, pKa, BURIED, DESOLVATION_EFFECTS, SIDECHAIN_HYDROGEN_BOND, BACKBONE_HYDROGEN_BOND, COULOMBIC_INTERACTION)
            )
        return collections
    data = gen_parse_data(data)
    data = [
        (x[0].split()[0], int(x[0].split()[1]), x[0].split()[2], float(x[1])) for x in data]
    
    return data
propka_data = Propka_load_propka(input_pka)

def infer_modify_resnames(propka_data):
    
    pH=7.0
    collections = []
    
    for resname, resnum, chain, pka in propka_data:
        
        # Aspartate
        if resname == 'ASP':
            if pka > pH:
                resname_new = 'ASH'
                collections.append((resname, chain, resnum, resname_new))
        
        # Glutamate
        if resname == 'GLU':
            if pka > pH:
                resname_new = 'GLH'
                collections.append((resname, chain, resnum, resname_new))
        
        # Histidine
        if resname == 'HIS':
            if pka > pH:
                resname_new = 'HIP'
                collections.append((resname, chain, resnum, resname_new))
        
        # lysine
        if resname == 'LYS':
            if pka < pH:
                resname_new = 'LYN'
                collections.append((resname, chain, resnum, resname_new))
            
    return collections
modify_resnames = infer_modify_resnames(propka_data)


with open(input_pdb,  'r') as f:
    pdb_text = f.read().split('\n')
    pdb_text = list(filter(lambda line: line.startswith('ATOM'), pdb_text))

get_resname = lambda line: str(line[17:20])
get_chain = lambda line: str(line[21:22])
get_resnum = lambda line: int(line[22:26])

def modify_pdb_text(pdb_text, modify_resnames):
    modify_resnames = dict(((x[:3], x[3]) for x in modify_resnames))
    collections = []
    for line in pdb_text:
        key = (get_resname(line), get_chain(line), get_resnum(line))
        if key in modify_resnames.keys():
            line_new = line[:17] + modify_resnames[key] + line[20:]
            collections.append(line_new)
        else:
            collections.append(line)
    return collections

pdb_text = modify_pdb_text(pdb_text, modify_resnames)
pdb_text.append('END')

with open(output_pdb, 'w') as f:
    f.write('\n'.join(pdb_text))
