// =====================================================================
// 1. 数据导入与预处理
// =====================================================================
import delimited "C:\Users\73627\Desktop\研二上\26.4.21\Final_Panel_for_Stata.csv", clear

// 统一变量名小写并处理缺失值
replace yearlycitation = 0 if missing(yearlycitation)
replace log_yearlycitation = ln(1 + yearlycitation) if missing(log_yearlycitation)

// 交互项构造
gen log_author = log(1 + numa)
gen log_ref    = log(1 + numr)
gen author_year = log_author * year / 100
gen ref_year    = log_ref * year / 100
gen sef_year    = selfretra * year / 100

// 构造论文年龄
gen age = year - pyear

// =====================================================================
// 2. 核心回归：重新定义分组 (0-1, 2-10, >10)
// =====================================================================

// --- [模型 1] 基准/低重合度组 (N <= 1) ---
reghdfe log_yearlycitation did ///
    author_year ref_year sef_year if n_sameconcept <= 1, ///
    absorb(paper_numid year age) cluster(focal_id) 
est sto low_n
estadd local paper_fe "Yes"
estadd local year_fe  "Yes"
estadd local age_fe   "Yes"

// --- [模型 2] 中度重合度组 (2 <= N <= 10) ---
reghdfe log_yearlycitation did ///
    author_year ref_year sef_year if n_sameconcept >= 2 & n_sameconcept <= 10, ///
    absorb(paper_numid year age) cluster(focal_id) 
est sto mid_n
estadd local paper_fe "Yes"
estadd local year_fe  "Yes"
estadd local age_fe   "Yes"

// --- [模型 3] 高度重合度组 (N > 10) ---
reghdfe log_yearlycitation did ///
    author_year ref_year sef_year if n_sameconcept > 10, ///
    absorb(paper_numid year age) cluster(focal_id) 
est sto high_n
estadd local paper_fe "Yes"
estadd local year_fe  "Yes"
estadd local age_fe   "Yes"

// =====================================================================
// 3. 机制检验：连续调节效应
// =====================================================================
capture drop did_x_n 
gen did_x_n = did * n_sameconcept

reghdfe log_yearlycitation did did_x_n ///
    author_year ref_year sef_year, ///
    absorb(paper_numid year age) cluster(focal_id)
est sto interaction_model

