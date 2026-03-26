* Replicate formatted Opportunity Atlas mobility figures in Stata
* Usage:
*   cd "/Users/jfogel/workforce_notes/oi-ai-demo"
*   do src/make_figures_stata.do

version 17.0
clear all
set more off
set graphics off

local root "/Users/jfogel/workforce_notes/oi-ai-demo"
local input_csv "`root'/data/tract_outcomes/tract_outcomes_selected.csv"
local outdir "`root'/figures"
capture mkdir "`root'/figures"
capture mkdir "`outdir'"

tempfile base

import delimited using "`input_csv'", varnames(1) clear
keep state kfr_pooled_pooled_p25 kfr_pooled_pooled_p75 ///
     kfr_white_pooled_p25 kfr_black_pooled_p25 ///
     kid_pooled_pooled_blw_p50_n kid_white_pooled_blw_p50_n kid_black_pooled_blw_p50_n

* Exclude territories: AS, GU, MP, PR, VI.
drop if inlist(state, 60, 66, 69, 72, 78)
save `base', replace

********************************************************************************
* Poor vs Rich
********************************************************************************
use `base', clear
keep if !missing(kfr_pooled_pooled_p25, kfr_pooled_pooled_p75, kid_pooled_pooled_blw_p50_n)
keep if kid_pooled_pooled_blw_p50_n > 0

gen x = kfr_pooled_pooled_p25
gen y = kfr_pooled_pooled_p75
gen w = kid_pooled_pooled_blw_p50_n

quietly corr x y [aw=w]
matrix C = r(C)
scalar r_pr = C[1,2]
local rprtxt : display %5.3f r_pr

quietly summarize x, detail
scalar xlo = max(0, r(p1))
scalar xhi = min(1, r(p99))
quietly summarize y, detail
scalar ylo = max(0, r(p1))
scalar yhi = min(1, r(p99))

