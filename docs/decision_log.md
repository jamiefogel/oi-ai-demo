# Decision Log

Fill this as we go before final plotting.

## Locked choices (current defaults)

1. Geography: Census tracts
2. Outcome: Income rank at age 35 (`kfr_*`)
3. Comparison A: `p25` vs `p75` (pooled)
4. Comparison B: White vs Black at `p25`
5. Missing/suppressed: Drop missing/suppressed values

## Pending decisions for confirmation

1. Weights for poor-rich:
   - Option A: `kid_pooled_pooled_blw_p50_n` (recommended)
   - Option B: unweighted
2. Weights for white-black:
   - Option A: `kid_white_pooled_blw_p50_n + kid_black_pooled_blw_p50_n` (recommended)
   - Option B: unweighted
3. Minimum denominator threshold:
   - Option A: `> 0` only (recommended)
   - Option B: stricter cutoff (e.g., `>= 20`)
4. Binning:
   - Option A: 20 weighted quantile bins (recommended)
   - Option B: alternative count
5. Geographic sample:
   - Option A: all U.S. tracts (recommended)
   - Option B: contiguous U.S. only / exclude territories
6. Axis scaling:
   - Option A: fixed `[0,1]` on both axes (recommended)
   - Option B: data-driven limits

## Audit notes

- Record final selected options and date here.
