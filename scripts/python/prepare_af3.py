import pandas as pd 
import json
import os 

file_dir = os.path.dirname(os.path.abspath(__file__))
case_data = os.path.join(file_dir, '../data/CasE-mutated-peptides.csv')
mhc_data = os.path.join(file_dir, '../data/MHC-protein-sequences.json')
df_case = pd.read_csv(case_data)
with open(mhc_data, 'r') as f:
    mhc_data = json.load(f)

"""
data/
└── input/
    └── af/
        ├── CasE_55_PΩV1/
        │   ├── wt.json
        │   └── mut.json
        └── CasE_55_PΩV2/
            ├── wt.json
            └── mut.json

{
    "name": "MHC-A01:01_CasE-B07:02_b2mgbl",
    "modelSeeds": [1],
    "dialect": "alphafold3",
    "version": 1,
    "sequences": [
        {"protein": {"id": ["A"], "sequence": ""}},
        {"protein": {"id": ["B"], "sequence": ""}},
        {"protein": {"id": ["C"], "sequence": ""}}
    ]
}
"""

af_input = os.path.join(file_dir, '../data/input/af')
os.makedirs(af_input, exist_ok=True)
b2m_seq = mhc_data['Beta-2-microglobulin']['Protein sequence main (21-119)']
for i in range(len(df_case)):
    Peptide_ID,	Peptide, HLA_restriction, Peptide_Length, anchor_position, aaWT, residue_number, aaMUT = df_case.iloc[i]
    hla_key = [k for k in mhc_data.keys() if HLA_restriction in k]
    if not hla_key:
        print(HLA_restriction)
    else:
        hla_key = hla_key[0]
    hla_seq = mhc_data[hla_key]['Protein sequence'] #### Need to change

    try: 
        int_anchor_pos = int(anchor_position[-1])
    except:
        int_anchor_pos = Peptide_Length
    WT_Peptide = Peptide[:int_anchor_pos-1] + aaWT + Peptide[int_anchor_pos:]

    wt_dict = {
        "name": f"{Peptide_ID}/wt",
        "modelSeeds": [1],
        "dialect": "alphafold3",
        "version": 1,
        "sequences": [
            # MHC
            {"protein": {"id": ["A"], "sequence": hla_seq}},
            # Peptide
            {"protein": {"id": ["B"], "sequence": WT_Peptide}},
            # Beta-2-microglobulin (B2M)
            {"protein": {"id": ["C"], "sequence": b2m_seq}}
        ]
    }
    mut_dict = {
        "name": f"{Peptide_ID}/mut",
        "modelSeeds": [1],
        "dialect": "alphafold3",
        "version": 1,
        "sequences": [
            {"protein": {"id": ["A"], "sequence": hla_seq}},
            {"protein": {"id": ["B"], "sequence": Peptide}},
            {"protein": {"id": ["C"], "sequence": b2m_seq}}
        ]
    }
    os.makedirs(f'{af_input}/{Peptide_ID}', exist_ok=True)

    with open(f'{af_input}/{Peptide_ID}/wt.json', 'w') as f:
        json.dump(wt_dict, f, indent=2)
    with open(f'{af_input}/{Peptide_ID}/mut.json', 'w') as f:
        json.dump(mut_dict, f, indent=2)
    if i == 2:
        break