// baseline_1to1.do — 1:1 匹配基准 DID 回归
// 数据: panel_1to1.csv (148,920 focals, 2.9M rows)

clear
set more off

import delimited "/Data4/yutao_wen/processed/panel_1to1.csv", clear
di "Total rows: " _N

// 预处理
replace yearlycitation = 0 if missing(yearlycitation)
replace log_yearlycitation = ln(1 + yearlycitation) if missing(log_yearlycitation)

rename group_val group
rename log_yearlycitation log_cites
rename yearlycitation cites
rename dom_dist dom_d

label var group   "Treatment (1=focal, 0=candidate)"
label var log_cites "ln(1+cites)"
label var did     "DID"
label var dom_d   "DOM distance"

// Panel ID: pair = (exp_id, ctrl_id)
egen panel_id = group(exp_id ctrl_id)

// Table 1: Descriptive
di ""
di "=== TABLE 1: DESCRIPTIVE ==="
summarize log_cites did dom_d
bysort group: summarize log_cites did dom_d

count if group == 1
local n1 = r(N)
count if group == 0
local n0 = r(N)
di "Treatment rows: " %15.0gc `n1'
di "Control rows:  " %15.0gc `n0'

// Table 2: DID regression
di ""
di "=== TABLE 2: BASELINE DID ==="

// M1: DID only
reghdfe log_cites did, absorb(panel_id year) cluster(exp_id)
est store m1
estadd local pair_fe "Y"; estadd local year_fe "Y"

// M2: DID + age
reghdfe log_cites did pd, absorb(panel_id year) cluster(exp_id)
est store m2
estadd local pair_fe "Y"; estadd local year_fe "Y"

// M3: DID + interactions with pd
gen did_pd = did * pd
reghdfe log_cites did did_pd pd, absorb(panel_id year) cluster(exp_id)
est store m3
estadd local pair_fe "Y"; estadd local year_fe "Y"

// Output
esttab m1 m2 m3 ///
    using "/home/wenyutao/retraction_analysis2/StataAnalysis/Table_Baseline_1to1.csv", ///
    replace b(%9.3f) t(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    drop(pd did_pd _cons) ///
    scalars("pair_fe Pair_FE" "year_fe Year_FE") ///
    mtitle("DID only" "+pd" "+DIDxpd") ///
    title("Baseline DID: 1:1 DOM Matching") ///
    addnotes("Pair FE + Year FE. SE clustered at focal level.")

di ""
di "=== DONE ==="
