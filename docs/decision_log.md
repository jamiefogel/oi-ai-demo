# Decision Log

Fill this as we go before final plotting.

## Locked choices (current defaults)

1. Geography: Census tracts
2. Outcome: Income rank at age 35 (`kfr_*`)
3. Comparison A: `p25` vs `p75` (pooled)
4. Comparison B: White vs Black at `p25`
5. Missing/suppressed: Drop missing/suppressed values
6. Minimum denominator: keep rows with weight `> 0`
7. Bins: 20 weighted quantile bins
8. Axes: fixed `[0, 1]` for x and y in all panels
9. Geography filter: exclude territories, keep 50 states + DC

## Weight options (from tract_outcomes_early.csv)

1. Weights for poor-rich:
   - Option A: `kid_pooled_pooled_blw_p50_n` (selected)
   - Option B: `kid_pooled_pooled_n`
   - Option C: unweighted
2. Weights for white-black:
   - Option A: `kid_white_pooled_blw_p50_n + kid_black_pooled_blw_p50_n` (selected)
   - Option B: `kid_white_pooled_n + kid_black_pooled_n`
   - Option C: unweighted

## Notes

- There are no `kid_*p25*` weight fields in `tract_outcomes_early.csv`, so p25-specific weights are not available in this file.

## Audit notes

- Finalized on 2026-03-26.
