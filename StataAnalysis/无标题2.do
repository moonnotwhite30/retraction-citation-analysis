
import delimited ///
"C:\Users\73627\Desktop\研二上\26.4.21\panel_df_concept.csv", ///
clear
drop age sef_year ref_year author_year log_ref log_author
//=========================前期准备（可选择）=========================//
//（1）只聚焦在XXXX年到XXXX年所发表的论文
*drop if pyear <= 1995 | pyear >= 2015
//（2）取log，并构造年份与作者数量NumA、参考文献数量NumR的交互项
gen log_author = log(1+numa)
gen log_ref = log(1+numr)
gen author_year = log_author * year/100
gen ref_year = log_ref * year/100

gen sef_year = selfretra*year/100

//（3）构造撤"撤稿前观测年份长度"变量
gen t_ptor = ryear - pyear //定义撤稿前观测年份长度
//（4）构造"论文年龄"变量
gen age = year - pyear

//（4）TWFE，有控制变量，控制个体+年份+论文年龄效应
reghdfe log_yearlycitation did ///
author_year ref_year sef_year  , ///
absorb(paper_numid year age) cluster(paper_numid) 
est sto FE_age_YesCon
estadd local paper_fe "Yes"
estadd local year_fe  "Yes"
estadd local age_fe   "Yes"

//=========================n_sameconcept分组回归=====================//
* ==============================================================================
* 1. 定义分组 (使用小写变量名 n_sameconcept)
* ==============================================================================
* 请先运行 ds 或 describe 确认你的变量名到底是 n_sameconcept 还是 n_same_concept
cap drop concept_group
gen concept_group = .
replace concept_group = 1 if n_sameconcept == 0
replace concept_group = 2 if n_sameconcept >= 1 & n_sameconcept <= 2
replace concept_group = 3 if n_sameconcept >= 3 & n_sameconcept <= 5
replace concept_group = 4 if n_sameconcept >= 6 & n_sameconcept <= 10
replace concept_group = 5 if n_sameconcept >= 11 & n_sameconcept != .

label define g_lab 1 "0" 2 "1-2" 3 "3-5" 4 "6-10" 5 "11+"
label values concept_group g_lab

* ==============================================================================
* 2. 准备结果收集器
* ==============================================================================
tempname memhold
tempfile results_file
postfile `memhold' group coef se low high obs using "`results_file'", replace

* ==============================================================================
* 3. 循环回归：细分进度展示 (变量名同步改为小写)
* ==============================================================================
local total_groups = 5

forvalues i = 1/`total_groups' {
    local g_name : label g_lab `i'
    
    display as text _newline(1) "{hline 70}"
    display as result "🔍 任务进度: Group `i'/`total_groups' (分桶: `g_name')"
    
    display as text "  [Step 1/4] 正在准备子样本数据..."
    quietly count if concept_group == `i' & did != .
    local n_obs = r(N)
    
    display as text "  [Step 2/4] 启动核心回归: reghdfe (吸纳 paper_numid year age)..."
    
    * ---------------------------------------------------------
    * 保持原代码逻辑，仅将变量名改为小写
    * ---------------------------------------------------------
    timer on `i'
    quietly reghdfe log_yearlycitation did ///
            author_year ref_year sef_year if concept_group == `i', ///
            absorb(paper_numid year age) cluster(paper_numid)
    timer off `i'
    
    display as text "  [Step 3/4] 提取系数并计算置信区间..."
    local b = _b[did]
    local s = _se[did]
    local low_ci = _b[did] - 1.96*_se[did]
    local high_ci = _b[did] + 1.96*_se[did]
    
    display as text "  [Step 4/4] 结果存入缓存..."
    post `memhold' (`i') (`b') (`s') (`low_ci') (`high_ci') (`n_obs')
    
    quietly timer list `i'
    display as result "  ✅ 完成！本组 N: `n_obs' | Coef: " %6.4f `b' " | Time: " %4.2f r(t`i') "s"
}

