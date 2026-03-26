# Analysis Plan: Opportunity Atlas Mobility Correlations

## Goal

Create two figures (each with two panels: raw scatter and binned scatter) that compare tract-level mobility estimates across groups.

- Figure 1: `kfr_pooled_pooled_p25` vs `kfr_pooled_pooled_p75`
- Figure 2: `kfr_white_pooled_p25` vs `kfr_black_pooled_p25`

Each panel should print the correlation coefficient directly on the plot.

## Phase 1: Data setup

1. Download `tract_outcomes.zip` from Opportunity Atlas public data.
2. Unzip and load `tract_outcomes_early.csv`.
3. Keep only columns needed for IDs, outcomes, and weights.

## Phase 2: Decision lock before estimation

Before plotting, lock:

1. Geography scope (all tracts vs subset)
2. Weighting choice for correlations and binned means
3. Missing/suppressed-value rule
4. Minimum sample-size threshold
5. Bin count and binning method
6. Axis ranges and any trimming/winsorization

## Phase 3: Build analysis datasets

1. Poor-rich sample:
   - Keep rows with non-missing `p25`, `p75`, and weight.
2. White-Black sample:
   - Keep rows with non-missing white and Black `p25` outcomes and both weights.
3. Construct comparison-specific weight variables based on locked decisions.

## Phase 4: Estimation and plotting

1. Compute correlation on tract-level rows (weighted or unweighted per decision log).
2. Produce raw scatter plots.
3. Produce binned scatter plots using weighted quantile bins if weighted.
4. Annotate each plot with `r = ...`.
5. Save four plots under `figures/`.

## Phase 5: LaTeX output

1. Build one LaTeX file in `latex/` with:
   - Figure 1 (raw + binned)
   - Figure 2 (raw + binned)
2. Include short caption text with sample/weight definitions.
3. Compile to PDF.

## Deliverables

1. `figures/poor_rich_raw.pdf`
2. `figures/poor_rich_bins.pdf`
3. `figures/white_black_raw.pdf`
4. `figures/white_black_bins.pdf`
5. `latex/atlas_mobility_figures.tex`
6. `latex/atlas_mobility_figures.pdf`
