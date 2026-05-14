// =====================================================================
// baseline_reg.do — 描述性统计 + 基准 DID 回归
// 日期: 2026-05-14
// 前置: 先在 Python 中运行抽样 → panel_1to1.csv
// 抽样代码: 见 notebook 末尾 "Stata 抽样准备" cell
// =====================================================================

clear
set more off

// =====================================================================
// 1. 数据导入
// =====================================================================
di "=== 导入 10% 样本 ==="
import delimited "/Data4/yutao_wen/processed/panel_1to1.csv", clear
di "Total rows: " _N

// =====================================================================
// 2. 变量预处理
// =====================================================================
di "=== 变量预处理 ==="

// 确保完整
replace yearlycitation = 0 if missing(yearlycitation)
replace log_yearlycitation = ln(1 + yearlycitation) if missing(log_yearlycitation)

// 重命名 (Stata-friendly)
rename group_val group
rename journal_id jid
rename dom_distance dom_dist
rename pre_cites_total pre_cites
rename log_yearlycitation log_cites
rename yearlycitation cites

// Panel ID = pair (unique focal_id + paper_id combination)
// paper 可出现在多个 pair 中, 所以用 pair 而非 paper_id
egen panel_id = group(focal_id paper_id)
drop paper_numid pair

// 标签
label var group    "Treatment (1=focal, 0=candidate)"
label var year     "Calendar year"
label var cites    "Yearly citations"
label var log_cites "ln(1+cites)"
label var did      "DID (treated x post)"
label var dom_dist "DOM distance"
label var numa     "No. of authors"
label var numr     "No. of references"
label var pre_cites "Pre-retraction total cites"
label var selfretra "Self-retracted focal"
label var age      "Paper age"

// =====================================================================
// 3. 描述性统计 (Table 1)
// =====================================================================
di ""
di "=========================================="
di " TABLE 1: DESCRIPTIVE STATISTICS"
di "=========================================="

summarize log_cites did post treated dom_dist numa numr ///
    pre_cites age selfretra

di ""
di "--- By Group ---"
bysort group: summarize log_cites did post treated dom_dist numa numr ///
    pre_cites age selfretra

// 样本计数
count if group == 1
local n1 = r(N)
count if group == 0
local n0 = r(N)
di "Treatment rows: " %15.0gc `n1'
di "Control rows:  " %15.0gc `n0'

// =====================================================================
// 4. 基准回归 (Table 2)
// =====================================================================
di ""
di "=========================================="
di " TABLE 2: BASELINE DID"
di "=========================================="

// (1) DID only
reghdfe log_cites did, absorb(panel_id year age) cluster(focal_id)
est store m1
estadd local paper_fe "Y"; estadd local year_fe "Y"; estadd local ctrl "None"

// (2) + Basic controls
reghdfe log_cites did author_year ref_year sef_year ///
    log_numa log_numr, absorb(panel_id year age) cluster(focal_id)
est store m2
estadd local paper_fe "Y"; estadd local year_fe "Y"; estadd local ctrl "Basic"

// (3) + Full controls (Azoulay 2019)
reghdfe log_cites did author_year ref_year sef_year ///
    log_numa log_numr log_pre_cites pre_cites, ///
    absorb(panel_id year age) cluster(focal_id)
est store m3
estadd local paper_fe "Y"; estadd local year_fe "Y"; estadd local ctrl "Full"

// =====================================================================
// 5. 输出
// =====================================================================
esttab m1 m2 m3 ///
    using "/home/wenyutao/retraction_analysis2/StataAnalysis/Table_Baseline.csv", ///
    replace b(%9.3f) t(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    drop(author_year ref_year sef_year log_numa log_numr log_pre_cites pre_cites _cons) ///
    scalars("paper_fe Paper_FE" "year_fe Year_FE" "ctrl Controls") ///
    mtitle("DID only" "+Basic" "+Full") ///
    title("Baseline DID: Effect of Retraction on Citations") ///
    addnotes("Paper FE + Year FE + Age FE. SE clustered at focal level." ///
             "Full controls: author_year, ref_year, sef_year, log_numa, log_numr, log_pre_cites, pre_cites_total.")

di ""
di "=== DONE ==="