// =====================================================================
// 4. 结果汇总输出
// =====================================================================
esttab low_n mid_n high_n interaction_model, ///
    b(%9.3f) t(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    scalars("paper_fe Paper FE" "year_fe Year FE" "age_fe Age FE") ///
    mtitle("N <= 1" "2 <= N <= 10" "N > 10" "Interaction") ///
    title("Spillover Effects with New Grouping")
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	//jaccard版本
// =====================================================================
// 针对 1:N 匹配优化的带权重回归分析 (Weighted Ripple Effect Analysis)
// =====================================================================

clear
set more off

// 1. 导入数据
import delimited "C:\Users\73627\Desktop\研二上\26.4.21\Final_Panel_with_Jaccard_10NumRA.csv", clear

// 2. 基础变量预处理
di "🚀 正在进行变量预处理..."
replace yearlycitation = 0 if missing(yearlycitation)
cap gen log_yearlycitation = ln(1 + yearlycitation)

gen log_author = log(1 + numa)
gen log_ref    = log(1 + numr)
gen age        = year - pyear

// 生成交互控制项 (分母除以 100 是为了防止系数太小，不影响显著性)
gen author_year = log_author * year / 100
gen ref_year    = log_ref * year / 100
gen sef_year    = selfretra * year / 100

// ---------------------------------------------------------------------
// 3. 计算 1:N 权重 (关键步骤)
// ---------------------------------------------------------------------
di "⚖️ 正在计算 1:N 匹配权重..."

// 首先标记唯一的配对 (一个 pair 包含一实验一控制，在面板中重复多年)
bysort focal_id pair: gen pair_unique_tag = (_n == 1)

// 计算每个撤稿论文 (focal_id) 总共匹配到了多少个唯一的 pair
bysort focal_id: egen num_pairs = total(pair_unique_tag)

// 生成权重变量：权重 = 1 / 该事件下的配对总数
gen weight = 1 / num_pairs

// 4. 动态分组逻辑 (基于 ja_sameconcept 的分布)
// ---------------------------------------------------------------------
di "📊 正在计算 Jaccard 分布分位数..."
quietly summarize ja_sameconcept if group == 1 & ja_sameconcept > 0, detail
local p50 = r(p50)
local p90 = r(p90)

cap drop ja_group
gen ja_group = 1 if ja_sameconcept == 0
replace ja_group = 2 if ja_sameconcept > 0 & ja_sameconcept <= `p50'
replace ja_group = 3 if ja_sameconcept > `p50' & ja_sameconcept <= `p90'
replace ja_group = 4 if ja_sameconcept > `p90'

label define jlab 1 "Ja=0" 2 "Low(<=P50)" 3 "Mid(P50-P90)" 4 "High(>P90)"
label values ja_group jlab

// ---------------------------------------------------------------------
// 5. 执行带权重的分组回归 [pw=weight]
// ---------------------------------------------------------------------
di "⚖️ 正在执行带权重的分样本回归..."
forvalues i = 1/4 {
    // 使用 [pw=weight] 进行概率加权
    reghdfe log_yearlycitation did ///
        author_year ref_year sef_year [pw=weight] if ja_group == `i', ///
        absorb(paper_numid year age) cluster(focal_id) 
    
    est sto mw`i'
    estadd local paper_fe "Yes"
    estadd local year_fe  "Yes"
    estadd local age_fe   "Yes"
    estadd local weighted "Yes"
}

// ---------------------------------------------------------------------
// 6. 执行带权重的连续调节项回归
// ---------------------------------------------------------------------
di "🔗 正在执行带权重的连续调节效应回归..."
cap drop did_x_ja
gen did_x_ja = did * ja_sameconcept

reghdfe log_yearlycitation did did_x_ja ///
    author_year ref_year sef_year [pw=weight], ///
    absorb(paper_numid year age) cluster(focal_id)

est sto mw_inter
estadd local paper_fe "Yes"
estadd local year_fe  "Yes"
estadd local age_fe   "Yes"
estadd local weighted "Yes"

// ---------------------------------------------------------------------
// 7. 输出最终结果表格
// ---------------------------------------------------------------------
esttab mw1 mw2 mw3 mw4 mw_inter, ///
    b(%9.3f) t(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    scalars("paper_fe Paper FE" "year_fe Year FE" "weighted Weighted") ///
    mtitle("Ja=0" "Low" "Mid" "High" "Interact") ///
    title("Weighted Spillover Analysis (1:N Corrected)") ///
    addnotes("Weight = 1/N, where N is the number of pairs per Focal paper." ///
             "Standard errors are clustered at the Focal level.")
//////////////////////////
// =====================================================================
// =====================================================================
// 修正版：10 分组带权重回归 (修复 r(198) 语法错误)
// =====================================================================

clear
set more off

// 1. 导入数据
import delimited "C:\Users\73627\Desktop\研二上\26.4.21\Final_Panel_with_Jaccard_10NumRA.csv", clear

// 2. 基础变量预处理
di "🚀 正在预处理变量..."
replace yearlycitation = 0 if missing(yearlycitation)
cap gen log_yearlycitation = ln(1 + yearlycitation)

gen log_author = log(1 + numa)
gen log_ref    = log(1 + numr)
gen age        = year - pyear

gen author_year = log_author * year / 100
gen ref_year    = log_ref * year / 100
gen sef_year    = selfretra * year / 100

// 3. 计算 1:N 权重
di "⚖️ 正在计算 1:N 匹配权重..."
bysort focal_id pair: gen pair_unique_tag = (_n == 1)
bysort focal_id: egen num_pairs = total(pair_unique_tag)
gen weight = 1 / num_pairs

// 4. 十分位均匀分组 (针对 Jaccard > 0 的样本)
di "📊 正在进行 10 分位分组..."
cap drop ja_decile
xtile ja_decile = ja_sameconcept if ja_sameconcept > 0, n(10)

// ---------------------------------------------------------------------
// 5. 循环回归 (优化统计量提取逻辑)
// ---------------------------------------------------------------------
di "⚖️ 正在执行分组回归..."

forvalues i = 1/10 {
    di "👉 正在分析第 `i` / 10 组..."
    
    // 执行回归
    reghdfe log_yearlycitation did ///
        author_year ref_year sef_year [pw=weight] if ja_decile == `i', ///
        absorb(paper_numid year age) cluster(focal_id)
    
    // 存储模型
    est store g`i'
    
    // 统计唯一 ID 数量 (不使用 preserve，更稳健)
    // 统计该组内的唯一 Focal 数量
    quietly count if ja_decile == `i' & pair_unique_tag == 1 & group == 1
    local n_focal = r(N)
    
    // 统计该组内的总对子数 (Experimental + Control)
    quietly count if ja_decile == `i' & pair_unique_tag == 1
    local n_pairs = r(N)
    
    // 将统计量打入模型标量中
    estadd scalar n_focal = `n_focal'
    estadd scalar n_pair  = `n_pairs'
    estadd local paper_fe "Yes"
    estadd local year_fe  "Yes"
}

// ---------------------------------------------------------------------
// 6. 输出结果表格 (展示 Focal 数和 Pair 数)
// ---------------------------------------------------------------------
di "📝 正在生成最终报表..."

// 如果 esttab 报错，请先执行 ssc install estout
esttab g1 g2 g3 g4 g5 g6 g7 g8 g9 g10, ///
    b(%9.3f) t(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    drop(author_year ref_year sef_year _cons) ///
    scalars("n_focal Num_Focals" "n_pair Num_Pairs" "paper_fe Paper_FE" "year_fe Year_FE") ///
    mtitle("D1" "D2" "D3" "D4" "D5" "D6" "D7" "D8" "D9" "D10") ///
    title("Weighted Spillover Analysis: 10 Deciles of Jaccard") ///
    addnotes("Weight = 1/N. Num_Focals: Unique retracted papers." "Num_Pairs: Total experimental-control pairs.")

// 安装必要的绘图插件（如果没装的话）
// ssc install coefplot

coefplot g1 g2 g3 g4 g5 g6 g7 g8 g9 g10, ///
    keep(did) ///
    vertical ///
    yline(0, lcolor(red) lpattern(dash)) /// // 参考线
    ylabel(, format(%9.2f)) ///
    ytitle("Spillover Effect (DID Coefficient)") ///
    xtitle("Deciles of Jaccard Similarity (Low to High)") ///
    title("The Gradient of Retraction Ripple Effect") ///
    rename(g1="D1" g2="D2" g3="D3" g4="D4" g5="D5" g6="D6" g7="D7" g8="D8" g9="D9" g10="D10") ///
    recast(connect) // 把点连成线，更能体现趋势



// =====================================================================
// =====================================================================// =====================================================================
// 最终高性能修正版：标记法计数 (解决 inspect 报错与内存崩溃问题)
// =====================================================================

clear
set more off

// 1. 导入数据 (请根据实际路径修改)
import delimited "C:\Users\73627\Desktop\研二上\26.4.21\Final_Panel_with_Jaccard_10NumRA.csv", clear

// 2. 基础变量预处理
di "🚀 正在预处理变量..."
replace yearlycitation = 0 if missing(yearlycitation)
cap gen log_yearlycitation = ln(1 + yearlycitation)

gen log_author = log(1 + numa)
gen log_ref    = log(1 + numr)
gen age        = year - pyear

gen author_year = log_author * year / 100
gen ref_year    = log_ref * year / 100
gen sef_year    = selfretra * year / 100

// 3. 计算 1:N 权重与分组广播 (同前，确保逻辑严密)
bysort focal_id pair: gen pair_unique_tag = (_n == 1)
bysort focal_id: egen num_pairs = total(pair_unique_tag)
gen weight = 1 / num_pairs

xtile temp_decile = ja_sameconcept if ja_sameconcept > 0 & group == 1, n(10)
bysort pair: egen ja_decile = max(temp_decile)
replace ja_decile = 0 if missing(ja_decile)
drop temp_decile

// ---------------------------------------------------------------------
// 4. 关键：在循环外先行标记去重 ID (标记只需做一次，节省几十分钟时间)
// ---------------------------------------------------------------------
di "🏷️ 正在全局标记去重 ID..."

// 标记唯一的撤稿事件 (focal_id)
bysort ja_decile focal_id: gen tag_focal = (_n == 1)

// 标记唯一的论文个体 (paper_id)
// 注意：实验组和控制组是互斥的，所以按这三个维度标记即可
bysort ja_decile group paper_id: gen tag_paper = (_n == 1)

// ---------------------------------------------------------------------
// 5. 循环回归与计数
// ---------------------------------------------------------------------
di "⚖️ 正在执行分组回归..."

forvalues i = 0/10 {
    di "👉 正在分析组别: `i' / 10 ..."
    
    // 执行加权回归
    reghdfe log_yearlycitation did ///
        author_year ref_year sef_year [pw=weight] if ja_decile == `i', ///
        absorb(paper_numid year age) cluster(focal_id)
    
    est store g`i'
    
    // --- 使用标记位精准计数 (极速) ---
    
    // 1. 唯一撤稿事件数 (Focals)
    quietly count if ja_decile == `i' & tag_focal == 1
    local nf = r(N)
    
    // 2. 唯一实验组论文数 (Candidate)
    quietly count if ja_decile == `i' & tag_paper == 1 & group == 1
    local nt = r(N)
    
    // 3. 唯一控制组论文数 (Cid)
    quietly count if ja_decile == `i' & tag_paper == 1 & group == 0
    local nc = r(N)
    
    // 注入标量
    estadd scalar n_focal = `nf'
    estadd scalar n_treat = `nt'
    estadd scalar n_control = `nc'
    estadd local paper_fe "Yes"
    estadd local year_fe  "Yes"
}