set scheme s2color
preserve
sample 5000, count
twoway ///
    (scatter y x, mcolor("37 163 145%10") msymbol(o) msize(vtiny)) ///
    (lfit y x, lcolor("37 163 145") lwidth(medthick)), ///
    title("Poor vs Rich Mobility", color("37 163 145") size(large)) ///
    subtitle("Raw scatter", color(black) size(medsmall)) ///
    xtitle("Mean rank for children from p25 parents", size(medlarge)) ///
    ytitle("Mean rank for children from p75 parents", size(medlarge)) ///
    text(`=yhi - 0.03*(yhi-ylo)' `=xlo + 0.02*(xhi-xlo)' "Weighted r = `rprtxt'", ///
         place(e) size(medsmall) color(black)) ///
    graphregion(color("236 236 236")) plotregion(color("236 236 236")) ///
    xlabel(, labsize(medlarge) nogrid) ylabel(, labsize(medlarge) nogrid) ///
    xscale(range(`=xlo' `=xhi')) yscale(range(`=ylo' `=yhi')) ///
    legend(off)
graph export "`outdir'/poor_rich_raw_stata.pdf", replace
restore

sort x
gen cw = sum(w)
quietly summarize w
scalar tw = r(sum)
gen bin = ceil(20 * cw / tw)
replace bin = 20 if bin > 20

* Rebuild weighted means by bin
use `base', clear
keep if !missing(kfr_pooled_pooled_p25, kfr_pooled_pooled_p75, kid_pooled_pooled_blw_p50_n)
keep if kid_pooled_pooled_blw_p50_n > 0
gen x = kfr_pooled_pooled_p25
gen y = kfr_pooled_pooled_p75
gen w = kid_pooled_pooled_blw_p50_n
sort x
gen cw = sum(w)
quietly summarize w
scalar tw = r(sum)
gen bin = ceil(20 * cw / tw)
replace bin = 20 if bin > 20
gen wx = x*w
gen wy = y*w
collapse (sum) wx wy w, by(bin)
gen xb = wx/w
gen yb = wy/w

twoway ///
    (line yb xb, lcolor("37 163 145") lwidth(medthick)) ///
    (scatter yb xb, mcolor("37 163 145") msymbol(O) msize(medsmall)), ///
    title("Poor vs Rich Mobility", color("37 163 145") size(large)) ///
    subtitle("Binned scatter (20 weighted quantile bins)", color(black) size(medsmall)) ///
    xtitle("Mean rank for children from p25 parents", size(medlarge)) ///
    ytitle("Mean rank for children from p75 parents", size(medlarge)) ///
    text(`=yhi - 0.03*(yhi-ylo)' `=xlo + 0.02*(xhi-xlo)' "Weighted r = `rprtxt'", ///
         place(e) size(medsmall) color(black)) ///
    graphregion(color("236 236 236")) plotregion(color("236 236 236")) ///
    xlabel(, labsize(medlarge) nogrid) ylabel(, labsize(medlarge) nogrid) ///
    xscale(range(`=xlo' `=xhi')) yscale(range(`=ylo' `=yhi')) ///
    legend(off)
graph export "`outdir'/poor_rich_bins_stata.pdf", replace

********************************************************************************
* White vs Black
********************************************************************************
use `base', clear
keep if !missing(kfr_white_pooled_p25, kfr_black_pooled_p25, kid_white_pooled_blw_p50_n, kid_black_pooled_blw_p50_n)
gen weight_sum = kid_white_pooled_blw_p50_n + kid_black_pooled_blw_p50_n
keep if weight_sum > 0

gen x = kfr_white_pooled_p25
gen y = kfr_black_pooled_p25
gen w = weight_sum

quietly corr x y [aw=w]
matrix C = r(C)
scalar r_wb = C[1,2]
local rwbtxt : display %5.3f r_wb

quietly summarize x, detail
scalar xlo = max(0, r(p1))
scalar xhi = min(1, r(p99))
quietly summarize y, detail
scalar ylo = max(0, r(p1))
scalar yhi = min(1, r(p99))

preserve
sample 5000, count
twoway ///
    (scatter y x, mcolor("226 145 45%10") msymbol(o) msize(vtiny)) ///
    (lfit y x, lcolor("226 145 45") lwidth(medthick)), ///
    title("White vs Black Mobility (p25)", color("226 145 45") size(large)) ///
    subtitle("Raw scatter", color(black) size(medsmall)) ///
    xtitle("Mean rank for white children", size(medlarge)) ///
    ytitle("Mean rank for Black children", size(medlarge)) ///
    text(`=yhi - 0.03*(yhi-ylo)' `=xlo + 0.02*(xhi-xlo)' "Weighted r = `rwbtxt'", ///
         place(e) size(medsmall) color(black)) ///
    graphregion(color("236 236 236")) plotregion(color("236 236 236")) ///
    xlabel(, labsize(medlarge) nogrid) ylabel(, labsize(medlarge) nogrid) ///
    xscale(range(`=xlo' `=xhi')) yscale(range(`=ylo' `=yhi')) ///
    legend(off)
graph export "`outdir'/white_black_raw_stata.pdf", replace
restore

sort x
gen cw = sum(w)
quietly summarize w
scalar tw = r(sum)
gen bin = ceil(20 * cw / tw)
replace bin = 20 if bin > 20
gen wx = x*w
gen wy = y*w
collapse (sum) wx wy w, by(bin)
gen xb = wx/w
gen yb = wy/w

twoway ///
    (line yb xb, lcolor("226 145 45") lwidth(medthick)) ///
    (scatter yb xb, mcolor("226 145 45") msymbol(O) msize(medsmall)), ///
    title("White vs Black Mobility (p25)", color("226 145 45") size(large)) ///
    subtitle("Binned scatter (20 weighted quantile bins)", color(black) size(medsmall)) ///
    xtitle("Mean rank for white children", size(medlarge)) ///
    ytitle("Mean rank for Black children", size(medlarge)) ///
    text(`=yhi - 0.03*(yhi-ylo)' `=xlo + 0.02*(xhi-xlo)' "Weighted r = `rwbtxt'", ///
         place(e) size(medsmall) color(black)) ///
    graphregion(color("236 236 236")) plotregion(color("236 236 236")) ///
    xlabel(, labsize(medlarge) nogrid) ylabel(, labsize(medlarge) nogrid) ///
    xscale(range(`=xlo' `=xhi')) yscale(range(`=ylo' `=yhi')) ///
    legend(off)
graph export "`outdir'/white_black_bins_stata.pdf", replace

display "Done. Stata figures in `outdir'"
