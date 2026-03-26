# oi-ai-demo

Opportunity Atlas demo project for tract-level mobility correlation plots:

1. Poor vs rich mobility (`p25` vs `p75`)
2. White vs Black mobility (both at `p25`)

This repo is structured to make key analysis decisions explicit before plotting.

## Project layout

- `docs/analysis_plan.md`: end-to-end implementation plan
- `docs/decision_log.md`: decision checklist and selections
- `src/`: analysis scripts
- `figures/`: generated plots
- `latex/`: LaTeX file for two figures with two panels each
- `data/`: local downloaded data (ignored by git except `.gitkeep`)

## Workflow

1. Finalize decisions in `docs/decision_log.md`
2. Download Opportunity Atlas file into `data/`
3. Run analysis script in `src/`
4. Generate figures in `figures/`
5. Compile LaTeX in `latex/`

## Commands

```bash
cd /Users/jfogel/workforce_notes/oi-ai-demo

# Download and unzip tract outcomes data
bash src/download_data.sh

# Build plots + LaTeX source
Rscript src/make_figures.R

# Compile PDF
cd latex && pdflatex atlas_mobility_figures.tex
```