postclose `memhold'
display as text _newline(1) "{hline 70}"
display as result "✨ 分组回归全部结束！"

* ==============================================================================
* 4. 自动化绘图展示 (已修正 grid 选项与断行符)
* ==============================================================================
preserve
    use "`results_file'", clear
    
    * 计算置信区间 (以防之前步骤没存，这里再算一次)
    cap gen low = coef - 1.96 * se
    cap gen high = coef + 1.96 * se

    * 绘图：将网格线逻辑放入 ylabel 中
    twoway (rcap high low group, lcolor(navy) lwidth(medium)) ///
           (scatter coef group, mcolor(navy) msize(large) msymbol(O)), ///
           yline(0, lcolor(red) lpattern(dash)) ///
           ylabel(, grid glstyle(dot)) ///  <-- 修正点：网格线现在挂在 ylabel 下
           xlabel(1 "0" 2 "1-2" 3 "3-5" 4 "6-10" 5 "11+") ///
           xtitle("Knowledge Overlap (n_sameconcept)", margin(top)) ///
           ytitle("DID Coefficient (log_citation)", margin(right)) ///
           title("Subgroup Regression Results", size(medium)) ///
           legend(off) scheme(s2color) // 建议加个配色方案，更像期刊风格
restore

///////////////////////////////////////////
* ==============================================================================
* 1. 定义更细分的颗粒化分组 (特别针对 8+ 以后)
* ==============================================================================
cap drop concept_group
gen concept_group = .
replace concept_group = 1 if n_sameconcept == 0
replace concept_group = 2 if n_sameconcept == 1
replace concept_group = 3 if n_sameconcept == 2
replace concept_group = 4 if n_sameconcept >= 3  & n_sameconcept <= 4
replace concept_group = 5 if n_sameconcept >= 5  & n_sameconcept <= 7
replace concept_group = 6 if n_sameconcept >= 8  & n_sameconcept <= 10
replace concept_group = 7 if n_sameconcept >= 11 & n_sameconcept <= 13
replace concept_group = 8 if n_sameconcept >= 14 & n_sameconcept != .

label define g_lab 1 "0" 2 "1" 3 "2" 4 "3-4" 5 "5-7" 6 "8-10" 7 "11-13" 8 "14+"
label values concept_group g_lab

* ==============================================================================
* 2. 循环回归：细分进度展示
* ==============================================================================
tempname memhold
tempfile res_fine
postfile `memhold' group coef se low high obs using "`res_fine'", replace

local total_groups = 8

forvalues i = 1/`total_groups' {
    local g_name : label g_lab `i'
    
    display as text _newline(1) "{hline 75}"
    display as result "🚀 正在计算分组 `i'/`total_groups': [N_SameConcept: `g_name']"
    
    * [Step 1]
    display as text "  > 检查样本分布..."
    quietly count if concept_group == `i' & did != .
    local n_obs = r(N)
    
    * [Step 2] 你的原代码逻辑
    display as text "  > 正在执行 reghdfe (控制 paper, year, age)..."
    timer on `i'
    quietly reghdfe log_yearlycitation did ///
            author_year ref_year sef_year if concept_group == `i', ///
            absorb(paper_numid year age) cluster(paper_numid)
    timer off `i'
    
    * [Step 3] 提取并存入结果
    local b = _b[did]
    local s = _se[did]
    local low_ci = _b[did] - 1.96*_se[did]
    local high_ci = _b[did] + 1.96*_se[did]
    
    post `memhold' (`i') (`b') (`s') (`low_ci') (`high_ci') (`n_obs')
    quietly timer list `i'
    display as result "  ✅ 完成! N=`n_obs' | Coef=" %6.4f `b' " | 耗时=" %4.2f r(t`i') "s"
}

postclose `memhold'

* ==============================================================================
* 3. 绘图展示
* ==============================================================================
preserve
    use "`res_fine'", clear
    twoway (rcap high low group, lcolor(navy%60) lwidth(medium)) /// 
           (connected coef group, mcolor(navy) lcolor(navy) msize(large) msymbol(O)), ///
           yline(0, lcolor(red) lpattern(dash)) ///
           ylabel(, grid glstyle(dot)) ///
           xlabel(1 "0" 2 "1" 3 "2" 4 "3-4" 5 "5-7" 6 "8-10" 7 "11-13" 8 "14+") ///
           xtitle("Finer Knowledge Overlap Groups") ///
           ytitle("DID Coefficient (log_citation)") ///
           title("Detailed Subgroup Analysis (Tail Focus)", size(medium)) ///
           legend(off)
restore


* ==============================================================================
* 1. 定义新分组 (0, 1, 2, 3-5, 6+)
* ==============================================================================
cap drop concept_group
gen concept_group = .
replace concept_group = 1 if n_sameconcept == 0
replace concept_group = 2 if n_sameconcept == 1
replace concept_group = 3 if n_sameconcept == 2
replace concept_group = 4 if n_sameconcept >= 3 & n_sameconcept <= 5
replace concept_group = 5 if n_sameconcept >= 6 & n_sameconcept != .

