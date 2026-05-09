# Install miniconda in FIR

```bash
cd ~/scratch
bash Miniconda3-latest-Linux-x86_64.sh -b -p ~/scratch/miniconda3
source ~/scratch/miniconda3/etc/profile.d/conda.sh
conda --version
conda create -n case python=3.11 -y
conda activate case
pip install -r ~/scratch/CasE/requirements.txt
```

# Alternative: use Python venv in FIR

If you do not want to use conda, create a regular Python virtual environment:

```bash
cd ~/scratch/CasE
python -m venv ~/scratch/case-venv
source ~/scratch/case-venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Then activate it in the Slurm script before running Python scripts:

```bash
source ~/scratch/case-venv/bin/activate
which python
python --version
which propka3
```

# Monitor job

```bash
squeue -u $USER
tail -f case_wt_md-<jobid>.out
tail -f case_wt_md-<jobid>.err
```

# Copy data to FIR with scp

If SSH reports `Host key verification failed`, first verify and add the remote host key:

```bash
ssh-keyscan -t ed25519 140.114.97.192
ssh-keygen -lf <(ssh-keyscan -t ed25519 140.114.97.192 2>/dev/null)
ssh-keyscan -t ed25519 140.114.97.192 >> ~/.ssh/known_hosts
```

After confirming the fingerprint is correct, copy from the repo root:

```bash
cd ~/scratch/CasE
scp -r yang_loci@140.114.97.192:/mnt/nas_1/YangLab/loci/casE/data/output/CasE_14_P2V1 ./data/output/
```

If you are already inside `~/scratch/CasE/data`, use:

```bash
scp -r yang_loci@140.114.97.192:/mnt/nas_1/YangLab/loci/casE/data/output/CasE_14_P2V1 ./output/
```

# Copy data from FIR to A100 with scp

Run this on FIR to copy `CasE_14_P2V1` back to the A100 repo:

```bash
scp -r /home/locitran/scratch/CasE/data/fir/CasE_14_P2V1 \
  yang_loci@140.114.97.192:/mnt/nas_1/YangLab/loci/casE/data/fir/
```

# 2 tasks
# 4 cpus / task --> 8 cpus

#SBATCH --ntasks=8                          # MPI tasks
#SBATCH --cpus-per-task=4                  # CPUs per task
