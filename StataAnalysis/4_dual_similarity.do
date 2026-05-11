// =====================================================================
// 4_dual_similarity.do — 双维度相似性分析 (加权版)
// 日期: 2026-05-11
// 修改: 2026-05-11 加1:N权重
// 数据: Final_Panel_with_DualSim_clean.csv
// =====================================================================

clear
set more off

// =====================================================================
// 1. 数据导入
// =====================================================================
import delimited "/home/wenyutao/retraction-analysis/StataAnalysis/Final_Panel_with_DualSim_clean.csv", clear
di ""
di "=== 数据: " _N " 行 ==="

// =====================================================================
// 2. 变量预处理
// =====================================================================
replace yearlycitation = 0 if missing(yearlycitation)
capture confirm variable log_yearlycitation
if _rc != 0 gen log_yearlycitation = ln(1 + yearlycitation)
else replace log_yearlycitation = ln(1 + yearlycitation) if missing(log_yearlycitation)

gen log_author = log(1 + numa)
gen log_ref    = log(1 + numr)
gen author_year = log_author * year / 100
gen ref_year    = log_ref * year / 100
gen sef_year    = selfretra * year / 100
gen age = year - pyear

// =====================================================================
// 3. 1:N 匹配权重
//    每个 focal paper 有不同数量的候选 j (1~286个)
//    weight = 1 / (该focal下的候选j数量)
//    使每个focal对回归的贡献相等
// =====================================================================
bysort focal_id pair: gen pair_unique_tag = (_n == 1)
bysort focal_id: egen num_pairs = total(pair_unique_tag) if group == 1
replace num_pairs = 1 if missing(num_pairs)
gen weight = 1 / num_pairs
summarize num_pairs, detail
di "每个 focal 平均候选 j 数: " %9.1f r(mean)

// =====================================================================
// 4. 构造交互项
// =====================================================================
cap drop did_simij did_simjr did_safe
gen did_simij = did * sim_ij_high
gen did_simjr = did * sim_jr_high
gen did_safe  = did * sim_ij_high * (1 - sim_jr_high)

// =====================================================================
// 5. 回归
// =====================================================================
di ""
di "========== [模型1] 基准: did only =========="
reghdfe log_yearlycitation did author_year ref_year sef_year [pw=weight], ///
    absorb(paper_numid year age) cluster(focal_id)
est sto m0

di ""
di "========== [模型2] +Sim(i,j)高 =========="
reghdfe log_yearlycitation did did_simij author_year ref_year sef_year [pw=weight], ///
    absorb(paper_numid year age) cluster(focal_id)
est sto m1

di ""
di "========== [模型3] +双维度 =========="
reghdfe log_yearlycitation did did_simij did_simjr author_year ref_year sef_year [pw=weight], ///
    absorb(paper_numid year age) cluster(focal_id)
est sto m2

di ""
di "========== [模型4] ★核心β₃: +安全替代交互 =========="
reghdfe log_yearlycitation did did_simij did_simjr did_safe author_year ref_year sef_year [pw=weight], ///
    absorb(paper_numid year age) cluster(focal_id)
est sto m3

di ""
di "========== [模型5] 稳健性: +Journal×Year FE =========="
reghdfe log_yearlycitation did did_simij did_simjr did_safe author_year ref_year sef_year [pw=weight], ///
    absorb(paper_numid year age journal_id#year) cluster(focal_id)
est sto m4

// =====================================================================
// 6. 输出表格
// =====================================================================
di ""
di "=== 输出 ==="
esttab m0 m1 m2 m3 m4 ///
    using "/home/wenyutao/retraction-analysis/StataAnalysis/Table_DualSim_weighted.csv", ///
    replace b(%9.3f) t(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    drop(author_year ref_year sef_year _cons) ///
    mtitle("基准" "+Sim(i,j)" "+双维度" "★β₃" "+JxY") ///
    title("Table: Dual Similarity Analysis (1:N Weighted)") ///
    addnotes("Weight = 1/N_pairs_per_focal. All models use [pw=weight]." ///
             "Standard errors clustered at focal_id level." ///
             "Sim(i,j) = Jaccard(focal, candidate); Sim(j,r) = Jaccard(candidate, retracted ref)")

di ""
di "=== 完成 ==="