label define g_lab 1 "0" 2 "1" 3 "2" 4 "3-5" 5 "6+"
label values concept_group g_lab

* ==============================================================================
* 2. 准备结果收集器 (postfile)
* ==============================================================================
tempname memhold
tempfile results_file
postfile `memhold' group coef se low high obs using "`results_file'", replace

* ==============================================================================
* 3. 循环回归：细分进度展示
* ==============================================================================
local total_groups = 5  // 合并后共 5 组

forvalues i = 1/`total_groups' {
    local g_name : label g_lab `i'
    
    display as text _newline(1) "{hline 70}"
    display as result "🔍 任务进度: Group `i'/`total_groups' (分桶: `g_name')"
    
    display as text "  [Step 1/4] 正在准备子样本数据..."
    quietly count if concept_group == `i' & did != .
    local n_obs = r(N)
    
    display as text "  [Step 2/4] 启动核心回归: reghdfe (吸纳 paper_numid year age)..."
    
    timer on `i'
    * 保持你的原回归逻辑
    quietly reghdfe log_yearlycitation did ///
            author_year ref_year sef_year if concept_group == `i', ///
            absorb(paper_numid year age) cluster(paper_numid)
    timer off `i'
    
    display as text "  [Step 3/4] 提取系数并计算置信区间..."
    local b = _b[did]
    local s = _se[did]
    local low_ci = _b[did] - 1.96*_se[did]
    local high_ci = _b[did] + 1.96*_se[did]
    
    display as text "  [Step 4/4] 结果存入缓存..."
    post `memhold' (`i') (`b') (`s') (`low_ci') (`high_ci') (`n_obs')
    
    quietly timer list `i'
    display as result "  ✅ 完成！本组 N: `n_obs' | Coef: " %6.4f `b' " | Time: " %4.2f r(t`i') "s"
}

postclose `memhold'
display as text _newline(1) "{hline 70}"
display as result "✨ 分组回归全部结束！"

* ==============================================================================
* 4. 自动化绘图展示 (修正版)
* ==============================================================================
preserve
    use "`results_file'", clear
    
    * 确保置信区间列存在
    cap gen low = coef - 1.96 * se
    cap gen high = coef + 1.96 * se

    * 绘图：优化坐标轴与网格
    twoway (rcap high low group, lcolor(navy) lwidth(medium)) ///
           (scatter coef group, mcolor(navy) msize(large) msymbol(O)), ///
           yline(0, lcolor(red) lpattern(dash)) ///
           ylabel(, grid glstyle(dot)) ///
           xlabel(1 "0" 2 "1" 3 "2" 4 "3-5" 5 "6+") ///
           xtitle("Knowledge Overlap (n_sameconcept)", margin(top)) ///
           ytitle("DID Coefficient (log_citation)", margin(right)) ///
           title("Subgroup Regression: Merged High-Overlap Tail", size(medium)) ///
           note("Notes: Merged groups with 6+ concepts to increase precision.", size(vsmall)) ///
           legend(off) scheme(s2color)
restore

* ==============================================================================
* 1. 构造"均等样本"分组 (基于分位数特征)
* ==============================================================================
cap drop concept_group
gen concept_group = .
replace concept_group = 1 if n_sameconcept == 0
replace concept_group = 2 if n_sameconcept == 1
replace concept_group = 3 if n_sameconcept == 2
replace concept_group = 4 if n_sameconcept >= 3 & n_sameconcept <= 4
replace concept_group = 5 if n_sameconcept >= 5 & n_sameconcept <= 7
replace concept_group = 6 if n_sameconcept >= 8 & n_sameconcept != .

label define g_lab 1 "0" 2 "1" 3 "2" 4 "3-4" 5 "5-7" 6 "8+"
label values concept_group g_lab

* ==============================================================================
* 2. 准备结果收集器
* ==============================================================================
tempname memhold
tempfile results_equal
postfile `memhold' group coef se low high obs using "`results_equal'", replace

* ==============================================================================
* 3. 循环执行：每一小步都反馈进度
* ==============================================================================
local total_groups = 6

