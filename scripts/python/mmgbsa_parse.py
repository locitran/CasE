import os
import sys
import math
import numpy as np
from sys import argv

file=argv[1]
fwrite=open("mmgbsa_complex.dat", 'w')
flag=False
with open(file,'r') as f:
    for line in f:
        if line.startswith('Complex:'):
            flag=True
        if flag:
            fwrite.write(line)
        if line.strip().endswith('Receptor:'):
            flag=False

fwrite=open("mmgbsa_receptor.dat", 'w')
flag=False
with open(file,'r') as f:
    for line in f:
        if line.startswith('Receptor:'):
            flag=True
        if flag:
            fwrite.write(line)
        if line.strip().endswith('Ligand:'):
            flag=False
            
fwrite=open("mmgbsa_ligand.dat", 'w')
flag=False
with open(file,'r') as f:
    for line in f:
        if line.startswith('Ligand:'):
            flag=True
        if flag:
            fwrite.write(line)
        if line.strip().endswith('DELTAS:'):
            flag=False
            
fwrite=open("mmgbsa_deltas.dat", 'w')
flag=False
with open(file,'r') as f:
    for line in f:
        if line.startswith('D,E,L,T,A,S,:'):
            flag=True
        if flag:
            fwrite.write(line)
        if line.strip().endswith('DG3  90'):
            flag=False

fwrite=open("mmgbsa.dat.0", 'w')
flag=False
with open(file,'r') as f:
    for line in f:
        if line.startswith('DELTAS:'):
            flag=True
        if flag:
            fwrite.write(line)
        if line.strip().endswith('DG3  90'):
            flag=False

file1='mmgbsa_complex.dat'
file2='mmgbsa_receptor.dat'
file3='mmgbsa_ligand.dat'
file4='mmgbsa_deltas.dat'
inputfile = file1
splittingtxt = 'Energy Decomposition'
filenameformat = 'mmgbsa_complex.#.csv'

def newfout(filenum):
    filename = filenameformat.replace('#',str(filenum) )
    fout=open(filename,'w')
    return fout

file = open( inputfile )
lines=file.readlines()[2:-2]
    
filenum=1
fout = newfout(filenum)

for line in lines:
    if splittingtxt in line:
        fout.close()
        filenum+=1
        fout = newfout( filenum )
    else:
        fout.write(line)
        
fout.close()

inputfile = file2
splittingtxt = 'Energy Decomposition'
filenameformat = 'mmgbsa_receptor.#.csv'

def newfout(filenum):
    filename = filenameformat.replace('#',str(filenum) )
    fout=open(filename,'w')
    return fout

file = open( inputfile )
lines=file.readlines()[2:-2]
    
filenum=1
fout = newfout(filenum)

for line in lines:
    if splittingtxt in line:
        fout.close()
        filenum+=1
        fout = newfout( filenum )
    else:
        fout.write(line)
        
fout.close()

inputfile = file3
splittingtxt = 'Energy Decomposition'
filenameformat = 'mmgbsa_ligand.#.csv'

def newfout(filenum):
    filename = filenameformat.replace('#',str(filenum) )
    fout=open(filename,'w')
    return fout

file = open( inputfile )
lines=file.readlines()[2:-2]
    
filenum=1
fout = newfout(filenum)

for line in lines:
    if splittingtxt in line:
        fout.close()
        filenum+=1
        fout = newfout( filenum )
    else:
        fout.write(line)
        
fout.close()

inputfile = file4
splittingtxt = 'E,n,e,r,g,y, ,D,e,c,o,m,p,o,s,i,t,i,o,n'
filenameformat = 'mmgbsa_deltas.#.csv'

def newfout(filenum):
    filename = filenameformat.replace('#',str(filenum) )
    fout=open(filename,'w')
    return fout

file = open( inputfile )
lines=file.readlines()[2:-1]
    
filenum=1
fout = newfout(filenum)

for line in lines:
    if splittingtxt in line:
        fout.close()
        filenum+=1
        fout = newfout( filenum )
    else:
        fout.write(line)
        
fout.close()
