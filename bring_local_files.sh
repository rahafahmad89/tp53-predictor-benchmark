#!/bin/bash
# Run ONCE in WSL, from the repository root, to copy the files that only exist on your computer:
#   bash bring_local_files.sh
set -e
SRC="$HOME/tp53/data benchmarking"
MD="$HOME/tp53/MD_sim"
ok(){ echo "  copied  $1"; }
miss(){ echo "  MISSING $1"; }

echo "Processed datasets with the added scores (BayesDel, PolyPhen-2):"
for f in germline_benchmark_final_v2.csv somatic_benchmark_final_confident_v2.csv; do
  [ -f "$SRC/$f" ] && cp "$SRC/$f" data/ && ok "$f" || miss "$f"
done
echo "Annotation provenance:"
for f in polyphen_raw.json vep_revision_versions.txt polyphen_version.txt polyphen_myvariant.csv; do
  [ -f "$SRC/$f" ] && cp "$SRC/$f" data/annotation/ && ok "$f" || miss "$f"
done
echo "Molecular dynamics inputs (parameters, topologies, equilibrated structures):"
mkdir -p data/md/inputs/mdp
cp "$MD"/mdp/*.mdp data/md/inputs/mdp/ 2>/dev/null && ok "mdp/*.mdp" || miss "MD_sim/mdp/*.mdp"
cp "$MD"/transfer/prod*.mdp data/md/inputs/mdp/ 2>/dev/null && ok "transfer/prod*.mdp" || miss "transfer/prod*.mdp"
for s in WT R110L G262S; do
  mkdir -p data/md/inputs/$s
  cp "$MD"/transfer/$s/*.top "$MD"/transfer/$s/*.itp "$MD"/transfer/$s/*.gro data/md/inputs/$s/ 2>/dev/null \
    && ok "transfer/$s (top, itp, gro)" || miss "transfer/$s"
done
echo
echo "Largest files now in the repository (GitHub rejects files over 100 MB):"
find . -path ./.git -prune -o -type f -size +20M -print
echo "Done."
