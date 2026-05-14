// baseline_328style.do — 完全复刻 3.28.do 的回归设定
// 数据: panel_1to1.csv (1:1 DOM matching)

clear
set more off

import delimited "/Data4/yutao_wen/processed/panel_1to1.csv", clear
di "Total rows: " _N

// === 变量预处理 (与 3.28.do 完全一致) ===
replace yearlycitation = 0 if missing(yearlycitation)
replace log_yearlycitation = ln(1 + yearlycitation) if missing(log_yearlycitation)
gen age = year - pyear

rename group_val group
rename log_yearlycitation log_cites

// paper_numid: 每篇 paper 一个唯一 ID (与 3.28 一致)
egen paper_numid = group(exp_id ctrl_id)

label var log_cites "ln(1 + yearly citations)"
label var did      "DID term"

// === 模型设定 (完全复刻 3.28.do) ===

// (1) 普通 OLS, 无控制变量
di ""
di "=== M1: OLS, no controls ==="
reg log_cites did
est sto OLS_NoCon
estadd local paper_fe "No"
estadd local year_fe  "No"

// (2) 普通 OLS, 控制变量 (用 pd 替代 author_year/ref_year)
di ""
di "=== M2: OLS, with pd ==="
reg log_cites did pd
est sto OLS_YesCon
estadd local paper_fe "No"
estadd local year_fe  "No"

// (3) TWFE, 无控制变量
di ""
di "=== M3: TWFE, no controls ==="
reghdfe log_cites did, absorb(paper_numid year age) cluster(paper_numid)
est sto FE_age_NoCon
estadd local paper_fe "Yes"
estadd local year_fe  "Yes"
estadd local age_fe   "Yes"

// (4) TWFE, 控制变量
di ""
di "=== M4: TWFE, with pd ==="
reghdfe log_cites did pd, absorb(paper_numid year age) cluster(paper_numid)
est sto FE_age_YesCon
estadd local paper_fe "Yes"
estadd local year_fe  "Yes"
estadd local age_fe   "Yes"

// Output
esttab OLS_NoCon OLS_YesCon FE_age_NoCon FE_age_YesCon ///
    using "/home/wenyutao/retraction_analysis2/StataAnalysis/Table_328style.csv", ///
    replace b(%9.3f) t(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    drop(pd _cons) ///
    scalars("paper_fe Paper_FE" "year_fe Year_FE" "age_fe Age_FE") ///
    mtitle("OLS" "OLS+pd" "TWFE" "TWFE+pd") ///
    title("Baseline DID — 3.28.do Specification (1:1 DOM)") ///
    addnotes("Paper FE + Year FE + Age FE. SE clustered at paper level.")

di ""
di "=== DONE ==="
