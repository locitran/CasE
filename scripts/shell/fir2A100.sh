#!/bin/bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <fir_folder> <a100_folder> [a100_host]" >&2
  echo "Example: $0 /home/locitran/scratch/CasE/data/fir/CasE_14_P2V1 /mnt/nas_1/YangLab/loci/casE/data/fir" >&2
  exit 1
fi

fir_folder=$1
a100_folder=$2
a100_host=${3:-yang_loci@140.114.97.192}

if [[ ! -d "$fir_folder" ]]; then
  echo "ERROR: FIR folder does not exist: $fir_folder" >&2
  exit 1
fi

parent_dir=$(cd "$(dirname "$fir_folder")" && pwd)
folder_name=$(basename "$fir_folder")
archive="${parent_dir}/${folder_name}.tar.gz"

echo "Compressing $fir_folder"
tar -C "$parent_dir" -czf "$archive" "$folder_name"

echo "Creating remote folder: $a100_host:$a100_folder"
ssh "$a100_host" "mkdir -p '$a100_folder'"

echo "Transferring $archive to $a100_host:$a100_folder/"
scp "$archive" "$a100_host:$a100_folder/"

echo "Extracting on A100"
ssh "$a100_host" "cd '$a100_folder' && tar -xzf '${folder_name}.tar.gz'"

echo "Transfer complete"
echo "Remote folder: $a100_host:$a100_folder/$folder_name"
echo "Local archive kept at: $archive"
