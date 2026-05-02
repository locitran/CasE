import os 
import sys

heat_in = str(sys.argv[1])
heating_in = str(sys.argv[2])

total_time = 10 # ns
dt = 0.00200 # ps

init_step = 0
total_step = 10**3 * total_time / dt # --> 500,000 steps
print(f"Total step: {total_step}")

temp_inc  = 5 # K
init_temp = 50.0 # K
norm_temp = 310.0 # K 
max_temp  = 320.0 # K

# First loop (heating from 50 → 320 by 5 K):
# 	•	Temps used: 50 → 55 → 60 → … → 315 → 320
# 	•	That’s 50, 55, …, 315 → 54 segments
# Second loop (cooling 320 → 310 by 5 K):
# 	•	320 → 315
# 	•	315 → 310
# 	•	2 segments
n_segments = 56
step_inc = int(total_step // 56)

tempfile = "tempfile"
with open(tempfile, 'w') as f:
    while (init_temp < 320.0):
        f.writelines("&wt type='TEMP0', istep1=" + str(init_step) + ", istep2=" + str(init_step+step_inc) + ", value1=" + str(init_temp) + ", value2=" + str(init_temp+5) +", /" + "\n")
        init_step = init_step + step_inc
        init_temp = init_temp + 5

    while (max_temp > 310.0):
        if max_temp == 310.0:
            f.writelines("&wt type='TEMP0', istep1=" + str(init_step) + ", istep2=" + str(total_step) + ", value1=" + str(norm_temp) + ", value2=" + str(norm_temp) +", /" + "\n")
        else:
            f.writelines("&wt type='TEMP0', istep1=" + str(init_step) + ", istep2=" + str(init_step+step_inc) + ", value1=" + str(max_temp) + ", value2=" + str(max_temp-5) +", /" + "\n")
            init_step = init_step + step_inc
            max_temp = max_temp - 5
    f.writelines("&wt type='END' /")

#merge the heating input file and the step by step temp increment
merge_file = f"cat {heat_in} {tempfile} > {heating_in}"
os.system(merge_file)
os.remove(tempfile)