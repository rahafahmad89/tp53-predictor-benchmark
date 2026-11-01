#!/bin/bash
# Re-runs the whole benchmark from the processed datasets in data/ and regenerates results/.
# Usage (from the repository root):  bash run_all.sh
set -e
ROOT=$(cd "$(dirname "$0")" && pwd)
WORK="$ROOT/work"; mkdir -p "$WORK"
for f in germline_benchmark_final.csv somatic_benchmark_final_confident.csv \
         germline_benchmark_final_v2.csv somatic_benchmark_final_confident_v2.csv; do
  [ -f "$ROOT/data/$f" ] || { echo "Missing data/$f"; exit 1; }
  cp "$ROOT/data/$f" "$WORK/"
done
cd "$WORK"
for s in 01_missingness_report 02_classify_variants 03_benchmark_metrics 04_pairwise_comparison \
         05_suggest_thresholds 06_domain_stratified_performance 07_md_candidate_selection \
         build_final_recommended_thresholds 09_metasvm_check 10_bootstrap_ci \
         11_domain_delta_auc 12_discordance_recalibrated; do
  echo "=================== $s"
  python3 "$ROOT/scripts/benchmark/$s.py" > "log_$s.txt" 2>&1 || { echo "FAILED: $s (see work/log_$s.txt)"; exit 1; }
  tail -2 "log_$s.txt"
done
echo "=================== figures and tables"
python3 "$ROOT/scripts/figures/make_figures.py" "$WORK" "$WORK/figures"
python3 "$ROOT/scripts/figures/make_tables.py" "$WORK" "$WORK/Tables.docx" "$WORK" "$ROOT/results/tables/supp_table4_additional_tools.csv"
echo "=================== molecular dynamics"
python3 "$ROOT/scripts/md/md_analysis.py" "$ROOT/data/md/qc_analysis" "$WORK/md"
python3 "$ROOT/scripts/md/make_figure5.py" "$ROOT/data/md/qc_analysis" "$WORK/md" --strip
echo "Done. New outputs are in work/; compare with results/."