// ---------------------------------------------------------------------
// 6. 输出结果表格
// ---------------------------------------------------------------------
di "📝 正在生成最终报表..."

esttab g0 g1 g2 g3 g4 g5 g6 g7 g8 g9 g10, ///
    b(%9.3f) t(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    drop(author_year ref_year sef_year _cons) ///
    scalars("n_focal Num_Focals" "n_treat Num_Treats" "n_control Num_Controls" "paper_fe Paper_FE") ///
    mtitle("Base" "D1" "D2" "D3" "D4" "D5" "D6" "D7" "D8" "D9" "D10") ///
    title("Ripple Effect: Weighted Decile Analysis (Final Corrected)")

// 7. 绘图
coefplot g0 g1 g2 g3 g4 g5 g6 g7 g8 g9 g10, ///
    keep(did) vertical yline(0, lcolor(red) lpattern(dash)) ///
    rename(g0="Base" g1="D1" g2="D2" g3="D3" g4="D4" g5="D5" g6="D6" g7="D7" g8="D8" g9="D9" g10="D10") ///
    recast(connect)


// 1. 绘制 Jaccard 分数在 10 个十分位组中的分布
graph box ja_sameconcept if ja_decile > 0, ///
    over(ja_decile, label(alternate)) /// // 分组展示，交错显示标签防止重叠
    ytitle("Jaccard Similarity Score") ///
    title("Distribution of Jaccard Scores across Deciles (D1-D10)") ///
    note("Excluding Base Group (Jaccard = 0)") ///
    box(1, fcolor(teal%80) lcolor(black)) /// // 设置专业色系
    marker(1, msize(tiny) mcolor(gray%30))    // 缩小异常值标记















//////////////////////////////////////////////////////////////////////////
// =====================================================================
// 自动化处理四个阈值的面板数据
// =====================================================================

local thresholds "0.0 0.1 0.2 0.3"

foreach t in `thresholds' {
    
    // 1. 清除当前内存并导入对应阈值的文件
    clear
    di "正在分析阈值：T = `t'"
    import delimited "C:\Users\73627\Desktop\研二上\26.4.21\Final_Panel_with_`t'_Jaccard.csv", clear

    // 2. 基础变量预处理
    replace yearlycitation = 0 if missing(yearlycitation)
    replace log_yearlycitation = ln(1 + yearlycitation) if missing(log_yearlycitation)
    
    gen log_author = log(1 + numa)
    gen log_ref    = log(1 + numr)
    gen author_year = log_author * year / 100
    gen ref_year    = log_ref * year / 100
    gen sef_year    = selfretra * year / 100
    gen age = year - pyear
    
    // 3. 动态分组：根据该阈值下 ja_sameconcept 的分布自动划组
    // 逻辑：
    // Group 1: Ja = 0 (基准)
    // Group 2: Ja > 0 且 <= P50 (Low)
    // Group 3: Ja > P50 且 <= P90 (Mid)
    // Group 4: Ja > P90 (High - Top 10%)
    
    quietly summarize ja_sameconcept if group == 1 & ja_sameconcept > 0, detail
    local p50 = r(p50)
    local p90 = r(p90)
    
    cap drop ja_group
    gen ja_group = 1 if ja_sameconcept == 0
    replace ja_group = 2 if ja_sameconcept > 0 & ja_sameconcept <= `p50'
    replace ja_group = 3 if ja_sameconcept > `p50' & ja_sameconcept <= `p90'
    replace ja_group = 4 if ja_sameconcept > `p90'
    
    label define jlab 1 "Ja=0" 2 "Low(<=P50)" 3 "Mid(P50-P90)" 4 "High(>P90)"
    label values ja_group jlab

    // 4. 执行分组回归
    forvalues i = 1/4 {
        reghdfe log_yearlycitation did ///
            author_year ref_year sef_year if ja_group == `i', ///
            absorb(paper_numid year age) cluster(focal_id) 
        est sto t`t'_g`i'
        estadd local paper_fe "Yes"
        estadd local year_fe  "Yes"
    }

    // 5. 执行连续调节项回归 (全样本)
    capture drop did_x_ja
    gen did_x_ja = did * ja_sameconcept
    reghdfe log_yearlycitation did did_x_ja ///
        author_year ref_year sef_year, ///
        absorb(paper_numid year age) cluster(focal_id)
    est sto t`t'_inter
    estadd local paper_fe "Yes"
    estadd local year_fe  "Yes"

    // 6. 立即输出该阈值下的表格
    esttab t`t'_g1 t`t'_g2 t`t'_g3 t`t'_g4 t`t'_inter, ///
        b(%9.3f) t(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
        scalars("paper_fe Paper FE" "year_fe Year FE") ///
        mtitle("Ja=0" "Low" "Mid" "High" "Interact") ///
        title("Threshold T=`t': Spillover Analysis by Dynamic Distribution")
}
	