forvalues i = 1/`total_groups' {
    local g_name : label g_lab `i'
    
    display as text _newline(1) "{hline 70}"
    display as result "🔍 正在处理均衡分组 `i'/`total_groups' (范围: `g_name')"
    
    * [Step 1/4] 样本量核对
    display as text "  > [Step 1] 正在提取数据并核算样本量..."
    quietly count if concept_group == `i' & did != .
    local n_obs = r(N)
    
    * [Step 2/4] 执行原定回归逻辑
    display as text "  > [Step 2] 启动核心回归: reghdfe (控制个体+年份+年龄)..."
    timer on `i'
    quietly reghdfe log_yearlycitation did ///
            author_year ref_year sef_year if concept_group == `i', ///
            absorb(paper_numid year age) cluster(paper_numid)
    timer off `i'
    
    * [Step 3/4] 结果抓取
    display as text "  > [Step 3] 正在提取 DID 系数与置信区间..."
    local b = _b[did]
    local s = _se[did]
    local low_ci = _b[did] - 1.96*_se[did]
    local high_ci = _b[did] + 1.96*_se[did]
    
    * [Step 4/4] 存入临时文件
    display as text "  > [Step 4] 正在清理缓存并保存结果..."
    post `memhold' (`i') (`b') (`s') (`low_ci') (`high_ci') (`n_obs')
    
    quietly timer list `i'
    display as result "  ✅ 完成! 样本数: `n_obs' | 耗时: " %4.2f r(t`i') "s"
}

postclose `memhold'
display as text _newline(1) "{hline 70}"
display as result "✨ 所有分组任务执行完毕！正在绘制系数图..."

* ==============================================================================
* 4. 绘图展示
* ==============================================================================
preserve
    use "`results_equal'", clear
    
    twoway (rcap high low group, lcolor(navy) lwidth(medium)) ///
           (scatter coef group, mcolor(navy) msize(large) msymbol(O)), ///
           yline(0, lcolor(red) lpattern(dash)) ///
           ylabel(, grid glstyle(dot)) ///
           xlabel(1 "0" 2 "1" 3 "2" 4 "3-4" 5 "5-7" 6 "8+") ///
           xtitle("Knowledge Overlap (Grouped by Sample Quantiles)", margin(top)) ///
           ytitle("DID Coefficient (log_citation)", margin(right)) ///
           title("Equally Divided Subgroup Analysis", size(medium)) ///
           legend(off) scheme(s2color)
restore





* ==============================================================================
* 1. 重新定义分组 (0, 1, 2, 3-4, 5-7, 8-10, 11+)
* ==============================================================================
cap drop concept_group
gen concept_group = .
replace concept_group = 1 if n_sameconcept == 0
replace concept_group = 2 if n_sameconcept == 1
replace concept_group = 3 if n_sameconcept == 2
replace concept_group = 4 if n_sameconcept >= 3  & n_sameconcept <= 4
replace concept_group = 5 if n_sameconcept >= 5  & n_sameconcept <= 7
replace concept_group = 6 if n_sameconcept >= 8  & n_sameconcept <= 10
replace concept_group = 7 if n_sameconcept >= 11 & n_sameconcept != .

label define g_lab 1 "0" 2 "1" 3 "2" 4 "3-4" 5 "5-7" 6 "8-10" 7 "11+"
label values concept_group g_lab

* ==============================================================================
* 2. 准备结果收集器 (postfile)
* ==============================================================================
tempname memhold
tempfile res_merged
postfile `memhold' group coef se low high obs using "`res_merged'", replace

* ==============================================================================
* 3. 循环回归：细分进度展示
* ==============================================================================
local total_groups = 7  // 合并后总共 7 组

forvalues i = 1/`total_groups' {
    local g_name : label g_lab `i'
    
    display as text _newline(1) "{hline 75}"
    display as result "🚀 正在计算分组 `i'/`total_groups': [N_SameConcept: `g_name']"
    
    * [Step 1] 检查样本
    display as text "  > 检查样本分布..."
    quietly count if concept_group == `i' & did != .
    local n_obs = r(N)
    
    * [Step 2] 核心回归逻辑 (保持原封不动)
    display as text "  > 正在执行 reghdfe (吸纳 paper_numid year age)..."
    timer on `i'
    quietly reghdfe log_yearlycitation did ///
            author_year ref_year sef_year if concept_group == `i', ///
            absorb(paper_numid year age) cluster(paper_numid)
    timer off `i'
    
    * [Step 3] 提取统计量
    local b = _b[did]
    local s = _se[did]
    local low_ci = _b[did] - 1.96*_se[did]
    local high_ci = _b[did] + 1.96*_se[did]
    
    * [Step 4] 结果存档
    post `memhold' (`i') (`b') (`s') (`low_ci') (`high_ci') (`n_obs')
    quietly timer list `i'
    display as result "  ✅ 完成! N=`n_obs' | Coef=" %6.4f `b' " | 耗时=" %4.2f r(t`i') "s"
}

postclose `memhold'

* ==============================================================================
* 4. 绘图展示
* ==============================================================================
preserve
    use "`res_merged'", clear
    
    * 生成绘图所需的置信区间
    cap gen low = coef - 1.96 * se
    cap gen high = coef + 1.96 * se

    twoway (rcap high low group, lcolor(navy%70) lwidth(medium)) /// 
           (connected coef group, mcolor(navy) lcolor(navy) msize(large) msymbol(O)), ///
           yline(0, lcolor(red) lpattern(dash)) ///
           ylabel(, grid glstyle(dot)) ///
           xlabel(1 "0" 2 "1" 3 "2" 4 "3-4" 5 "5-7" 6 "8-10" 7 "11+") ///
           xtitle("Knowledge Overlap (n_sameconcept)", margin(top)) ///
           ytitle("DID Coefficient (log_citation)", margin(right)) ///
           title("Subgroup Analysis: Merged Tail (11+)", size(medium)) ///
           note("Notes: 11+ group merges top 5% samples to ensure statistical power.") ///
           legend(off) scheme(s2color)
restore


* ==============================================================================
* 1. 重新定义分组 (0, 1, 2, 3-4, 5-7, 8+)
* ==============================================================================
cap drop concept_group
gen concept_group = .
replace concept_group = 1 if n_sameconcept == 0
replace concept_group = 2 if n_sameconcept == 1
replace concept_group = 3 if n_sameconcept == 2
replace concept_group = 4 if n_sameconcept >= 3 & n_sameconcept <= 4
replace concept_group = 5 if n_sameconcept >= 5 & n_sameconcept <= 7
replace concept_group = 6 if n_sameconcept >= 8 & n_sameconcept != .

label define g_lab 1 "0" 2 "1" 3 "2" 4 "3-4" 5 "5-7" 6 "8+"
label values concept_group g_lab

* ==============================================================================
* 2. 准备结果收集器 (postfile)
* ==============================================================================
tempname memhold
tempfile res_merged_8plus
postfile `memhold' group coef se low high obs using "`res_merged_8plus'", replace

* ==============================================================================
* 3. 循环回归：细分进度展示
* ==============================================================================
local total_groups = 6  // 现在是 6 个均衡分组

forvalues i = 1/`total_groups' {
    local g_name : label g_lab `i'
    
    display as text _newline(1) "{hline 75}"
    display as result "🚀 正在计算分组 `i'/`total_groups': [N_SameConcept: `g_name']"
    
    * [Step 1] 检查样本
    display as text "  > [1/4] 检查样本分布与数据提取..."
    quietly count if concept_group == `i' & did != .
    local n_obs = r(N)
    
    * [Step 2] 核心回归逻辑 (保持原封不动)
    display as text "  > [2/4] 正在执行 reghdfe (吸纳 paper_numid year age)..."
    timer on `i'
    quietly reghdfe log_yearlycitation did ///
            author_year ref_year sef_year if concept_group == `i', ///
            absorb(paper_numid year age) cluster(paper_numid)
    timer off `i'
    
    * [Step 3] 提取统计量
    display as text "  > [3/4] 计算 DID 系数与置信区间..."
    local b = _b[did]
    local s = _se[did]
    local low_ci = _b[did] - 1.96*_se[did]
    local high_ci = _b[did] + 1.96*_se[did]
    
    * [Step 4] 结果存档
    display as text "  > [4/4] 正在清理缓存并保存结果..."
    post `memhold' (`i') (`b') (`s') (`low_ci') (`high_ci') (`n_obs')
    
    quietly timer list `i'
    display as result "  ✅ 完成! 本组样本量: `n_obs' | 耗时: " %4.2f r(t`i') "s"
}

postclose `memhold'

* ==============================================================================
* 4. 自动化绘图展示
* ==============================================================================
preserve
    use "`res_merged_8plus'", clear
    
    * 生成绘图所需变量
    cap gen low = coef - 1.96 * se
    cap gen high = coef + 1.96 * se

    twoway (rcap high low group, lcolor(navy%70) lwidth(medium)) /// 
           (connected coef group, mcolor(navy) lcolor(navy) msize(large) msymbol(O)), ///
           yline(0, lcolor(red) lpattern(dash)) ///
           ylabel(, grid glstyle(dot)) ///
           xlabel(1 "0" 2 "1" 3 "2" 4 "3-4" 5 "5-7" 6 "8+") ///
           xtitle("Knowledge Overlap (n_sameconcept)", margin(top)) ///
           ytitle("DID Coefficient (log_citation)", margin(right)) ///
           title("Subgroup Analysis: Optimized Grouping (8+)", size(medium)) ///
           note("Notes: Merged tail (8+) to ensure statistical precision across categories.") ///
           legend(off) scheme(s2color)
restore

* ==============================================================================
* 1. 重新定义极致颗粒化分组 (0, 1, 2, 3, 4, 5, 6, 7, 8-10, 11+)
* ==============================================================================
cap drop concept_group
gen concept_group = .
replace concept_group = 1  if n_sameconcept == 0
replace concept_group = 2  if n_sameconcept == 1
replace concept_group = 3  if n_sameconcept == 2
replace concept_group = 4  if n_sameconcept == 3
replace concept_group = 5  if n_sameconcept == 4
replace concept_group = 6  if n_sameconcept == 5
replace concept_group = 7  if n_sameconcept == 6
replace concept_group = 8  if n_sameconcept == 7
replace concept_group = 9  if n_sameconcept >= 8  & n_sameconcept <= 10
replace concept_group = 10 if n_sameconcept >= 11 & n_sameconcept != .

label define g_lab 1 "0" 2 "1" 3 "2" 4 "3" 5 "4" 6 "5" 7 "6" 8 "7" 9 "8-10" 10 "11+"
label values concept_group g_lab

* ==============================================================================
* 2. 准备结果收集器 (postfile)
* ==============================================================================
tempname memhold
tempfile res_granular
postfile `memhold' group coef se low high obs using "`res_granular'", replace

* ==============================================================================
* 3. 循环回归：细分进度展示
* ==============================================================================
local total_groups = 10  // 现在扩展到了 10 个组

forvalues i = 1/`total_groups' {
    local g_name : label g_lab `i'
    
    display as text _newline(1) "{hline 75}"
    display as result "🚀 正在计算极致颗粒化分组 `i'/`total_groups': [N: `g_name']"
    
    * [Step 1] 检查样本分布
    display as text "  > 检查样本分布..."
    quietly count if concept_group == `i' & did != .
    local n_obs = r(N)
    
    * [Step 2] 核心回归逻辑 (你的原代码)
    display as text "  > 正在执行 reghdfe (吸纳 paper_numid year age)..."
    timer on `i'
    quietly reghdfe log_yearlycitation did ///
            author_year ref_year sef_year if concept_group == `i', ///
            absorb(paper_numid year age) cluster(paper_numid)
    timer off `i'
    
    * [Step 3] 提取统计量
    local b = _b[did]
    local s = _se[did]
    local low_ci = _b[did] - 1.96*_se[did]
    local high_ci = _b[did] + 1.96*_se[did]
    
    * [Step 4] 结果存档
    post `memhold' (`i') (`b') (`s') (`low_ci') (`high_ci') (`n_obs')
    
    quietly timer list `i'
    display as result "  ✅ 完成! N=`n_obs' | Coef=" %6.4f `b' " | 耗时=" %4.2f r(t`i') "s"
}

postclose `memhold'

* ==============================================================================
* 4. 自动化绘图展示
* ==============================================================================
preserve
    use "`res_granular'", clear
    
    * 重新计算置信区间
    cap gen low = coef - 1.96 * se
    cap gen high = coef + 1.96 * se

    * 绘图：展示更精细的惩罚演变
    twoway (rcap high low group, lcolor(navy%60) lwidth(medium)) /// 
           (connected coef group, mcolor(navy) lcolor(navy) msize(large) msymbol(O)), ///
           yline(0, lcolor(red) lpattern(dash)) ///
           ylabel(, grid glstyle(dot)) ///
           xlabel(1 "0" 2 "1" 3 "2" 4 "3" 5 "4" 6 "5" 7 "6" 8 "7" 9 "8-10" 10 "11+") ///
           xtitle("Granular Knowledge Overlap (n_sameconcept)", margin(top)) ///
           ytitle("DID Coefficient (log_citation)", margin(right)) ///
           title("Detailed Subgroup Regression (n=0 to 11+)", size(medium)) ///
           legend(off) scheme(s2color)
restore



