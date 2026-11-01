# tp53-predictor-benchmark

Code, processed data and results for:

> Ahmad RM, Ali BR, Al Dhaheri N. **Cross-dataset recalibration and exploratory structural analysis of discordant TP53 missense variant predictions.** (submitted)

We benchmark 15 missense pathogenicity predictors (SIFT, REVEL, CADD, ClinPred, MetaLR, MetaRNN, MetaSVM, MVP, PROVEAN, DANN, PolyPhen-2 HumDiv and HumVar, BayesDel, AlphaMissense, EVE) on a germline TP53 dataset (n = 390; ClinVar / ClinGen TP53 VCEP) and a somatic dataset (n = 117; ClinVar oncogenicity), recalibrate their thresholds, test performance inside and outside the DNA-binding domain, and run exploratory molecular dynamics for two discordant variants (p.Arg110Leu, p.Gly262Ser).

## Repository layout

| Folder | Contents |
|---|---|
| `data/` | Processed benchmark datasets (one row per variant: predictor scores, reference label) |
| `data/annotation/` | VEP input lists, Ensembl/dbNSFP version records, PolyPhen-2 retrieval output |
| `data/md/qc_analysis/` | GROMACS `.xvg` outputs for 9 trajectories (RMSD, RMSF, Zn–ligand distances, temperature, energy) |
| `data/md/inputs/` | `.mdp` parameters, topologies and equilibrated structures used for production runs |
| `scripts/dataset_construction/` | How the two datasets were built from ClinVar, ClinGen ERepo and COSMIC CMC (needs raw downloads, see below) |
| `scripts/annotation/` | Code-based re-annotation: Ensembl VEP REST (BayesDel) and MyVariant.info (PolyPhen-2) |
| `scripts/benchmark/` | Analysis pipeline, steps 01–12 |
| `scripts/figures/` | Figures 1–4, Supplementary Figure 1 and all tables |
| `scripts/md/` | MD analysis (plateau test, residue-wise RMSF tests with BH correction, Zn distances) and Figure 5 |
| `results/` | Outputs as reported in the manuscript: tables (CSV), figures (PNG 600 dpi + PDF), run logs |

## Reproducing the results

```bash
git clone https://github.com/rahafahmad89/tp53-predictor-benchmark.git
cd tp53-predictor-benchmark
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
bash run_all.sh
```

`run_all.sh` copies the datasets into `work/`, runs steps 01–12, then rebuilds the figures, tables and MD analysis there. Compare `work/` with `results/`. Bootstrap and cross-validation use a fixed seed (20261030), so numbers reproduce exactly. A full run takes about 10–20 minutes on a laptop.

### Pipeline steps (`scripts/benchmark/`)

| Step | What it does | Main outputs |
|---|---|---|
| 01 | Missingness per tool and class | `missingness_report_*.csv` |
| 02 | Binary calls at published default thresholds | `*_classified.csv` |
| 03 | ROC-AUC, PR-AUC, sensitivity, specificity, MCC, … | `benchmark_summary_*.csv` |
| 04 | Pairwise discordance; DeLong tests with Benjamini–Hochberg correction | `discordance_matrix_*.csv`, `delong_pairwise_*.csv` |
| 05 | Youden and MCC-maximised thresholds per dataset | `suggested_thresholds_summary.csv` |
| 06 | Performance inside vs outside the DBD (residues 94–312) | `domain_stratified_*.csv` |
| 07 | Discordance ranking of candidate variants for MD | `md_candidates_*.csv` |
| 08 | Residue numbering check against PDB 1TUP | log |
| build_final_recommended_thresholds | Recommended thresholds table | `final_recommended_thresholds_v2.csv` |
| 09 | MetaSVM processing check | `metasvm_check_report.txt` |
| 10 | Bootstrap 95% CIs (2,000 resamples), optimism correction, 5×50 cross-validated thresholds | `table1_auc_ci.csv`, `table2_recalibration_ci.csv`, `table3_threshold_ci.csv` |
| 11 | ΔAUC DBD vs non-DBD: bootstrap CI and permutation test (5,000), BH-adjusted | `domain_delta_auc.csv`, `domain_stratified_ci.csv` |
| 12 | Discordance after recalibration and within the DBD | `discordance_decomposition_summary.csv`, `discordance_candidates_recalibrated.csv` |

### Re-annotation (`scripts/annotation/`, needs internet)

```bash
python3 scripts/annotation/vep_rest_revision.py      # BayesDel via Ensembl VEP REST (release 116, dbNSFP plugin)
python3 scripts/annotation/merge_new_vep_scores.py   # writes the *_v2.csv datasets
python3 scripts/annotation/add_polyphen.py           # PolyPhen-2 HDIV/HVAR from dbNSFP v4.8a via MyVariant.info
```

The original predictor scores were obtained with the Ensembl VEP web interface (GRCh38, transcript ENST00000269305.9 / NM_000546.6) with the dbNSFP plugin.

### Molecular dynamics

Systems: PDB 1TUP chain B, residues 97–289, wild type, R110L and G262S; AMBER99SB-ILDN, TIP3P, 0.15 M NaCl; Zn as a non-bonded ion with flat-bottom distance restraints; GROMACS 2023.4; 3 × 4 ns per system. Trajectories are not included because of their size; the analysed `.xvg` files are.

```bash
python3 scripts/md/md_analysis.py data/md/qc_analysis work/md
python3 scripts/md/make_figure5.py data/md/qc_analysis work/md --strip
```

## Data sources and licences

- ClinVar, ClinGen Evidence Repository and MaveDB data are public.
- The somatic variant pool was drawn in part from the COSMIC Cancer Mutation Census. COSMIC data are licence-restricted, so raw COSMIC files are **not** included; the scripts in `scripts/dataset_construction/` show how they were used. The final datasets contain no COSMIC-specific fields.
- Predictor scores come from dbNSFP (via Ensembl VEP and MyVariant.info); please respect each predictor's own licence.

## Citation

Please cite the article above (see `CITATION.cff`). Archived release: Zenodo DOI to be added.

## Contact

Rahaf M. Ahmad (700039113@uaeu.ac.ae); corresponding author: Noura Al Dhaheri (noura.aldhaheri@uaeu.ac.ae).
