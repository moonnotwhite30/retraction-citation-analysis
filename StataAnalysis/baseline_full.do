// baseline_full.do — 1:1 DOM + 完整控制变量 (3.28 设定)
// 数据: panel_1to1_full.csv

clear
set more off

import delimited "/Data4/yutao_wen/processed/panel_1to1_full.csv", clear
di "Total rows: " _N

// 预处理
replace yearlycitation = 0 if missing(yearlycitation)
replace log_yearlycitation = ln(1 + yearlycitation) if missing(log_yearlycitation)

rename group_val group
rename log_yearlycitation log_cites
rename yearlycitation cites

// paper FE ID
egen paper_numid = group(exp_id ctrl_id)

// 标签
label var log_cites "ln(1+cites)"
label var did      "DID"
label var pd       "Pre-retraction"
label var f_numa   "No. authors (focal)"
label var f_numr   "No. references (focal)"
label var selfretra "Self-retracted focal"
label var pre_cites_total "Pre-retraction total cites"

// ================================================
// Table 1: Descriptive (全变量)
// ================================================
di ""
di "=== TABLE 1: DESCRIPTIVE ==="
summarize log_cites did pd age f_numa f_numr selfretra pre_cites_total ///
    log_numa log_numr log_pre_cites author_year ref_year sef_year

di ""
di "--- By Group ---"
bysort group: summarize log_cites did pd age f_numa f_numr selfretra pre_cites_total

// ================================================
// Table 2: 基准回归 (完全复刻 3.28.do)
// ================================================
di ""
di "=== TABLE 2: BASELINE DID ==="

// M1: OLS no controls
reg log_cites did
est sto m1
estadd local paper_fe "No"; estadd local year_fe "No"

// M2: TWFE no controls
reghdfe log_cites did, absorb(paper_numid year age) cluster(paper_numid)
est sto m2
estadd local paper_fe "Yes"; estadd local year_fe "Yes"

// M3: TWFE + basic controls (3.28 style)
reghdfe log_cites did author_year ref_year sef_year, ///
    absorb(paper_numid year age) cluster(paper_numid)
est sto m3
estadd local paper_fe "Yes"; estadd local year_fe "Yes"

// M4: TWFE + full controls
reghdfe log_cites did author_year ref_year sef_year ///
    log_numa log_numr log_pre_cites pre_cites_total, ///
    absorb(paper_numid year age) cluster(paper_numid)
est sto m4
estadd local paper_fe "Yes"; estadd local year_fe "Yes"

// Output
esttab m1 m2 m3 m4 ///
    using "/home/wenyutao/retraction_analysis2/StataAnalysis/Table_Full_Controls.csv", ///
    replace b(%9.3f) t(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    drop(*.author_year *.ref_year *.sef_year *.log_numa *.log_numr *.log_pre_cites *.pre_cites_total _cons) ///
    scalars("paper_fe Paper_FE" "year_fe Year_FE") ///
    mtitle("OLS" "TWFE" "+3.28Ctrls" "+Full") ///
    title("Baseline DID — 1:1 DOM with Full Controls") ///
    addnotes("Paper FE + Year FE + Age FE. SE clustered at paper level." ///
             "3.28 controls: author_year, ref_year, sef_year." ///
             "Full controls: + log_numa, log_numr, log_pre_cites, pre_cites_total.")

di ""
di "=== DONE ==="
