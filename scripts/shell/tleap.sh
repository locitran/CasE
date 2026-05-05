#!/bin/bash

get_water_numbers() {
  local leap_file=$1
  awk '/Added [0-9]+ residues\./ {print $2; exit}' "$leap_file"
}

echo "Starting tleap prepare run at $(date)"
start=$(date +%s)  # Record start time in minutes

if [[ -s "$topfile" && -s "$coordfile" && -s "$output_pdb" ]]; then
    echo "Found existing tleap outputs; skipping tleap preparation"
    echo "  topfile: $topfile"
    echo "  coordfile: $coordfile"
    echo "  output_pdb: $output_pdb"
    end=$(date +%s)
    elapsed=$((end - start))
    report_elapsed "tleap" "$elapsed"
    return 0
fi

# 1/ Get number of water molecules
cat > $tleap/count_water.in <<EOF
source leaprc.protein.ff14SB
source leaprc.water.tip3p
protein = loadpdb $outdir/noh_propka.pdb
solvatebox protein TIP3PBOX 10 iso
quit
EOF
################################################
run_container tleap -f $tleap/count_water.in
mv leap.log $tleap/count_water.log
read -r water_num < <(get_water_numbers $tleap/count_water.log)

# 2/ Calculate number of ions to obtain 0.15 nM NaCl
# n_ions=0.15*$water_num/(1000/18.08)
n_ions=$(printf "%.0f\n" "$(echo "0.15 * $water_num / (1000 / 18.08)" | bc -l)")

# 3/ Add ions to achieve 0.15M Salt Concentration 
cat > $tleap/build_system.in <<EOF
source leaprc.protein.ff14SB
source leaprc.water.tip3p
protein = loadpdb $outdir/noh_propka.pdb
EOF

# 5/ Detect disulfide bond 
sslink_file=$outdir/noh_sslink
while read -r res1 res2; do
  [[ -z "$res1" || -z "$res2" ]] && continue
  echo "bond protein.${res1}.SG protein.${res2}.SG" >> $tleap/build_system.in
done < $sslink_file

cat >> $tleap/build_system.in <<EOF
solvatebox protein TIP3PBOX 10 iso
charge protein
addIons protein Na+ 0
addIons protein Cl- 0
addIons protein Na+ ${n_ions} Cl- ${n_ions}
charge protein
saveamberparm protein ${topfile} ${coordfile}
savepdb protein ${output_pdb}
quit
EOF
################################################
run_container tleap -f $tleap/build_system.in
mv leap.log $tleap/build_system.log


end=$(date +%s)  # Record end time in minutes
elapsed=$((end - start))  # Compute total time

echo "tleap run completed at $(date)"
report_elapsed "tleap" "$elapsed"
