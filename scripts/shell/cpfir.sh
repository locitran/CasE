#!/bin/bash
set -euo pipefail

workdir=${1:-/mnt/nas_1/YangLab/loci/casE}

for variant in CasE_14_P2V1 CasE_14_P2V2 CasE_14_P2V3 CasE_14_P2V4 CasE_14_P2V5; do
  for type in wt mut; do
    src="$workdir/data/output/$variant/$type/${type}_model.cif"
    dst_dir="$workdir/data/fir/$variant/$type"
    dst="$dst_dir/${type}_model.cif"

    if [[ ! -s "$src" ]]; then
      echo "Warning: missing source CIF, skipping: $src" >&2
      continue
    fi

    mkdir -p "$dst_dir"
    cp "$src" "$dst"
    echo "Copied $src -> $dst"
  done
done

# bash /mnt/nas_1/YangLab/loci/casE/scripts/shell/cpfir.sh /mnt/nas_1/YangLab/loci/casE