///////////////////////////
///不同阈值分10个组版本：//
///////////////////////////
// =====================================================================
// 自动化处理四个阈值的面板数据（十分位进化版）
// =====================================================================

local thresholds "0.0 0.1 0.2 0.3"

foreach t in `thresholds' {
    
    // 1. 生成合法后缀（去掉小数点，防止 r(7) 报错）
    local t_suffix = subinstr("`t'", ".", "", .)
    
    di "****************************************************"
    di "🚀 正在执行十分位深度分析：T = `t'"
    di "****************************************************"
    
    // 2. 导入对应文件
    clear
    import delimited "C:\Users\73627\Desktop\研二上\26.4.21\Final_Panel_with_`t'_Jaccard.csv", clear

    // 3. 基础变量预处理
    replace yearlycitation = 0 if missing(yearlycitation)
    replace log_yearlycitation = ln(1 + yearlycitation) if missing(log_yearlycitation)
    
    gen log_author = log(1 + numa)
    gen log_ref    = log(1 + numr)
    gen author_year = log_author * year / 100
    gen ref_year    = log_ref * year / 100
    gen sef_year    = selfretra * year / 100
    gen age = year - pyear
    
    // 4. 动态十分位切分逻辑
    cap drop ja_group
    gen ja_group = 1 if ja_sameconcept == 0  // 基准组：完全不相似
    
    // 使用 xtile 将 ja > 0 的部分均匀切分为 10 个等级
    // 产生的值为 1-10，我们将其偏移到 2-11 组
    tempvar temp_groups
    xtile `temp_groups' = ja_sameconcept if group == 1 & ja_sameconcept > 0, n(10)
    replace ja_group = `temp_groups' + 1 if ja_sameconcept > 0
    
    label define j_decile 1 "Ja=0" 2 "D1" 3 "D2" 4 "D3" 5 "D4" 6 "D5" 7 "D6" 8 "D7" 9 "D8" 10 "D9" 11 "D10"
    label values ja_group j_decile

    // 5. 循环执行 11 组回归 (1个基准 + 10个十分位)
    forvalues i = 1/11 {
        // 只有当该组存在样本时才运行，增强代码健壮性
        quietly count if ja_group == `i'
        if r(N) > 0 {
            reghdfe log_yearlycitation did ///
                author_year ref_year sef_year if ja_group == `i', ///
                absorb(paper_numid year age) cluster(focal_id) 
            
            est sto t`t_suffix'_g`i'
            estadd local paper_fe "Yes"
            estadd local year_fe  "Yes"
        }
    }

  // 6. 结果汇总输出 (展示全部 11 列)
    di "--- 正在生成完整十分位报表 (T=`t') ---"
    
    // 使用 t`t_suffix'_g* 自动匹配该阈值下的所有 11 个组
    esttab t`t_suffix'_g1 t`t_suffix'_g2 t`t_suffix'_g3 t`t_suffix'_g4 t`t_suffix'_g5 ///
           t`t_suffix'_g6 t`t_suffix'_g7 t`t_suffix'_g8 t`t_suffix'_g9 t`t_suffix'_g10 t`t_suffix'_g11, ///
        b(%9.3f) t(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
        compress nogaps nodepvars ///  // 压缩表格宽度，防止在 Stata 窗口里换行太乱
        title("Full Decile Analysis: T=`t'")
}

// =====================================================================
// 7. 终极对比：所有阈值的"最高相似组 (D10)"横向对比
// =====================================================================
esttab t00_g11 t01_g11 t02_g11 t03_g11, ///
    b(%9.3f) t(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    mtitle("T=0.0_D10" "T=0.1_D10" "T=0.2_D10" "T=0.3_D10") ///
    title("Comparison of Top Decile (D10) Across Thresholds")
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	