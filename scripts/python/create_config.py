
import os
import argparse
from model_confidence import get_amber_res_blocks

description="""
Generate Amber input files for AF3 structures.
Automatically classifies residues by AF3 B-factor confidence
and applies restraint schemes for minimization, heating,
equilibration, and production MD.
"""
parser = argparse.ArgumentParser(description=description, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-n", "--name",required=True,help="Job / folder name")
parser.add_argument("-p", "--prmtop",required=True,help="Amber topology file (.prmtop)")
parser.add_argument("-c", "--coord",required=True,help="Amber coordinate file (.crd or .rst7)")
parser.add_argument("-s", "--structure",required=True,help="AF3 PDB structure used to extract B-factor confidence")
args = parser.parse_args()

############Input files##################################
folder=args.name #folder name 
topolfile=args.prmtop #.prmtop
coordfile=args.coord #.crd file
pdbfile=args.structure #pdb after pdb4amber
##########################################################


############Step related parameters#######################
#Number of steps per stage
min_steps_sdcg=5000
min_steps_sd=2500
min_ener_steps=10         #Save energy info every 10 steps
min_traj_steps=100        #Save snapshot every 100 steps
min_restart_steps=100   #Save restart file every 100 steps
############Heating related###############################
# heating_steps=5000000       #1,0000ps or 10ns
heating_steps=500000       
heating_ener_steps=50000    #Save energy info every 100ps
heating_traj_steps=50000    #Save snapshot every 100ps
heating_restart_steps=50000 #Save restart file every 100ps
###########NVT Equilibration related#######################
# equi_NVT_steps=5000000      #10,000ps or 10ns
equi_NVT_steps=500000      
equi_NVT_ener_steps=50000   #Save energy info every 100ps
equi_NVT_traj_steps=50000   #Save snapshot info every 100ps
equi_NVT_restart_steps=50000 #Save restart file every 100ps
###########NPT Equilibration related#######################
# equi_NPT_steps=5000000      #10,000ps or 10ns
equi_NPT_steps=500000     
equi_NPT_ener_steps=50000   #Save energy info every 100ps
equi_NPT_traj_steps=50000   #Save snapshot info every 100ps
equi_NPT_restart_steps=50000 #Save restart file every 100ps
##########NPT Production related###########################
# md_NPT_steps=50000000      #100,000ps or 100ns
md_NPT_steps=5000000   
md_NPT_ener_steps=50000    #Save energy info every 100ps
md_NPT_traj_steps=50000    #Save snapshot info every 100ps
md_NPT_restart_steps=50000 #Save restart file every 100ps
###########################################################
delta_t=0.002 #ps per frame


###################Other parameters########################
cutoff=10.0 #Angstroms
itemp=50 #Initial Temperature (K)
rtemp=310.0  #Reference Temperature (K)
pressure=1.0123 #units in bar equal to 1 atm

####################Restraints#############################
#Energy Minimization stage 1 restraints
min1_res="!(@H=|:WAT|@Na+|@Cl-)"
min1_resf=25.0

#Energy Minimization stage 2 restraints 
min2_resf_70up=10.0
min2_resf_70below=2.0

#Energy Minimization stage 3 restraints
min3_resf_70up=5.0
min3_resf_70below=2.0

#Heating restraints
heat_resf_70up=5.0
heat_resf_70below=2.0

#Equilibration NVT restraints
equiNVT_resf_70up=2.0
equiNVT_resf_70below=0.50

#Equilibration NPT restraints
equiNPT_resf_70up=1.0
equiNPT_resf_70below=0.10
###########################################################

################Getting list of residues above and below confidence score threshold####
high_res, low_res = get_amber_res_blocks(pdbfile, cutoff=70.0)

high_res_txt = "\n".join(high_res)
low_res_txt  = "\n".join(low_res)
#######################################################################################


#Energy Minimization Stage 1
with open(f"{folder}/min0.in", "w") as file:
    file.write(
f"""
#Type of Simulation Being Done: Energy Minimization, Stage1, RESTRAINING ALL HEAVY ATOMS EXCEPT WATER AND IONS,
 &cntrl
  ntxo=2, IOUTFM=1, !NetCDF Binary Format.
  imin=1, !Energy Minimization
  maxcyc={min_steps_sdcg}, !Total Minimization Cycles to be run. Steepest Decent First, then Conjugate Gradient Method if ncyc < maxcyc
  ncyc={min_steps_sd}, !Number of Steepest Decent Minimization Steps to run before switching to Conjugate Gradient
  cut={cutoff}, !Cut Off Distance for Non-Bounded Interactions
  igb=0, !No Generalized Born
  ntp=0, !No pressure scaling (Default)
  ntb=1, !Constant Volume. (default when igb and ntp are both 0, which are their defaults)
  ntf=1, !Complete Interactions are Calculated
  ntc=1, !SHAKE is NOT performed, DEFAULT
  ntpr={min_ener_steps}, !Every {min_ener_steps} steps, energy information will be printed in human-readable form to files "mdout" and "mdinfo"
  ntwx={min_traj_steps}, !Every {min_traj_steps} steps, the coordinates will be written to the mdcrd file
  ntwr={min_restart_steps}, !Every {min_restart_steps} steps during dynamics, the restart file will be written, ensuring that recovery from a crash will not be so painful. #If ntwr < 0, a unique copy of the file, "restrt_<nstep>", is written every abs(ntwr) steps
  ntr=1, !Turn ON (Cartesian) Restraints
  restraintmask='{min1_res}', !Atoms to be Restrained are specified by a restraintmask
  restraint_wt={min1_resf}, !Force Constant for Restraint, kcal/(mol * A^2)
/
  """)

#Energy Minimization Stage 2
with open(f"{folder}/min1.in", "w") as file:
    file.write(
f"""#Type of Simulation Being Done: Energy Minimization, Stage2
 &cntrl
  ntxo=2, IOUTFM=1, !NetCDF Binary Format.
  imin=1, !Energy Minimization
  maxcyc={min_steps_sdcg}, !Total Minimization Cycles to be run. Steepest Decent First, then Conjugate Gradient Method if ncyc < maxcyc
  ncyc={min_steps_sd}, !Number of Steepest Decent Minimization Steps to run before switching to Conjugate Gradient
  cut={cutoff}, !Cut Off Distance for Non-Bounded Interactions
  igb=0, !No Generalized Born
  ntp=0, !No pressure scaling (Default)
  ntb=1, !Constant Volume. (default when igb and ntp are both 0, which are their defaults)
  ntf=1, !Complete Interactions are Calculated
  ntc=1, !SHAKE is NOT performed, DEFAULT
  ntpr={min_ener_steps}, !Every {min_ener_steps} steps, energy information will be printed in human-readable form to files "mdout" and "mdinfo"
  ntwx={min_traj_steps}, !Every {min_traj_steps} steps, the coordinates will be written to the mdcrd file
  ntwr={min_restart_steps}, !Every {min_restart_steps} steps during dynamics, the restart file will be written, ensuring that recovery from a crash will not be so painful. #If ntwr < 0, a unique copy of the file, "restrt_<nstep>", is written every abs(ntwr) steps
  ntr=1, !Turn ON (Cartesian) Restraints
/
Hold Residues with B-factor_more_than_70
{min2_resf_70up}
FIND
CA * * *
P * * *
C2 * * *
C4' * * *
SEARCH
{high_res_txt}
END
Hold Residues with B-factor_less_than_70
{min2_resf_70below}
FIND
CA * * *
P * * *
C2 * * *
C4' * * *
SEARCH
{low_res_txt}
END
END
""")


#Energy Minimization Stage 3
with open(f"{folder}/min2.in", "w") as file:
    file.write(
f"""#Type of Simulation Being Done: Energy Minimization, Stage3
 &cntrl
  ntxo=2, IOUTFM=1, !NetCDF Binary Format.
  imin=1, !Energy Minimization
  maxcyc={min_steps_sdcg}, !Total Minimization Cycles to be run. Steepest Decent First, then Conjugate Gradient Method if ncyc < maxcyc
  ncyc={min_steps_sd}, !Number of Steepest Decent Minimization Steps to run before switching to Conjugate Gradient
  cut={cutoff}, !Cut Off Distance for Non-Bounded Interactions
  igb=0, !No Generalized Born
  ntp=0, !No pressure scaling (Default)
  ntb=1, !Constant Volume. (default when igb and ntp are both 0, which are their defaults)
  ntf=1, !Complete Interactions are Calculated
  ntc=1, !SHAKE is NOT performed, DEFAULT
  ntpr={min_ener_steps}, !Every {min_ener_steps} steps, energy information will be printed in human-readable form to files "mdout" and "mdinfo"
  ntwx={min_traj_steps}, !Every {min_traj_steps} steps, the coordinates will be written to the mdcrd file
  ntwr={min_restart_steps}, !Every {min_restart_steps} steps during dynamics, the restart file will be written, ensuring that recovery from a crash will not be so painful. #If ntwr < 0, a unique copy of the file, "restrt_<nstep>", is written every abs(ntwr) steps
  ntr=1, !Turn ON (Cartesian) Restraints
/
Hold Residues with B-factor_more_than_70
{min3_resf_70up}
FIND
CA * * *
P * * *
C2 * * *
C4' * * *
SEARCH
{high_res_txt}
END
Hold Residues with B-factor_less_than_70
{min3_resf_70below}
FIND
CA * * *
P * * *
C2 * * *
C4' * * *
SEARCH
{low_res_txt}
END
END
""")

#Heating Stage
with open(f"{folder}/heat.in", "w") as file:
    file.write(
f"""#Type of Simulation Being Done: Heating,
 &cntrl
  ntxo=2, IOUTFM=1, !NetCDF Binary Format.
  imin=0, !MD Simulation
  irest=0, !Do NOT Restart the Simulation; instead, run as a NEW Simulation
  ig=-1, !Pseudo-random number seed is changed with every run.
  ntx=1, !Coordinates, but no Velocities, will be read. Formatted (ASCII) coordinate file is expected
  nstlim={heating_steps}, !Number of MD-steps to be performed. Default 1.
  dt={delta_t}, !The time step (psec). Recommended MAXIMUM is .002 if SHAKE is used, or .001 if SHAKE is NOT used
  cut={cutoff}, !Cut Off Distance for Non-Bounded Interactions
  igb=0, !No Generalized Born
  ntp=0, !No pressure scaling (Default)
  ntb=1, !Constant Volume. (default when igb and ntp are both 0, which are their defaults)
  ntf=2, !Bond Interactions involving H-atoms omitted
  ntc=2, !Bonds involving Hydrogen are Constrained
  ntpr={heating_ener_steps}, !Every {heating_ener_steps} steps, energy information will be printed in human-readable form to files "mdout" and "mdinfo"
  ntwx={heating_traj_steps}, !Every {heating_traj_steps} steps, the coordinates will be written to the mdcrd file
  ntwr={heating_restart_steps}, !Every {heating_restart_steps} steps during dynamics, the restart file will be written, ensuring that recovery from a crash will not be so painful. #If ntwr < 0, a unique copy of the file, "restrt_<nstep>", is written every abs(ntwr) steps
  ntt=3, !Use Langevin Dynamics with the Collision Frequency GAMA given by gamma_ln,
  gamma_ln=2.00000, !Collision Frequency, ps ^ (-1)
  tempi=50.00000, !Initial Temperature
  ntr=1, !Turn ON (Cartesian) Restraints
/
""")

with open(f"{folder}/heat_res.in", "w") as file:
    file.write(
f"""
Hold Residues with B-factor_more_than_70
{heat_resf_70up}
FIND
CA * * *
P * * *
C2 * * *
C4' * * *
SEARCH
{high_res_txt}
END
Hold Residues with B-factor_less_than_70
{heat_resf_70below}
FIND
CA * * *
P * * *
C2 * * *
C4' * * *
SEARCH
{low_res_txt}
END
END
""")

init_step = 0
total_step = {heating_steps}
temp_inc  = 5
init_temp = 50.0
norm_temp = 310.0
max_temp  = 320.0
interval  = ((max_temp-init_temp)/temp_inc)+((max_temp-norm_temp)/temp_inc)
step_inc  = int(heating_steps/interval)


heat_in = f"{folder}/heat.in"
tempfile  = f"{folder}/temp_inc.in"
resfile = f"{folder}/heat_res.in"

TempFile = open(tempfile, 'w')
while (init_temp < max_temp):
    TempFile.writelines("&wt type='TEMP0', istep1=" + str(init_step) + ", istep2=" + str(init_step+step_inc) + ", value1=" + str(init_temp) + ", value2=" + str(init_temp+5) +", /" + "\n")
    init_step = init_step + step_inc
    init_temp = init_temp + 5

while (max_temp > norm_temp):
    if max_temp == norm_temp:
        TempFile.writelines("&wt type='TEMP0', istep1=" + str(init_step) + ", istep2=" + str(total_step) + ", value1=" + str(norm_temp) + ", value2=" + str(norm_temp) +", /" + "\n")
    else:
        TempFile.writelines("&wt type='TEMP0', istep1=" + str(init_step) + ", istep2=" + str(init_step+step_inc) + ", value1=" + str(max_temp) + ", value2=" + str(max_temp-5) +", /" + "\n")
        init_step = init_step + step_inc
        max_temp = max_temp - 5
        
TempFile.writelines("&wt type='END' /")
TempFile.close()

#merge the heating input file and the step by step temp increment
merge_file = "cat " + heat_in + " " + tempfile + " " + resfile + f" > {folder}/heating.in"
os.system(merge_file)

# NVT Equilibration

with open(f"{folder}/equi_NVT.in", "w") as file:
    file.write(
f"""#Type of Simulation Being Done: NVT Equilibration,
 &cntrl
  ntxo=2, IOUTFM=1, !NetCDF Binary Format.
  imin=0, !MD Simulation
  irest=1, !Continue the simulation
  ig=-1, !Pseudo-random number seed is changed with every run.
  ntx=5, !Coordinates and Velocities, will be read. Formatted (ASCII) coordinate file is expected
  nstlim={equi_NVT_steps}, !Number of MD-steps to be performed. Default 1.
  dt={delta_t}, !The time step (psec). Recommended MAXIMUM is .002 if SHAKE is used, or .001 if SHAKE is NOT used
  cut={cutoff}, !Cut Off Distance for Non-Bounded Interactions
  igb=0, !No Generalized Born
  ntp=0, !No pressure scaling (Default)
  ntb=1, !Constant Volume. (default when igb and ntp are both 0, which are their defaults)
  ntf=2, !Bond Interactions involving H-atoms omitted
  ntc=2, !Bonds involving Hydrogen are Constrained
  ntpr={equi_NVT_ener_steps}, !Every {equi_NVT_ener_steps} steps, energy information will be printed in human-readable form to files "mdout" and "mdinfo"
  ntwx={equi_NVT_traj_steps}, !Every {equi_NVT_traj_steps} steps, the coordinates will be written to the mdcrd file
  ntwr={equi_NVT_restart_steps}, !Every {equi_NVT_restart_steps} steps during dynamics, the restart file will be written, ensuring that recovery from a crash will not be so painful. #If ntwr < 0, a unique copy of the file, "restrt_<nstep>", is written every abs(ntwr) steps
  ntt=3, !Use Langevin Dynamics with the Collision Frequency GAMA given by gamma_ln,
  gamma_ln=2.00000, !Collision Frequency, ps ^ (-1)
  temp0=310.00000, !Reference temperature at which the system is to be kept
  tempi=310.00000, !Initial Temperature
  ntr=1, !Turn ON (Cartesian) Restraints
/
Hold Residues with B-factor_more_than_70
{equiNVT_resf_70up}
FIND
CA * * *
P * * *
C2 * * *
C4' * * *
SEARCH
{high_res_txt}
END
Hold Residues with B-factor_less_than_70
{equiNVT_resf_70below}
FIND
CA * * *
P * * *
C2 * * *
C4' * * *
SEARCH
{low_res_txt}
END
END
 """)

# NPT Equilibration

with open(f"{folder}/equi_NPT.in", "w") as file:
    file.write(
f"""#Type of Simulation Being Done: NPT Equilibration,
 &cntrl
  ntxo=2, IOUTFM=1, !NetCDF Binary Format.
  imin=0, !MD Simulation
  irest=1, !Continue the simulations
  ig=-1, !Pseudo-random number seed is changed with every run.
  ntx=5, !Coordinates and Velocities will be read; a formatted (ASCII) coordinate file is expected.
  nstlim={equi_NPT_steps}, !Number of MD-steps to be performed. Default 1.
  dt={delta_t}, !The time step (psec). Recommended MAXIMUM is .002 if SHAKE is used, or .001 if SHAKE is NOT used
  cut={cutoff}, !Cut Off Distance for Non-Bounded Interactions
  igb=0, !No Generalized Born
  ntp=1, !MD with isotropic position scaling
  ntb=2, !Constant Pressure. (default when ntp > 0)
  ntf=2, !Bond Interactions involving H-atoms omitted
  ntc=2, !Bonds involving Hydrogen are Constrained
  ntpr={equi_NPT_ener_steps}, !Every {equi_NPT_ener_steps} steps, energy information will be printed in human-readable form to files "mdout" and "mdinfo"
  ntwx={equi_NPT_traj_steps}, !Every {equi_NPT_traj_steps} steps, the coordinates will be written to the mdcrd file
  ntwr={equi_NPT_restart_steps}, !Every {equi_NPT_restart_steps} steps during dynamics, the restart file will be written, ensuring that recovery from a crash will not be so painful. #If ntwr < 0, a unique copy of the file, "restrt_<nstep>", is written every abs(ntwr) steps
  ntt=3, !Use Langevin Dynamics with the Collision Frequency GAMA given by gamma_ln,
  gamma_ln=2.00000, !Collision Frequency, ps ^ (-1)
  temp0=310.00000, !Reference temperature at which the system is to be kept
  tempi=310.00000, !Initial Temperature
  pres0=1.01300, !Reference Pressure (in units of bars, where 1 bar = 0.987 atm) at which the system is maintained
  ntr=1, !Turn ON (Cartesian) Restraints
/
Hold Residues with B-factor_more_than_70
{equiNPT_resf_70up}
FIND
CA * * *
P * * *
C2 * * *
C4' * * *
SEARCH
{high_res_txt}
END
Hold Residues with B-factor_less_than_70
{equiNPT_resf_70below}
FIND
CA * * *
P * * *
C2 * * *
C4' * * *
SEARCH
{low_res_txt}
END
END
""")

# Production Run
with open(f"{folder}/md_NPT.in", "w") as file:
    file.write(
f"""#Type of Simulation Being Done: Production Run,
 &cntrl
  ntxo=2, IOUTFM=1, !NetCDF Binary Format.
  imin=0, !MD Simulation
  irest=1, !Continue the simulation;
  ig=-1, !Pseudo-random number seed is changed with every run.
  ntx=5, !Coordinates and Velocities will be read; a formatted (ASCII) coordinate file is expected.
  nstlim={md_NPT_steps}, !Number of MD-steps to be performed. Default 1.
  dt={delta_t}, !The time step (psec). Recommended MAXIMUM is .002 if SHAKE is used, or .001 if SHAKE is NOT used
  cut={cutoff}, !Cut Off Distance for Non-Bounded Interactions
  igb=0, !No Generalized Born
  ntp=1, !MD with isotropic position scaling
  ntb=2, !Constant Pressure. (default when ntp > 0)
  ntf=2, !Bond Interactions involving H-atoms omitted
  ntc=2, !Bonds involving Hydrogen are Constrained
  ntpr={md_NPT_ener_steps}, !Every {md_NPT_ener_steps} steps, energy information will be printed in human-readable form to files "mdout" and "mdinfo"
  ntwx={md_NPT_traj_steps}, !Every {md_NPT_traj_steps} steps, the coordinates will be written to the mdcrd file
  ntwr={md_NPT_restart_steps}, !Every {md_NPT_restart_steps} steps during dynamics, the restart file will be written, ensuring that recovery from a crash will not be so painful. #If ntwr < 0, a unique copy of the file, "restrt_<nstep>", is written every abs(ntwr) steps
  ntt=3, !Use Langevin Dynamics with the Collision Frequency GAMA given by gamma_ln,
  gamma_ln=2.00000, !Collision Frequency, ps ^ (-1)
  temp0=310.00000, !Reference temperature at which the system is to be kept
  tempi=310.00000, !Initial Temperature
  pres0=1.01300, !Reference Pressure (in units of bars, where 1 bar = 0.987 atm) at which the system is maintained
  barostat=2, !Monte Carlo Barostat
/
 """)