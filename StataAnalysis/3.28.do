//ssc install unique
//=========================数据导入/DOM阈值0.4========================//
//import delimited ///
//"C:\Users\73627\Desktop\研二上\26.1.5改进\DOM_0.4_1x1_95to15.csv", ///
//clear

import delimited ///
"C:\Users\73627\Desktop\研二上\26.1.30\DOM_0.4_ConclusionInd_field3_jcr_highcita.csv", ///
clear
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
//（5）构造撤稿原因变量
local group_a imagereuse_i imagemanipulation_i datafabrication_i dataerror_i ///
              conclusionerror_i imageerror_i imagefabrication_i analysiserror_i ///
              methoderror_i irreproducible_i datamanipulation_i ///
              materialcontamination_i materialerror_i resultfabrication_i datareuse_i

local group_b articleplagiarism_i redundantpublication_i ///
              authorshipdispute_i unauthorized_i textplagiarism_i ///
              noethicsapproval_i dataplagiarism_i imageplagiarism_i ///
              unspecifiedmisconduct_i inappropriatecitation_i ///
              automaticgeneration_i fakepeerreview_i noinformedconsent_i textreuse_i
egen cat_content_error = rowmax(`group_a')
label var cat_content_error "Issues related to Data/Results/Methods"

egen cat_integrity_issue = rowmax(`group_b')
label var cat_integrity_issue "Issues related to Plagiarism/Ethics/Authorship"
//（6）部分-1变量变为缺失值
* 方法 A：使用 mvdecode 批量将 -1 转换为系统缺失值 (.)
mvdecode crossfield_small bigfield bigr_field field_consistent, mv(-1)
//（7）去掉一些不需要的变量
drop paper_id treated journal_id num_retra reference_ids rjournal_id tags reasonlist otherreason_i unknownreason_i field_code crossfield_big rjcr_better jcr_distance  num_top5max num_top5mean  rnum_top5max rnum_top5mean 


//===========================设置面板数据=============================//
xtset paper_numid year //告诉stata该数据为面板数据
xtdes //面板数据的一些描述


* --- 核心实验变量 ---
label var group "Treatment, n(1=Exp. Group)"
label var year "Observation year"
label var pyear "Publication year"
label var ryear "Ref. retraction year"
label var yearlycitation "Annual citations"
label var log_yearlycitation "Log(Annual citations + 1)"
label var pd "Relative time to event"

* --- 撤稿大类与特征 ---
label var cat_content_error "Reason: Data/method issues, n(0/1)"
label var cat_integrity_issue "Reason: Integrity/ethics, n(0/1)"
label var selfretra "Target paper self-retracted, n(0/1)"
label var t_ptor "Gap: Pub. to ref. retraction"

* --- 论文基础控制变量 ---
label var numa "No. of authors"
label var numr "No. of references"
label var age "Paper age"
label var jcr "Target paper JCR quartile, n(rank)"
label var rjcr "Retracted ref. JCR quartile, n(rank)"

* --- 领域相关变量 ---
label var field "Target paper field ID"
label var r_field "Retracted ref. field ID"
label var crossfield_small "Cross-field citation (minor), n(0/1)"
label var bigfield "Target paper major field"
label var bigr_field "Retracted ref. major field"
label var field_consistent "Field consistency within pair, n(0/1)"

* --- 作者科研实力指标 ---
label var num_top10max "Max. top 10% papers (author)"
label var rnum_top10max "Max. top 10% papers (retr. author)"

* --- ID 类变量 (通常不放进统计表，但建议打上标签) ---
label var pair "Matched Pair ID"
label var paper_numid "Paper Numerical ID"
**# Table1 Descriptive_Statistics
////////////////////////////////////////////////////////////////////////
//===========================输出Table1===============================//
//选择变量并计算统计量
local desc_vars "group year pyear ryear yearlycitation log_yearlycitation pd numa numr selfretra t_ptor age  "
/*
group 虚拟变量，0表示控制组，1表示实验组；
year 观测年份，每个个体都是从发表年到2023；
pyear 论文发表年份；
ryear 实验组论文的参考文献被撤稿的年份；
yearlycitation 论文每年的被引量；
log_yearlycitation 论文每年的引用量加一取对数处理；
pd 此观测年相对于事件发生年（ryear）的相对距离，负数代表事件发生前，0是事件发生当年，正数代表事件发生后；
numa 论文的作者数量；
numr 论文的参考文献数量；
selfretra 是否自己也被撤稿；
*pair实验组控制组的匹配对编号（每个实验组都对应一个唯一的控制组）；//这个决定不放，没有实际的含义
t_ptor 从目标论文的发表到其参考文献被撤稿的时间区间长度；
age 论文的年龄，即论文从发表年到观测年的时间区间长度；
*paper_numid 论文的数字编号；//这个决定不放，没有实际的含义
Issues related to Data/Results/Methods 是否是Data/Results/Methods相关原因
Issues related to Plagiarism/Ethics/Authorship 是否是Plagiarism/Ethics/Authorship相关原因
field 目标论文的领域编号；
r_field 撤稿论文的领域编号；
crossfield_small 虚拟变量，是否存在跨小领域的引用（即field与r_field不一致）；
bigfield 对目标论文的小领域field_l0进行了汇总与划分，归类进了三个大领域；
bigr_field 对撤稿论文的小领域的field_l0进行了汇总与划分，归类进了三个大领域；
field_consistent 虚拟变量，判断同一pair下的是实验组控制组是否属于一个大领域；
jcr 目标论文的jcr分区  
rjcr 撤稿论文的jcr分区
num_top10max 目标论文作者的前10%论文数的最大值
*num_top10mean 目标论文作者的前10%论文数的平均值 //这个决定不放
rnum_top10max 撤稿论文作者的前10%论文数的最大值
*rnum_top10mean 撤稿论文作者的前10%论文数的平均值 //这个决定不放
*/
* --- 核心变量 (Main Variables) ---


estpost summarize `desc_vars', detail

* --- 输出到 Word (RTF) ---
esttab . using "Descriptive_Stats.rtf", ///
    replace ///
    cells("count(fmt(%9.0f) label(N)) mean(fmt(%9.2f) label(Mean)) sd(fmt(%9.2f) label(SD)) p50(fmt(%9.2f) label(Median)) min(fmt(%9.0f) label(Min)) max(fmt(%9.0f) label(Max))") ///
    nonumber nomti noobs label ///
    title("{\b Table 1.} Descriptive statistics of sample (23,288 pairs, N = 631,990)") ///
    addnotes("Note: All statistics are calculated based on the full observation period. For heterogeneity variables with missing values, the matching rate remains above 90%. SD = Standard deviation; JCR = Journal Citation Reports.")
	
	
**# Table2 Impact on Log Yearly Citations
//===========================基准回归部分============================//
//（1）普通OLS，无控制变量
reg log_yearlycitation did 
est sto OLS_NoCon
estadd local paper_fe "No"
estadd local year_fe  "No"
estadd local age_fe   "No"
//（2）普通OLS，控制变量
reg log_yearlycitation did author_year ref_year sef_year
est sto OLS_YesCon
estadd local paper_fe "No"
estadd local year_fe  "No"
estadd local age_fe   "No"
//（3）TWFE，无控制变量，控制个体+年份+论文年龄效应
reghdfe log_yearlycitation did , ///
absorb(paper_numid year age) cluster(paper_numid) 
est sto FE_age_NoCon
estadd local paper_fe "Yes"
estadd local year_fe  "Yes"
estadd local age_fe   "Yes"

//（4）TWFE，有控制变量，控制个体+年份+论文年龄效应
reghdfe log_yearlycitation did ///
author_year ref_year sef_year  , ///
absorb(paper_numid year age) cluster(paper_numid) 
est sto FE_age_YesCon
estadd local paper_fe "Yes"
estadd local year_fe  "Yes"
estadd local age_fe   "Yes"

// --- 定义变量标签：体现时间趋势特征 ---
// 建议：不要直接写公式，使用 "(Trend)" 或 "(× Year)" 表达其实质
label var did "Post-Retraction (DID)"
label var author_year "No. of authors (Trend)"
label var ref_year "No. of references (Trend)"
label var sef_year "Self-retraction (Trend)"
//===========================输出Table2===============================//
//==========================基准回归表格==============================//
//循环处理每个模型：添加个体统计量
local models "OLS_NoCon OLS_YesCon FE_age_NoCon FE_age_YesCon"

foreach m in `models' {
    est restore `m'
  
    // --- 核心：统计回归样本中的实验组/控制组个体数 ---
    tempvar tag_t tag_c
    
    // 统计实验组 (group==1) 且在回归样本中 (e(sample)) 的唯一 ID 数
    quietly egen `tag_t' = tag(paper_numid) if group == 1 & e(sample)
    quietly count if `tag_t' == 1
    estadd scalar n_treat = r(N)
    
    // 统计控制组 (group==0) 且在回归样本中 (e(sample)) 的唯一 ID 数
    quietly egen `tag_c' = tag(paper_numid) if group == 0 & e(sample)
    quietly count if `tag_c' == 1
    estadd scalar n_control = r(N)
}

// --- 修改后的输出代码 ---
esttab OLS_NoCon OLS_YesCon FE_age_NoCon FE_age_YesCon using "Results_Final.rtf", ///
    replace ///
    b(%12.3f) se(%12.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///  // 修改显著性阈值：*** 为 0.001
    label nogaps compress ///
    title("{\b Table 2.} Impact of reference retraction on log annual citations") ///
    mtitle("(1)" "(2)" "(3)" "(4)") /// // 建议使用序号，OLS/TWFE 在 stats 行体现更清晰
    nonumber ///
    stats(paper_fe year_fe age_fe n_treat n_control N r2_a, ///
          fmt(%s %s %s %9.0f %9.0f %9.0f %9.3f) ///
          labels("Paper FE" "Year FE" "Age FE" "Treated papers" "Control papers" "Observations" "Adj. R-squared")) ///
    addnotes("Note: Standard errors are reported in parentheses and clustered at the paper level. The variables marked with '(Trend)' are interactions between the original variable and the observation year (scaled by 1/100). The sample includes 23,288 treatment-control pairs. * p < 0.05, ** p < 0.01, *** p < 0.001.")


	
	
	
	
//=====================================================================//
//===========================稳健性部分================================//
//=====================================================================//
**# Table3 稳健性3：增加控制变量
//===========================（一）常规稳健性================================//
//=============（1）增加控制变量，控制个体+时间+论文年龄=====================//
gen num_top1max_year = num_top1max*year
gen num_top1mean_year = num_top1mean*year
gen num_top10max_year = num_top10max*year
gen num_top10mean_year = num_top10mean*year

gen rnum_top1max_year = rnum_top1max*year
gen rnum_top1mean_year = rnum_top1mean*year
gen rnum_top10max_year = rnum_top10max*year
gen rnum_top10mean_year = rnum_top10mean*year

* ==============================================================================
* 稳健性检验：逐步增加作者与引文质量控制变量
* ==============================================================================
eststo clear

* --- (1) 原始回归：基础控制变量 ---
reghdfe log_yearlycitation did author_year ref_year sef_year , ///
    absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_rob_1

* --- (2) 增加作者端 Top 10% 动态表现 ---
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    num_top10max_year num_top10mean_year, ///
    absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_rob_2

* --- (3) 增加参考文献端 Top 10% 动态表现 ---
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    num_top10max_year num_top10mean_year rnum_top10max_year rnum_top10mean_year, ///
    absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_rob_3

* --- (4) 增加顶尖作者(Top 1%)动态表现 (全模型) ---
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    num_top10max_year num_top10mean_year rnum_top10max_year rnum_top10mean_year ///
    num_top1max_year num_top1mean_year rnum_top1max_year rnum_top1mean_year, ///
    absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_rob_4

* --- 运行前变量标签预设 (针对 keep 的部分) ---
label var did "Post-Retraction (DID)"
label var author_year "No. of authors (Trend)"
label var ref_year "No. of references (Trend)"
label var sef_year "Self-retraction (Trend)"

* --- 输出 Table 3 ---
esttab m_rob_1 m_rob_2 m_rob_3 m_rob_4 using "Robustness_Adding_Controls2.rtf", replace ///
    b(%12.3f) se(%12.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///  // 显著性标准调整
    keep(did author_year ref_year sef_year) /// // 保持核心变量展示
    label nogaps compress ///
    title("{\b Table 3.} Robustness check: Stepwise inclusion of quality controls") ///
    mtitle("(1)" "(2)" "(3)" "(4)") ///
    nonumber ///
    /* 使用 indicate 将大批量的动态控制变量折叠为 Yes/No 行 */ ///
    indicate("Author Top 10% trends = num_top10max_year num_top10mean_year" ///
             "Ref. Top 10% trends    = rnum_top10max_year rnum_top10mean_year" ///
             "Author Top 1% trends   = num_top1max_year num_top1mean_year" ///
             "Ref. Top 1% trends     = rnum_top1max_year rnum_top1mean_year") ///
    stats(hasPaperFE hasYearFE hasAgeFE n_treated n_control N r2_a, ///
          fmt(%s %s %s %9.0f %9.0f %9.0f %9.3f) /// // 样本量 N 强制为整数
          labels("Paper FE" "Year FE" "Age FE" "Treated papers" "Control papers" "Observations" "Adj. R-squared")) ///
    addnotes("Note: Standard errors (in parentheses) are clustered at the paper level. All models include paper, year, and paper-age fixed effects. Controls labeled as 'trends' are interactions of time-invariant quality metrics with the observation year, scaled by 1/100 for readability. * p < 0.05, ** p < 0.01, *** p < 0.001.")


			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 
			 //===========================（2）增减样本量==================================//
*（a）DOM阈值变化
* 设置工作路径
//===========================阈值测试=================================//
/*cd "C:\Users\73627\Desktop\研二上\26.1.5改进\"
* 1. 定义所有阈值（已按从小到大排序，包含 0.07, 0.15, 0.25, 0.6, 0.7）
local thresholds "0.03 0.05 0.07 0.08 0.1 0.15 0.2 0.25 0.3 0.4 0.5 0.6 0.7"

* 初始化用于输出的宏
local all_models ""
local all_mtitles ""

* 清空存储的模型
est clear

foreach t in `thresholds' {
    * --- 1.1 导入数据 ---
    * 确保文件名与磁盘上的文件名完全匹配（例如 DOM_0.15_1x1_95to15.csv）
    capture import delimited "DOM_`t'_1x1_95to15.csv", clear
    if _rc != 0 {
        di as error "文件 DOM_`t'_1x1_95to15.csv 未找到，跳过此阈值。"
        continue
    }
    
    * --- 1.2 构造回归变量 ---
    quietly {
        gen author_year = numa * year
        gen ref_year = numr * year
        gen sef_year = selfretra * year
        gen numretra_year = num_retra * year
        gen age = year - pyear     // 论文年龄
        * t_ptor 虽然构造了，但如果回归没用到可以不用放在这，或者根据需要保留
        gen t_ptor = ryear - pyear 
    }

    * --- 1.3 运行标准回归 ---
    reghdfe log_yearlycitation did author_year ref_year sef_year numretra_year, ///
            absorb(paper_numid year age) cluster(paper_numid)
    
    * --- 1.4 添加固定效应标识和个体统计量 ---
    estadd local paper_fe "Yes"
    estadd local year_fe  "Yes"
    estadd local age_fe   "Yes"
    
    tempvar tag_t tag_c
    quietly egen `tag_t' = tag(paper_numid) if group == 1 & e(sample)
    quietly count if `tag_t' == 1
    estadd scalar n_treat = r(N)
    
    quietly egen `tag_c' = tag(paper_numid) if group == 0 & e(sample)
    quietly count if `tag_c' == 1
    estadd scalar n_control = r(N)
    
    * --- 1.5 存储模型并准备输出宏 ---
    * 处理小数点：m015, m025 等
    local mname = subinstr("`t'", ".", "", .)
    est sto m`mname'
    
    * 拼接模型名
    local all_models "`all_models' m`mname'"
    
    * 拼接标题：0.1 标注为 Main
    if "`t'" == "0.1" {
        local all_mtitles `all_mtitles' "0.1(Main)"
    }
    else {
        local all_mtitles `all_mtitles' "`t'"
    }
}

* --- 2. 统一输出表格 ---
* 注意：由于列数极多（12-13列），建议在 Word 中将页面设为横向
esttab `all_models' using "Robustness_DOM_Table_Full.rtf", ///
    replace b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    drop(_cons author_year ref_year sef_year numretra_year) /// 
    label nogaps compress ///
    title("Table: Robustness Check across 13 DOM Thresholds") ///
    mtitle(`all_mtitles') ///
    stats(paper_fe year_fe age_fe n_treat n_control N r2_a, ///
          fmt(%s %s %s %9.0f %9.0f %9.0f %9.3f) ///
          labels("Paper FE" "Year FE" "Age FE" "Treated Papers" "Control Papers" "Observations" "Adj. R-squared"))	*/	  

**# Table4 稳健性2：DOM阈值扩大与缩小  
//=========================阈值0.4的稳健性检验========================//
cd "C:\Users\73627\Desktop\研二上\26.1.5改进\"
* 1. 定义所有阈值（已按从小到大排序，包含 0.07, 0.15, 0.25, 0.6, 0.7）
local thresholds "0.1 0.2 0.3 0.4 0.5 0.6 0.7"

* 初始化用于输出的宏
local all_models ""
local all_mtitles ""

* 清空存储的模型
est clear

foreach t in `thresholds' {
    * --- 1.1 导入数据 ---
    * 确保文件名与磁盘上的文件名完全匹配（例如 DOM_0.15_1x1_95to15.csv）
    capture import delimited "DOM_`t'_1x1_95to15.csv", clear
    if _rc != 0 {
        di as error "文件 DOM_`t'_1x1_95to15.csv 未找到，跳过此阈值。"
        continue
    }
    
    * --- 1.2 构造回归变量 ---
    quietly {
		gen log_author = log(1+numa)
		gen log_ref = log(1+numr)
		gen author_year = log_author * year/100
		gen ref_year = log_ref * year/100

		gen sef_year = selfretra*year/100
        gen age = year - pyear     // 论文年龄
        * t_ptor 虽然构造了，但如果回归没用到可以不用放在这，或者根据需要保留
        gen t_ptor = ryear - pyear 
    }

    * --- 1.3 运行标准回归 ---
    reghdfe log_yearlycitation did author_year ref_year sef_year , ///
            absorb(paper_numid year age) cluster(paper_numid)
    
    * --- 1.4 添加固定效应标识和个体统计量 ---
    estadd local paper_fe "Yes"
    estadd local year_fe  "Yes"
    estadd local age_fe   "Yes"
    
    tempvar tag_t tag_c
    quietly egen `tag_t' = tag(paper_numid) if group == 1 & e(sample)
    quietly count if `tag_t' == 1
    estadd scalar n_treat = r(N)
    
    quietly egen `tag_c' = tag(paper_numid) if group == 0 & e(sample)
    quietly count if `tag_c' == 1
    estadd scalar n_control = r(N)
    
    * --- 1.5 存储模型并准备输出宏 ---
    * 处理小数点：m015, m025 等
    local mname = subinstr("`t'", ".", "", .)
    est sto m`mname'
    
    * 拼接模型名
    local all_models "`all_models' m`mname'"
    
    * 拼接标题：0.1 标注为 Main
    if "`t'" == "0.4" {
        local all_mtitles `all_mtitles' "0.4(Main)"
    }
    else {
        local all_mtitles `all_mtitles' "`t'"
    }
}
label var did "Post-Retraction (DID)"
label var author_year "No. of authors (Trend)"
label var ref_year "No. of references (Trend)"
label var sef_year "Self-retraction (Trend)"
* --- 输出 Table 4 (多列横向模板) ---
esttab `all_models' using "Robustness_DOM_Table_Full.rtf", ///
    replace ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///  // 核心要求：*** 对应 0.001
    drop(_cons author_year ref_year sef_year) /// // 隐藏控制变量以节省横向空间
    label nogaps compress ///
    title("{\b Table 4.} Robustness check across different DOM thresholds") ///
    mtitle(`all_mtitles') ///
    nonumber ///
    stats(paper_fe year_fe age_fe n_treat n_control N r2_a, ///
          fmt(%s %s %s %9.0f %9.0f %9.0f %9.3f) /// // 整数 N 不带小数点
          labels("Paper FE" "Year FE" "Age FE" "Treated papers" "Control papers" "Observations" "Adj. R-squared")) ///
    addnotes("Note: Standard errors (in parentheses) are clustered at the paper level. This table examines the sensitivity of the baseline results across six different Degree of Matching (DOM) thresholds. All specifications include paper, year, and paper-age fixed effects. Time-varying controls (Author seniority, Ref. quality, and Self-retraction intensity) are included but not reported for brevity. * p < 0.05, ** p < 0.01, *** p < 0.001.")

**# Table5 稳健性3：实验组控制组比例扩大  
		  
*（b）实验组控制组1：N
* --- 0. 环境设置 ---
cd "C:\Users\73627\Desktop\研二上\26.1.5改进\"

* 定义匹配比例：1, 2, 3, 4
local ratios "1 2 3 4"

* 初始化用于输出的宏
local all_models ""
local all_mtitles ""

* 清空存储的模型
est clear

* --- 1. 循环运行回归 ---
foreach r in `ratios' {
    
    * 1.1 动态导入数据 (假设 DOM 阈值固定为 0.4)
    local filename "DOM_0.4_1x`r'_95to15.csv"
    capture import delimited "`filename'", clear
    
    if _rc != 0 {
        di as error "文件 `filename' 未找到，跳过此比例。"
        continue
    }
    
    * 1.2 构造回归变量
    quietly {
		gen log_author = log(1+numa)
		gen log_ref = log(1+numr)
		gen author_year = log_author * year/100
		gen ref_year = log_ref * year/100

		gen sef_year = selfretra*year/100
        gen age = year - pyear     // 论文年龄
    }

    * 1.3 运行双向固定效应回归
    reghdfe log_yearlycitation did author_year ref_year sef_year , ///
            absorb(paper_numid year age) cluster(paper_numid)
    
    * 1.4 添加统计量和标识
    estadd local paper_fe "Yes"
    estadd local year_fe  "Yes"
    estadd local age_fe   "Yes"
    
    * 统计处理组和控制组论文数量
    tempvar tag_t tag_c
    quietly egen `tag_t' = tag(paper_numid) if group == 1 & e(sample)
    quietly count if `tag_t' == 1
    estadd scalar n_treat = r(N)
    
    quietly egen `tag_c' = tag(paper_numid) if group == 0 & e(sample)
    quietly count if `tag_c' == 1
    estadd scalar n_control = r(N)
    
    * 1.5 存储模型
    est sto ratio_1x`r'
    local all_models "`all_models' ratio_1x`r'"
    
    * 拼接列标题
    if "`r'" == "1" {
        local all_mtitles `all_mtitles' "1:1(Main)"
    }
    else {
        local all_mtitles `all_mtitles' "1:`r'"
    }
}
label var did "Post-Retraction (DID)"
label var author_year "No. of authors (Trend)"
label var ref_year "No. of references (Trend)"
label var sef_year "Self-retraction (Trend)"
* --- 2. 统一输出表格 ---
* --- 2. 统一输出表格 ---
esttab `all_models' using "Robustness_Ratio_1x1_to_1x4.rtf", ///
    replace ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///  // 核心要求：*** 对应 0.001
    drop(_cons author_year ref_year sef_year) /// 
    label nogaps compress ///
    title("{\b Table 5.} Robustness check across different matching ratios (1:1 to 1:4)") ///
    mtitle(`all_mtitles') ///
    nonumber ///
    stats(paper_fe year_fe age_fe n_treat n_control N r2_a, ///
          fmt(%s %s %s %9.0f %9.0f %9.0f %9.3f) /// // 样本量 N 强制为整数
          labels("Paper FE" "Year FE" "Age FE" "Treated papers" "Control papers" "Observations" "Adj. R-squared")) ///
    addnotes("Note: Standard errors (in parentheses) are clustered at the paper level. This table examines the stability of the DID estimates as the matching ratio increases from 1:1 to 1:4. All models include paper, year, and paper-age fixed effects. Time-varying controls (Author seniority, Ref. quality, and Self-retraction intensity) are included but not reported for brevity. * p < 0.05, ** p < 0.01, *** p < 0.001.")


//============================（二）DID稳健性===============================//
**# Table6 稳健性4：安慰剂——提前年份
//======================（1）提前年份法安慰剂检验===========================//
* ==============================================================================
* 1. 运行基准回归 (不含 num_retra_year)
* ==============================================================================
reghdfe log_yearlycitation did author_year ref_year sef_year, ///
    absorb(paper_numid year age) cluster(paper_numid) 

* 统计样本内个体数
quietly {
    tempvar t1 c1
    egen `t1' = tag(paper_numid) if group == 1 & e(sample)
    count if `t1' == 1
    estadd scalar n_treat = r(N)
    egen `c1' = tag(paper_numid) if group == 0 & e(sample)
    count if `c1' == 1
    estadd scalar n_control = r(N)
}
estadd local paper_fe "Yes"
estadd local year_fe  "Yes"
estadd local age_fe   "Yes"
est store FE_age_YesCon


* ==============================================================================
* 2. 运行安慰剂回归 (提前 3年 )
* ==============================================================================
local lags "3"
foreach i in `lags' {
    * 生成虚假处理年份变量 (提前清理)
    cap drop ryear`i'
    cap drop did_placebo`i'
    
    gen ryear`i' = ryear - `i' if group == 1
    gen did_placebo`i' = (year >= ryear`i')
    replace did_placebo`i' = 0 if group == 0 | did_placebo`i' == .
    
    * 执行回归
    reghdfe log_yearlycitation did_placebo`i' author_year ref_year sef_year , ///
        absorb(paper_numid year age) cluster(paper_numid)
    
    * 统计样本内个体数
    quietly {
        tempvar t3 c3
        egen `t3' = tag(paper_numid) if group == 1 & e(sample)
        count if `t3' == 1
        estadd scalar n_treat = r(N)
        egen `c3' = tag(paper_numid) if group == 0 & e(sample)
        count if `c3' == 1
        estadd scalar n_control = r(N)
    }
    
    estadd local paper_fe "Yes"
    estadd local year_fe  "Yes"
    estadd local age_fe   "Yes"
    
    * 存储模型
    est store placebo_`i'
}
label var did "Post-Retraction (DID)"
label var author_year "No. of authors (Trend)"
label var ref_year "No. of references (Trend)"
label var sef_year "Self-retraction (Trend)"
* --- 2. 统一输出表格 ---
esttab FE_age_YesCon  placebo_3 using "Placebo_Test.rtf", ///
    replace ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///  // 核心要求：*** 对应 0.001
    label nogaps compress ///
    title("{\b Table 6.} Main results and placebo test") ///
    mtitle("(1)" "(2)") /// // 建议使用序号，在 Note 中解释含义
    rename(did_placebo1 did) ///  // 统一映射到 DID 行以便对比
    order(did author_year ref_year sef_year ) ///
    keep(did author_year ref_year sef_year did_placebo3) ///
    nonumber ///
    stats(paper_fe year_fe age_fe n_treat n_control N r2_a, ///
          fmt(%s %s %s %9.0f %9.0f %9.0f %9.3f) /// // 整数 N 不带小数点
          labels("Paper FE" "Year FE" "Age FE" "Treated papers" "Control papers" "Observations" "Adj. R-squared")) ///
    addnotes("Note: Standard errors (in parentheses) are clustered at the paper level. Column (1) reports the baseline DID estimate.  Column (2) performs a placebo test by artificially shifting the treatment time three year forward . * p < 0.05, ** p < 0.01, *** p < 0.001.")

**# Figure 稳健性5：安慰剂————事件研究法

//===========================（2）事件研究法=============================//
//生成相对时间值的虚拟变量，观测期-处理期
gen event = year - ryear if group == 1 //即只对处理组生成相对时间变量
tab event
//只保留前五期与后十期
replace event = -5 if event <= -5
replace event = 10 if event >= 10
tab event ,gen(eventz) //生成相对时间虚拟变量
forvalue i = 1/16{
         replace eventz`i' = 0 if (eventz`i' == 1 & group == 0)
} //将控制组的时间虚拟变量都变换为0
//设置基期
*drop eventz1 //将最早的一年作为基期
*drop eventz //事前第五期作为基期
drop eventz5 //事前一期作为基期
//Event回归（有控制变量）
reghdfe log_yearlycitation  eventz* ///
author_year ref_year sef_year   ///
, ///
absorb(paper_numid year age) cluster(paper_numid) level(95) 
//===========================绘图部分===========================//

coefplot, baselevels ///
  keep(eventz*) ///
  coeflabels( ///
    eventz1  = "-5" ///
    eventz2  = "-4" ///
    eventz3  = "-3" ///
    eventz4  = "-2" ///
    eventz5  = "-1" ///
    eventz6  = "0" ///
    eventz7  = "1"  ///
    eventz8  = "2"  ///
    eventz9  = "3"  ///
    eventz10 = "4"  ///
    eventz11 = "5"  ///
    eventz12 = "6"  ///
    eventz13 = "7"   /// 
    eventz14 = "8"   ///
    eventz15 = "9"   ///
    eventz16 = "10"   ///
  ) ///
  vertical ///
  yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ///
  ylabel(-0.2(0.1)0.2) ///
  xline(5, lwidth(vthin) lpattern(dash) lcolor(teal)) ///
  ytitle("Estimated Coefficients", size(small)) ///
  xtitle("Coefficient Estimates", size(small)) ///
  ///transform(*=@-r(mean)) ///
  addplot(line @b @at) ///
  ciopts(lpattern(dash) recast(rcap) msize(medium)) ///
  msymbol(circle_hollow) ///
  scheme(slmono)
 
**# Table7 稳健性6：安慰剂—— 混合虚构
//===================（3）混合虚构的安慰剂检验===================//
//记住基准回归的真实系数（-0.0317）
reghdfe log_yearlycitation did ///
author_year ref_year sef_year  , ///
absorb(paper_numid year age) cluster(paper_numid) 

//查看对照组和实验组中的个体数量
*ssc install distinct
bys group:distinct paper_numid
////////////////////////////////////循环运行///////////////////////////////////
mat b = J(500,1,0)
mat se = J(500,1,0)
mat p = J(500,1,0)
forvalues i=1/500{
	use"C:\Users\73627\Desktop\研二上\26.1.19改进\DOM_0.4_ConclusionInd_field3_jcr_highcita.dta",clear
	xtset paper_numid year
	gen age = year - pyear
	
	gen log_author = log(1+numa)
	gen log_ref = log(1+numr)
	gen author_year = log_author * year/100
	gen ref_year = log_ref * year/100
	
	gen sef_year = selfretra*year/100
	
	gen aaa = 1
	bys paper_numid:gen bbb=sum(aaa)
	sample 1 if bbb!=1, count by(paper_numid)
	drop if bbb==1
	sample 23288, count //这里要更改个体数
	keep paper_numid year
	rename year policy_year
	save 安慰剂抽取数据, replace
	merge 1:m paper_numid using "C:\Users\73627\Desktop\研二上\26.1.19改进\DOM_0.4_ConclusionInd_field3_jcr_highcita.dta"
	xtset paper_numid year
	gen group_aw = (_merge == 3)
	gen period = (year >= policy_year)
	gen did_A2 = group_aw*period
	gen age = year - pyear
	
	gen log_author = log(1+numa)
	gen log_ref = log(1+numr)
	gen author_year = log_author * year/100
	gen ref_year = log_ref * year/100
	gen sef_year = selfretra*year/100
	
	qui reghdfe log_yearlycitation did_A2 author_year ref_year sef_year , absorb(paper_numid year age) cluster(paper_numid) 
	mat b[`i',1] = _b[did_A2]
	mat se[`i',1] = _se[did_A2]
	mat p[`i',1] = 2*ttail(e(df_r),abs(_b[did_A2]/_se[did_A2]))
}
/////////////////////////////////生成系数及P值///////////////////////////////////
svmat b ,names(coef)
svmat se ,names(se)
svmat p ,names(pvalue)
drop if pvalue == .k
label var pvalue1 p值
label var coef1 估计系数
keep coef1 se1 pvalue1
//绘图
twoway (kdensity coef1 ,yaxis(2))(scatter pvalue1 coef1,msymbol(smcircle_hollow) mcolor(grey) yaxis(1)), ///
xlabel(-0.04(0.005)0.04,nogrid format(%4.2f)) ///
ytitle("p-value",orientation(horizontal) axis(1)) ///
ytitle("Kernel density",orientation(horizontal) axis(2)) ///
ylabel(0(0.1)1,nogrid axis(1) format(%7.1f) angle(0)) ///
ylabel(,axis(2) angle(0)) ///
xline(-0.0317, lwidth(vthin) lp(shortdash)) xtitle("Estimated coefficient") ///
yline(0.1, lwidth(vthin) lp(dash)) ytitle("p-value") ///
legend(label(1 "Kernel density") label(2 "p-value")) ///
plotregion(style(none)) ///
graphregion(color(white)) ///
saving(安慰剂检验图.png,replace)


// 绘图优化版
twoway (kdensity coef1, yaxis(2) lcolor(black) lwidth(medium)) ///
       (scatter pvalue1 coef1, msymbol(smcircle_hollow) mcolor(grey%50) yaxis(1)), ///
    /// 1. 调整横轴：缩小字体 (labsize) 并适当放宽刻度间距 (0.01)
    xlabel(-0.04(0.01)0.04, nogrid format(%4.2f) labsize(vsmall)) ///
    xtitle("Estimated Coefficient", size(small)) ///
    /// 2. 调整纵轴 (p-value)
    ytitle("p-value", axis(1) size(small)) ///
    ylabel(0(0.2)1, nogrid axis(1) format(%4.1f) angle(0) labsize(vsmall)) ///
    /// 3. 调整纵轴 (Kernel density)
    ytitle("Kernel Density", axis(2) size(small)) ///
    ylabel(, axis(2) angle(0) labsize(vsmall)) ///
    /// 4. 辅助线与标注
    xline(-0.0317, lwidth(vthin) lp(shortdash) lcolor(cranberry)) ///
    yline(0.1, lwidth(vthin) lp(dash) lcolor(black)) ///
    /// 5. 图例与整体风格
    legend(order(1 "Kernel Density" 2 "p-value") region(lstyle(none)) size(vsmall)) ///
    plotregion(style(none)) ///
    graphregion(color(white)) ///
    aspect(0.6) /// // 调整长宽比，拉长横轴也可以缓解拥挤
    name(placebo_test, replace)

// 导出高质量图片
graph export "Placebo_Distribution.pdf", replace

//安装命令
*ssc install dpplot
//画图：系数（需要离真实的系数很远）
dpplot coef1, xline(-0.,lp(dash)) xlabel(-0.2(0.1)0.1) xtitle("Placebo estimated coefficient") ytitle("Density") scheme(tufte) 
//画图：p值（需要大部分都大于0.1）
dpplot pvalue1, xtitle("Placebo p-value") ytitle("Density") scheme(tufte)

**# Table8 稳健性7：消除异质性处理效应
//=========================（4）异质性处理效应========================//
//（a）CSDID
*为了CSDID的gvar()做准备，将控制组的"政策年份"都设置为0
replace ryear = 0 if group == 0
csdid log_yearlycitation age ///
, ivar(paper_numid) time(year) gvar(ryear) 
//不同计算结果输出
* --- 1. 运行并存储原始结果 ---
estat simple

estat calendar

estat group

estat event


//=====================================================================//
//===========================异质性部分================================//
//=====================================================================//
**# 异质性1：参考文献的撤稿原因
//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX//	
//X==================异质性1：参考文献的撤稿原因=====================X//
//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX//
//异质性思路：
//1.细分原因（前30原因+其他）
//（1）交互项回归
//（2）分组回归
//2.删除与聚合
//（1）分组回归
//（2）交互项回归


**# 异质性1：参考文献的撤稿原因 Table1：细分原因分组回归
//（2）分组回归
//需要先设置反事实变量
//变量pair数值一样的实验组（group=1）与控制组（group=0）是一对的
//我需要对这些虚拟变量的控制组都赋予相同pair下实验组的值
//比如pair=1 下的实验组imagereuse_i 假如为1，那么pair=1下的控制组的imagereuse_i也赋值为1
//需要处理的虚拟变量序列：imagereuse_i //imagemanipulation_i //datafabrication_i //dataerror_i //redundantpublication_i //conclusionerror_i //imageerror_i //imagefabrication_i //analysiserror_i //methoderror_i //datareuse_i //irreproducible_i //textplagiarism_i //articleplagiarism_i //datamanipulation_i //automaticgeneration_i //unknownreason_i //noethicsapproval_i //textreuse_i //unspecifiedmisconduct_i //unauthorized_i //materialcontamination_i //imageplagiarism_i //materialerror_i //fakepeerreview_i //resultfabrication_i //dataplagiarism_i //authorshipdispute_i //inappropriatecitation_i //noinformedconsent_i //otherreason_i

* 为分组回归设置"反事实"原因虚拟变量
* 思路：在同一 pair 内，用实验组 (group==1) 的值赋给控制组 (group==0)
* 定义需要处理的原因变量（已移除 unknown 和 other）
* 定义剔除后的 29 个核心原因变量
* --- 1. 定义 29 个核心原因变量 (已剔除 Unknown 和 Other) ---
local reasons ///
    imagereuse_i imagemanipulation_i datafabrication_i dataerror_i ///
    redundantpublication_i conclusionerror_i imageerror_i imagefabrication_i ///
    analysiserror_i methoderror_i datareuse_i irreproducible_i ///
    textplagiarism_i articleplagiarism_i datamanipulation_i automaticgeneration_i ///
    noethicsapproval_i textreuse_i unspecifiedmisconduct_i unauthorized_i ///
    materialcontamination_i imageplagiarism_i materialerror_i fakepeerreview_i ///
    resultfabrication_i dataplagiarism_i authorshipdispute_i inappropriatecitation_i ///
    noinformedconsent_i

* --- 2. 继承逻辑：确保 Control 组拥有反事实特征 ---
foreach v of local reasons {
    bysort pair: egen __tmp_`v' = max(cond(group==1, `v', .))
    replace `v' = __tmp_`v' if group==0 & __tmp_`v' < .
    drop __tmp_`v'
}

capture estimates clear
local i = 1
foreach r of local reasons {
    di as txt "=== Running Subsample DID S`i' for reason: `r' ==="

    * 执行回归
    reghdfe log_yearlycitation did author_year ref_year sef_year if `r' == 1, ///
        absorb(paper_numid year age) cluster(paper_numid)

    * 统计 unique 论文数与分组样本量
    quietly {
        estadd scalar n_papers = e(N_clust)
        tempvar tag
        egen `tag' = tag(paper_numid) if e(sample)
        count if group == 1 & `tag' == 1
        estadd scalar treated_papers = r(N)
        count if group == 0 & `tag' == 1
        estadd scalar control_papers = r(N)
    }

    estimates store S`i'
    local ++i
}

* --- 重新定义标题 (关键：每个含空格的标题必须加引号) ---
local mt1 `" "Image Reuse" "Image Manip." "Data Fab." "Data Error" "Redundant Pub." "Concl. Error" "Image Error" "Image Fab." "Analysis Error" "Method Error" "'

local mt2 `" "Data Reuse" "Irreproducible" "Text Plag." "Article Plag." "Data Manip." "Auto. Gen." "Ethics Appr." "Text Reuse" "Unspec. Miscond." "Unauthorized" "'

local mt3 `" "Mat. Contam." "Image Plag." "Material Error" "Fake Peer Rev." "Result Fab." "Data Plag." "Author Dispute" "Inappr. Cite." "Informed Consent" "'

* --- 导出表 1 (以表 1 为例) ---
esttab S1 S2 S3 S4 S5 S6 S7 S8 S9 S10 using "Reason_Subsample_Part1x.rtf", replace ///
    title("{\b Table 8-1.} Subsample DID results by retraction reason (1-10)") ///
    keep(did) coeflabels(did "Post-retraction (DID)") ///
    b(%9.3f) ci(%9.3f) star(* 0.05 ** 0.01 *** 0.001) ///
    mtitle(`mt1') ///  // 这里的 mt1 已经是带引号的规范格式
    nonumber label nogap compress ///
    stats(treated_papers control_papers n_papers N r2_a, ///
          labels("Treated papers" "Control papers" "Unique papers" "Observations" "Adj. R-squared") ///
          fmt(%9.0f %9.0f %9.0f %9.0f %9.3f)) ///
    addnotes("Note: 95% confidence intervals in brackets. * p < 0.05, ** p < 0.01, *** p < 0.001.")

* --- 表 2：S11–S20 ---
esttab S11 S12 S13 S14 S15 S16 S17 S18 S19 S20 using "Reason_Subsample_Part2x.rtf", replace ///
    title("{\b Table 8-2.} Subsample DID results by retraction reason (Group 11-20)") ///
    keep(did) coeflabels(did "Post-retraction (DID)") ///
    b(%9.3f) ci(%9.3f) star(* 0.05 ** 0.01 *** 0.001) ///
    mtitle(`mt2') nonumber label nogap compress ///
    stats(treated_papers control_papers n_papers N r2_a, ///
          labels("Treated papers" "Control papers" "Unique papers" "Observations" "Adj. R-squared") ///
          fmt(%9.0f %9.0f %9.0f %9.0f %9.3f)) ///
    addnotes("Note: 95% confidence intervals in brackets. Standard errors are clustered at the paper level. * p < 0.05, ** p < 0.01, *** p < 0.001.")
* --- 表 3：S21–S29 ---
esttab S21 S22 S23 S24 S25 S26 S27 S28 S29 using "Reason_Subsample_Part3x.rtf", replace ///
    title("{\b Table 8-3.} Subsample DID results by retraction reason (Group 21-29)") ///
    keep(did) coeflabels(did "Post-retraction (DID)") ///
    b(%9.3f) ci(%9.3f) star(* 0.05 ** 0.01 *** 0.001) ///
    mtitle(`mt3') nonumber label nogap compress ///
    stats(treated_papers control_papers n_papers N r2_a, ///
          labels("Treated papers" "Control papers" "Unique papers" "Observations" "Adj. R-squared") ///
          fmt(%9.0f %9.0f %9.0f %9.0f %9.3f)) ///
    addnotes("Note: 95% confidence intervals in brackets. Standard errors are clustered at the paper level. * p < 0.05, ** p < 0.01, *** p < 0.001.")
	
//2.删除与聚合
//（1）分组回归
//（a）客观错误与失误 imagereuse_i imagemanipulation_i datafabrication_i dataerror_i conclusionerror_i imageerror_i imagefabrication_i analysiserror_i methoderror_i  irreproducible_i datamanipulation_i materialcontamination_i materialerror_i resultfabrication_i datareuse_i 

//（b）伦理与学术不端 articleplagiarism_i textreuse_i redundantpublication_i authorshipdispute_i unauthorized_i textplagiarism_i noethicsapproval_i dataplagiarism_i imageplagiarism_i unspecifiedmisconduct_i inappropriatecitation_i  automaticgeneration_i fakepeerreview_i noinformedconsent_i
* ==============================================================================
* 定义新的变量分组列表
* ==============================================================================
local group_a imagereuse_i imagemanipulation_i datafabrication_i dataerror_i ///
              conclusionerror_i imageerror_i imagefabrication_i analysiserror_i ///
              methoderror_i irreproducible_i datamanipulation_i ///
              materialcontamination_i materialerror_i resultfabrication_i datareuse_i

local group_b articleplagiarism_i  redundantpublication_i ///
              authorshipdispute_i unauthorized_i textplagiarism_i ///
              noethicsapproval_i dataplagiarism_i imageplagiarism_i ///
              unspecifiedmisconduct_i inappropriatecitation_i ///
              automaticgeneration_i fakepeerreview_i noinformedconsent_i  textreuse_i 

* ==============================================================================
* 预处理：生成组标识变量 (避免在 if 中使用复杂逻辑)
* ==============================================================================
gen byte is_group_a = 0
foreach v of local group_a {
    quietly replace is_group_a = 1 if `v' == 1
}

gen byte is_group_b = 0
foreach v of local group_b {
    quietly replace is_group_b = 1 if `v' == 1
}

* ==============================================================================
* 第一部分：回归 (a) 客观错误与失误
* ==============================================================================

* 1. 运行回归
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if is_group_a == 1, absorb(paper_numid year age) cluster(paper_numid)

* 2. 统计描述并存储
quietly {
    * 计算 Treated 和 Control 的数量
    preserve
        keep if is_group_a == 1
        bysort paper_numid: keep if _n == 1
        count if group == 1
        local N_tr_a = r(N)
        count if group == 0
        local N_co_a = r(N)
    restore
}
estadd scalar treated_papers = `N_tr_a'
estadd scalar control_papers = `N_co_a'
estadd scalar n_papers = e(N_clust)
estimates store GA

* ==============================================================================
* 第二部分：回归 (b) 伦理与学术不端
* ==============================================================================

* 1. 运行回归
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if is_group_b == 1, absorb(paper_numid year age) cluster(paper_numid)

* 2. 统计描述并存储
quietly {
    preserve
        keep if is_group_b == 1
        bysort paper_numid: keep if _n == 1
        count if group == 1
        local N_tr_b = r(N)
        count if group == 0
        local N_co_b = r(N)
    restore
}
estadd scalar treated_papers = `N_tr_b'
estadd scalar control_papers = `N_co_b'
estadd scalar n_papers = e(N_clust)
estimates store GB
* --- 1. 完善变量标签 ---
label var did "Post-retraction (DID)"

* --- 2. 定义大类列标题 (使用引号包裹以防空格错位) ---
local mt_groups `" "Tech./Data/Method" "Ethics/Text/Pub." "'

* ==============================================================================
* 第三部分：导出表格 (GA: 技术/数据/方法类; GB: 伦理/文本/出版类)
* ==============================================================================
esttab GA GB using "reason_groups_subsample_ab.rtf", replace ///
    title("{\b Table 9.} Subsample DID results by broad retraction categories") ///
    keep(did) ///
    coeflabels(did "Post-retraction (DID)") ///
    b(%9.3f) ci(%9.3f) ///  // 展示系数与置信区间
    star(* 0.05 ** 0.01 *** 0.001) /// // 核心要求：*** 对应 0.001
    mtitle(`mt_groups') ///
    nonumber label nogap compress ///
    stats(treated_papers control_papers n_papers N r2_a, ///
          labels("Treated papers" "Control papers" "Unique papers" "Observations" "Adj. R-squared") ///
          fmt(%9.0f %9.0f %9.0f %9.0f %9.3f)) /// // 整数格式
    addnotes("Note: 95% confidence intervals in brackets. Standard errors are clustered at the paper level. Column (1) includes categories related to technical, data, and methodological issues. Column (2) includes categories related to ethics, plagiarism, and publication process. * p < 0.05, ** p < 0.01, *** p < 0.001.")

* 清理临时分组变量
cap drop is_group_a is_group_b			 
			 
									 
**# 异质性2：论文领域 				 //XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX//			 
//X========================异质性2：论文领域=======================X//
//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXxx//
//由于情况比较复杂，所以有几个异质性层面
//.每个field_l0的异质性 ———— 交互项+分组回归
//.实验组论文的领域异质性（满足控制组不跨大学科的前提）———— 交互项+分组回归
//.是否小范围跨学科的论文 异质性（实验组论文与撤稿的参考文献综之间）———— 交互项+分组回归
//.是否大范围跨学科的论文 异质性（实验组论文与撤稿的参考文献综之间）———— 交互项+分组回归
//.敏感性测试：排除同期刊不同学科的实验组控制组对（field_consistent）————分组回归

**# 异质性2：论文领域————Table1：field_l0领域细分 分组回归（反事实）
/////////////////////////////////////////////////////////////////////////////////
///////////////////////////////1.field_l0领域细分////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
//一些预处理：
//逻辑基础： 对照组是通过期刊匹配找到的反事实（Counterfactual）。
//在 DID 框架下，对照组的作用是模拟"如果实验组论文没有被撤稿，它的引文轨迹会如何"。 //因此，对照组并不需要真的属于那个领域，它只需要表现得像那个领域的论文。
//操作：直接将实验组所属的 field_l0 赋予给同一 Pair 下的对照组（即 pair_id 级别的属性赋值）。

//合理解释：在事前引文趋势上已经匹配得很好了（Parallel Trend 成立），说明这个对照组论文在"吸引引文的能力"和"所处学术环境"上，与该领域的实验组论文是高度相似的。
//
* 定义你的领域变量列表
local fields "field_32 field_31 field_40 field_34 field_51 field_42 field_52 field_35 field_30 field_46 field_41 field_49 field_38 field_44 field_50 field_37 field_47 field_48 field_39 field_36 field_33 field_43"

* 循环处理每一个变量
foreach v of local fields {
    * 核心逻辑：在每一个 pair 内部，取该变量的最大值
    * 既然实验组是 1，对照组是 0，最大值就是 1
    bysort pair: egen new_`v' = max(`v')
    
    * 替换掉原变量（或者保留新变量 new_`v' 以便检查）
    replace `v' = new_`v'
    drop new_`v'
}

////////////////////////////////（1）分组回归////////////////////////////////////	 
* 1. 循环执行子样本回归 (Subsample DID by field)
*    现在同时存：实验组 / 控制组 论文个数（按 paper_numid 去重）
capture estimates clear

local fields ///
    field_32 field_31 field_40 field_34 field_51 field_42 field_52 field_35 ///
    field_30 field_46 field_41 field_49 field_38 field_44 field_50 field_37 ///
    field_47 field_48 field_39 field_36 field_33 field_43

local i = 1

foreach f of local fields {

    di as txt "=== 正在回归领域: `f' (Index: `i') ==="

    reghdfe log_yearlycitation ///
        did ///
        author_year ref_year sef_year ///
        if `f' == 1, ///
        absorb(paper_numid year age) ///
        cluster(paper_numid)

    * 1) 聚类后的 unique 论文数（领域内的 paper_numid）
    estadd scalar n_papers = e(N_clust)

    * 2) 该学科的总观测数（面板行数）
    estadd scalar n_obs = e(N)

    * 3) 统计该领域内的实验组 / 控制组 论文数（按 paper_numid 去重，且严格限定为估计样本）
    tempvar esample
    gen byte `esample' = e(sample)

    preserve
        keep if `esample' == 1      // 只保留本次回归的估计样本
        keep paper_numid group `f'  // 只保留需要的变量
        keep if `f' == 1            // 再保险：只保留该领域

        bysort paper_numid: keep if _n == 1

        quietly count if group == 1
        local N_treated = r(N)

        quietly count if group == 0
        local N_control = r(N)
    restore

    estadd scalar treated_papers = `N_treated'
    estadd scalar control_papers = `N_control'

    * 4) 存回归结果
    estimates store F`i'

    local ++i
}
*导出表格：F1–F11，F12–F22
*    同时展示 DID 系数 + 实验组/控制组论文数 + UniquePapers + Observations
* 2.1 第一批列标题（对应 F1–F11）
local ft1 ///
    "Biomedical_32" ///
    "Biological_31" ///
    "Engineering_40" ///
    "Chemical_34" ///
    "Physical_51" ///
    "Health_42" ///
    "Psychology_52" ///
    "Commerce_35" ///
    "Agricultural_30" ///
    "Information_46" ///
    "Environmental_41"

esttab F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 ///
    using "field_did_1_11.rtf", replace ///
    keep(did) ///
    coeflabels(did "DID") ///
    b(%9.3f) ci(%9.3f) ///
    stats(treated_papers control_papers n_papers n_obs, ///
          labels("TreatedPapers" "ControlPapers" "UniquePapers" "TotalObservations") ///
          fmt(%9.0f %9.0f %9.0f %9.0f)) ///
    nogap compress nonotes ///
    mtitle(`ft1') ///
    addnotes("95% confidence intervals in brackets.", ///
             "Treated/ControlPapers: unique paper_numid in the estimation sample (field_xx == 1).", ///
             "UniquePapers: number of distinct papers; TotalObservations: year-level observations.", ///
             "SEs clustered at paper_numid level.")

* 2.2 第二批列标题（对应 F12–F22）
local ft2 ///
    "Math_49" ///
    "Economics_38" ///
    "HumanSociety_44" ///
    "Philosophy_50" ///
    "Earth_37" ///
    "Language_47" ///
    "Law_48" ///
    "Education_39" ///
    "CreativeArts_36" ///
    "BuiltEnv_33" ///
    "History_43"

esttab F12 F13 F14 F15 F16 F17 F18 F19 F20 F21 F22 ///
    using "field_did_12_22.rtf", replace ///
    keep(did) ///
    coeflabels(did "DID") ///
    b(%9.3f) ci(%9.3f) ///
    stats(treated_papers control_papers n_papers n_obs, ///
          labels("TreatedPapers" "ControlPapers" "UniquePapers" "TotalObservations") ///
          fmt(%9.0f %9.0f %9.0f %9.0f)) ///
    nogap compress nonotes ///
    mtitle(`ft2') ///
    addnotes("Each column reports the DID estimate within that field subsample (field_xx == 1).", ///
             "Treated/ControlPapers: unique paper_numid in the estimation sample.", ///
             "UniquePapers: number of distinct papers; TotalObservations: year-level observations.", ///
             "SEs clustered at paper_numid level.")

**# 异质性2：论文领域————Table2：field_l0领域细分 分组回归（不反事实——稳健性检验）		
/////////////////////////////（2）分组回归稳健性////////////////////////////////
//面板数据中field依旧是真实的领域对应变量
//field取值从30到51 对应各个field_l0的学科
//现在我需要做个分组回归的稳健性回归
//即现在我需要回归在同一pair下，实验组（group=1）控制组（group=0）field_l0相同的的个体
//即同时满足pair相同且field_l0相同的个体才可以纳入回归
* --- 1.1 精准领域匹配筛选 ---
bysort pair: egen f_treat = max(cond(group==1, field, .))
gen is_field_match = (field == f_treat)
bysort pair: egen is_pure_pair = min(is_field_match)

* --- 1.2 自动化回归并按顺序存储为 F1-F22 ---
eststo clear

local list1 "32 31 40 34 51 42 52 35 30 46 41"
local list2 "49 38 44 50 37 47 48 39 36 33 43"

local i = 1
foreach f in `list1' `list2' {
    
    * 检查该领域是否有足够的精准匹配样本，避免报错中断
    quietly count if is_pure_pair == 1 & field == `f' & group == 1
    if r(N) > 5 {
        
        reghdfe log_yearlycitation did author_year ref_year sef_year ///
            if is_pure_pair == 1 & field == `f', ///
            absorb(paper_numid year age) cluster(paper_numid)
        
        * --- 修复后的统计量提取 ---
        * 1. 提取当前回归样本中的唯一实验组和控制组论文数
        quietly count if e(sample) & group == 1 & year == 2010 // 选一个年份截面统计数量，避免重复计数
        if r(N) == 0 quietly count if e(sample) & group == 1 // 如果年份不匹配，则回退到基础统计
        
        * 稳健的方法：利用 distinct 命令 (需 ssc install distinct) 或以下逻辑
        preserve
            keep if e(sample)
            keep paper_numid group
            duplicates drop
            
            quietly count if group == 1
            local t_count = r(N)
            quietly count if group == 0
            local c_count = r(N)
            local total_p = `t_count' + `c_count'
        restore
        
        estadd scalar treated_papers = `t_count'
        estadd scalar control_papers = `c_count'
        estadd scalar n_papers = `total_p'
        estadd scalar n_obs = e(N)
        
        eststo F`i'
    }
    else {
        * 如果样本太少无法回归，创建一个空模型占位，防止 esttab 错位
        quietly reg log_yearlycitation did if 0
        estadd scalar treated_papers = 0
        eststo F`i'
    }
    local ++i
}

* --- 2. 导出表格 (保持你之前的格式设置) ---

* 第一批 F1-F11
local ft1 "Biomedical_32" "Biological_31" "Engineering_40" "Chemical_34" "Physical_51" "Health_42" "Psychology_52" "Commerce_35" "Agricultural_30" "Information_46" "Environmental_41"

esttab F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 ///
    using "field_robust_1_11.rtf", replace ///
    keep(did) coeflabels(did "DID") b(%9.3f) ci(%9.3f) ///
    stats(treated_papers control_papers n_papers n_obs, ///
          labels("TreatedPapers" "ControlPapers" "UniquePapers" "TotalObservations") ///
          fmt(%9.0f %9.0f %9.0f %9.0f)) ///
    nogap compress nonotes mtitle(`ft1') ///
    addnotes("95% confidence intervals in brackets." "Strict field match within pairs.")

* 第二批 F12-F22
local ft2 "Math_49" "Economics_38" "HumanSociety_44" "Philosophy_50" "Earth_37" "Language_47" "Law_48" "Education_39" "CreativeArts_36" "BuiltEnv_33" "History_43"

esttab F12 F13 F14 F15 F16 F17 F18 F19 F20 F21 F22 ///
    using "field_robust_12_22.rtf", replace ///
    keep(did) coeflabels(did "DID") b(%9.3f) ci(%9.3f) ///
    stats(treated_papers control_papers n_papers n_obs, ///
          labels("TreatedPapers" "ControlPapers" "UniquePapers" "TotalObservations") ///
          fmt(%9.0f %9.0f %9.0f %9.0f)) ///
    nogap compress nonotes mtitle(`ft2')

/////////////////////////////////////////////////////////////////////
////////////////////////2.实验组论文的大领域异质性/////////////////////
/////////////////////////////////////////////////////////////////////
**# 异质性2：论文领域 Table3————三大领域交互项回归（设定反事实变量）	

//我希望先将同一pair下的控制组（group=0）的bigfield1 bigfield2 bigfield3 值都赋值成该pair下实验组（group=1）的值
//然后控制组的bigfield1 bigfield2 bigfield3 即可以作为同pair下实验组的反事实变量
//之后直接运行三个回归，得到分组回归结果
* --- 1. 反事实赋值逻辑：将实验组领域特征赋予同 pair 控制组 ---
foreach v of varlist bigfield1 bigfield2 bigfield3 {
    bysort pair: egen `v'_new = max(`v')
    replace `v' = `v'_new
    drop `v'_new
}

//交互项估计
* 三大学科异质性：DID × Bigfield1–3
* 已有 bigfield1 bigfield2 bigfield3 ∈ {0,1}
capture estimates clear

* 三个大领域（你可按自己的定义改注释）：
* (1) 领域1: bigfield1
* (2) 领域2: bigfield2
* (3) 领域3: bigfield3

local bigs ///
    bigfield1 ///
    bigfield2 ///
    bigfield3

local i = 1
foreach b of local bigs {

    di as txt "=== Running model M`i' for `b' ==="

    * 1) 异质性交互回归
    reghdfe log_yearlycitation ///
        c.did##c.`b' ///
        author_year ref_year sef_year  ///
        , absorb(paper_numid year age) ///
          cluster(paper_numid)

    * 2) 聚类后的 unique 论文数
    estadd scalar n_papers = e(N_clust)

    * 3) 统计该大学科 (bigfield==1) 的实验组 / 控制组论文数（按 paper_numid 去重）
    preserve
        keep paper_numid group `b'
        keep if `b' == 1

        bysort paper_numid: keep if _n == 1

        quietly count if group == 1
        local N_treated = r(N)

        quietly count if group == 0
        local N_control = r(N)
    restore

    estadd scalar treated_papers = `N_treated'
    estadd scalar control_papers = `N_control'

    * 4) 存回归结果
    estimates store M`i'

    local ++i
}

* 输出表格：三列，对应三大学科
* --- 1. 定义学科列标题 (使用复合双引号防止空格导致错位) ---
local mtitles `" "Life Sci. & Health" "Physical Sci. & Eng." "Social Sci. & Hum." "'

* --- 2. 定义交互项的统一显示标签 ---
* 假设您的交互项在回归中生成为 c.did#c.bigfield1 等
local coefmap ///
    c.did#c.bigfield1 "Post-retraction (DID) × Field" ///
    c.did#c.bigfield2 "Post-retraction (DID) × Field" ///
    c.did#c.bigfield3 "Post-retraction (DID) × Field"
* ==============================================================================
* 导出表格：展示三大学科的异质性交互项结果
* ==============================================================================
esttab M1 M2 M3 using "bigfield_heterogeneity_3fields2.rtf", replace ///
    title("{\b Table 10.} Heterogeneity analysis by broad scientific fields") ///
    keep(c.did#c.bigfield*) ///   // 仅保留交互项
    coeflabels(`coefmap') ///      // 统一命名为一行
    b(%9.3f) ci(%9.3f) ///         // 展示系数与置信区间
    star(* 0.05 ** 0.01 *** 0.001) /// // 核心要求：*** 对应 0.001
    mtitle(`mtitles') ///          // 学科大类标题
    nonumber label nogap compress ///
    stats(treated_papers control_papers n_papers N r2_a, ///
          labels("Treated papers" "Control papers" "Unique papers" "Observations" "Adj. R-squared") ///
          fmt(%9.0f %9.0f %9.0f %9.0f %9.3f)) /// // 样本量强制为整数
    addnotes("Note: 95% confidence intervals in brackets. Standard errors are clustered at the paper level. The independent variable is the interaction between Post-retraction (DID) and the respective scientific field dummy. All models include paper, year, and paper-age fixed effects. * p < 0.05, ** p < 0.01, *** p < 0.001.")
//3.29
* # 异质性2：论文领域 - 两大类分组回归（第一类 vs. 第二三类合并）
* 注：合并了 Physical Sciences (2) 和 Social Sciences (3)

capture estimates clear

* 我们手动跑两次回归，不再用简单的 1/3 循环，以便清晰定义合并逻辑
local groups "1 23"  // 定义两个标识符：1 代表第一类，23 代表合并类

foreach k in `groups' {
    
    * 定义当前循环的条件
    if "`k'" == "1" {
        local cond "bigfield == 1"
        local tlabel "Life Sciences"
    }
    else {
        local cond "(bigfield == 2 | bigfield == 3)"
        local tlabel "Phys/Eng & SocSci"
    }

    di as txt "=== Running subsample DID for `tlabel' (field_consistent == 1) ==="

    * 执行回归
    reghdfe log_yearlycitation ///
        did ///
        author_year ref_year sef_year ///
        if `cond' & field_consistent == 1, ///
        absorb(paper_numid year age) ///
        cluster(paper_numid)

    * 统计 unique 论文数
    estadd scalar n_papers = e(N_clust)

    * 计算实验组/控制组数量（去重统计）
    preserve
        keep if `cond' & field_consistent == 1
        bysort paper_numid: keep if _n == 1

        quietly count if group == 1
        local N_treated = r(N)

        quietly count if group == 0
        local N_control = r(N)
    restore

    estadd scalar treated_papers = `N_treated'
    estadd scalar control_papers = `N_control'

    * 存储结果，命名为 M1 和 M23
    estimates store M`k'
}

* --- 输出表格 ---

local mtitles "Life Sciences & Health" "Physical/Social/Other"

esttab M1 M23 using "bigfield_combined_results.rtf", replace ///
    title("Table: Subsample DID Results (Combined Fields 2 & 3)") ///
    keep(did) ///
    coeflabels(did "DID") ///
    b(%9.3f) ci(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    stats(treated_papers control_papers n_papers N, ///
          labels("Treated Papers" "Control Papers" "Unique Papers" "Observations") ///
          fmt(%9.0f %9.0f %9.0f %9.0f)) ///
    nogap compress nonotes ///
    mtitle(`mtitles') ///
    addnotes("Note: Column 1 covers Life Sciences (Group 1)." ///
             "Column 2 combines Physical Sciences (Group 2) and Social Sciences (Group 3)." ///
             "All models restrict to field_consistent == 1." ///
             "SEs clustered at paper_numid level.")

**# 异质性2：论文领域 Table8————实际上是"稳健性"敏感性测试 		
///////////////////////////////////////////////////////////////////////////////////
/////////4.敏感性测试：排除同期刊不同学科的实验组控制组对（field_consistent）//////
///////////////////////////////////////////////////////////////////////////////////	 
* 清空存储
eststo clear
*基准回归 (Baseline) ---
eststo baseline: reghdfe log_yearlycitation did author_year ref_year sef_year, ///
    absorb(paper_numid year age) cluster(paper_numid) 

* 统计文章数并强制转换为字符串存储
cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
local nt = string(`r(N)')  // 转换为字符串
estadd local n_treated "`nt'"

quietly count if group == 0 & tag == 1
local nc = string(`r(N)')  // 转换为字符串
estadd local n_control "`nc'"


*敏感性测试 (Robustness) ---
eststo robust: reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if field_consistent == 1, absorb(paper_numid year age) cluster(paper_numid)

* 统计文章数并强制转换为字符串存储
cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
local nt = string(`r(N)')
estadd local n_treated "`nt'"

quietly count if group == 0 & tag == 1
local nc = string(`r(N)')
estadd local n_control "`nc'"


* --- 1. 完善变量标签定义 ---
label var did "Post-retraction (DID)"
label var author_year "Author seniority (Trend)"
label var ref_year "Ref. quality (Trend)"
label var sef_year "Self-retraction (Trend)"

* --- 2. 导出标准化表格 (修复 Type Mismatch) ---
* 使用复合双引号 `" "` 处理标题和备注，确保 RTF 兼容性
local mtitles `" "Full Sample" "Field Consistent Only" "'

esttab baseline robust using Sensitivity_Consistency.rtf, replace ///
    title("{\b Table 11.} Sensitivity analysis: Impact of field consistency") ///
    keep(did author_year ref_year sef_year) ///
    coeflabels(did "Post-retraction (DID)") ///
    b(%9.3f) ci(%9.3f) ///         // 统一展示系数与置信区间 (CI)
    star(* 0.05 ** 0.01 *** 0.001) /// // 核心标准：*** 对应 0.001
    mtitle(`mtiles') ///
    nonumber label nogap compress ///
    stats(n_treated n_control n_papers N r2_a, ///
          labels("Treated papers" "Control papers" "Unique papers" "Observations" "Adj. R-squared") ///
          fmt(%9.0f %9.0f %9.0f %9.0f %9.3f)) /// // 样本量强制为整数
    addnotes("Note: 95% confidence intervals in brackets. Standard errors are clustered at the paper level. Column (1) includes the full matched sample. Column (2) restricts the analysis to matched pairs where the treated and control papers belong to the same broad scientific field to ensure cross-field consistency. * p < 0.05, ** p < 0.01, *** p < 0.001.")


**# 异质性2：论文领域 Table7————是否小范围跨学科引用：						 ///////////////////////////////////////////////////////////////////////////////////
////////////3.是否小范围跨学科的论文（实验组论文与撤稿的参考文献综之间）///////////	
///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////（1）分组回归：////////////////////////////////////
// 跨二级学科引用 (Cross-Field: Small) ---
sum crossfield_small ,detail
replace crossfield_small = . if crossfield_small == -1

reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if crossfield_small == 1, absorb(paper_numid year age) cluster(paper_numid) 

* 统计文章数
cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated `r(N)'
quietly count if group == 0 & tag == 1
estadd local n_control `r(N)'
eststo s1

// 同二级学科引用 (Within-Field: Small) ---
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if crossfield_small == 0, absorb(paper_numid year age) cluster(paper_numid)

* 统计文章数
cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated `r(N)'
quietly count if group == 0 & tag == 1
estadd local n_control `r(N)'
eststo s0

* --- 1. 完善变量标签 ---
label var did "Post-retraction (DID)"
label var author_year "Author seniority (Trend)"
label var ref_year "Ref. quality (Trend)"
label var sef_year "Self-retraction (Trend)"		 
			 
* --- 2. 定义列标题 (使用复合双引号) ---
local mt_small `" "Cross-Field (Small)" "Within-Field (Small)" "'

* --- 3. 导出表格 ---
esttab s1 s0 using Heterogeneity_Crossfield_Small.rtf, replace ///
    title("{\b Table 19.} Heterogeneity by knowledge boundary (Sub-field level)") ///
    keep(did author_year ref_year sef_year) ///
    coeflabels(did "Post-retraction (DID)") ///
    b(%9.3f) se(%9.3f) ///         // 核心修改：使用标准误 (SE)，移除置信区间
    star(* 0.05 ** 0.01 *** 0.001) /// // 核心要求：*** 对应 0.001
    mtitle(`mt_small') ///         // 分组标题
    mgroups("Dependent Variable: Log(Annual citations + 1)", pattern(1 0) prefix(\line\em ) span) ///
    nonumber label nogap compress ///
    stats(n_treated n_control n_papers N r2_a, ///
          labels("Treated papers" "Control papers" "Unique papers" "Observations" "Adj. R-squared") ///
          fmt(%9.0f %9.0f %9.0f %9.0f %9.3f)) /// // 样本量强制为整数
    addnotes("Note: Standard errors (in parentheses) are clustered at the paper level." ///
             "Cross-Field indicates pairs where the paper and its cited retracted reference belong to different sub-fields." ///
             "Within-Field indicates pairs belonging to the same sub-field." ///
             "* p < 0.05, ** p < 0.01, *** p < 0.001.")			 
			 

			 
**# 异质性4：JCR分区RJCR分区以及作者的声誉水平
			 
//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX//			 //X====================异质性4：JCR分区与RJCR分区==================X//	
//X========================以及作者的声誉水平======================X//	
//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX//		 

//1.实验组控制组JCR分区的异质性
//2.参考文献JCR分区的异质性
//3.rjcr_better 参考文献分区是否更好 异质性
//4.jcr_distance 论文与参考文献jcr分区差异的大小 异质性
//===================================================================//


**# 异质性4：JCR分区 Table1:实验组控制组JCR分区异质性（分组回归）
//1.实验组控制组JCR分区的异质性
//（1）分组回归
* 执行回归并存储结果 
//回归 1: JCR Q1 
/*reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if jcr == 1, absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
local nt = string(`r(N)')
estadd local n_treated "`nt'"
quietly count if group == 0 & tag == 1
local nc = string(`r(N)')
estadd local n_control "`nc'"
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_jcr1

// --- 回归 2: JCR Q2-Q4 ---
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if jcr <= 4 & jcr > 1, absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
local nt = string(`r(N)')
estadd local n_treated "`nt'"
quietly count if group == 0 & tag == 1
local nc = string(`r(N)')
estadd local n_control "`nc'"
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_jcr24

// --- 回归 3: Other ---
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if jcr == 5, absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
local nt = string(`r(N)')
estadd local n_treated "`nt'"
quietly count if group == 0 & tag == 1
local nc = string(`r(N)')
estadd local n_control "`nc'"
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_jcr5


label var did "Post-retraction (DID)"
label var author_year "Author seniority (Trend)"
label var ref_year "Ref. quality (Trend)"
label var sef_year "Self-retraction (Trend)"
* 使用复合双引号定义标题
local mt_jcr `" "JCR Q1" "JCR Q2-Q4" "Other Journals" "'

esttab m_jcr1 m_jcr24 m_jcr5 using JCR_Heterogeneity_Results.rtf, replace ///
    title("{\b Table 12.} Heterogeneity analysis by journal quality (JCR Quartiles)") ///
    keep(did author_year ref_year sef_year) ///
    coeflabels(did "Post-retraction (DID)") ///
    b(%9.3f) se(%9.3f) ///         // 核心修改：使用标准误 (SE)
    star(* 0.05 ** 0.01 *** 0.001) /// 
    mtitle(`mt_jcr') ///
    nonumber label nogap compress ///
    stats(n_treated n_control n_papers N r2_a, ///
          labels("Treated papers" "Control papers" "Unique papers" "Observations" "Adj. R-squared") ///
          fmt(%9.0f %9.0f %9.0f %9.0f %9.3f)) ///
    addnotes("Note: The dependent variable is Log(Annual citations + 1). Standard errors (in parentheses) are clustered at the paper level. JCR categories are based on the journal ranking at the year of publication. * p < 0.05, ** p < 0.01, *** p < 0.001.")
*/
*# 异质性4：JCR分区 Table1: 实验组控制组JCR分区异质性（分组回归）
// 1. 实验组控制组JCR分区的异质性
// （1）分组回归

* --- 回归 1: JCR Q1 ---
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if jcr == 1, absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
local nt = string(`r(N)')
estadd local n_treated "`nt'"
quietly count if group == 0 & tag == 1
local nc = string(`r(N)')
estadd local n_control "`nc'"
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_jcr_q1

* --- 回归 2: 其他 (JCR Q2-Q4 & Other) ---
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if jcr > 1, absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
local nt = string(`r(N)')
estadd local n_treated "`nt'"
quietly count if group == 0 & tag == 1
local nc = string(`r(N)')
estadd local n_control "`nc'"
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_jcr_others

* 变量标签与表格输出
label var did "Post-retraction (DID)"
label var author_year "Author seniority (Trend)"
label var ref_year "Ref. quality (Trend)"
label var sef_year "Self-retraction (Trend)"

* 定义两列的标题
local mt_jcr `" "JCR Q1" "Other Journals" "'

esttab m_jcr_q1 m_jcr_others using JCR_Heterogeneity_Results.rtf, replace ///
    title("{\b Table 12.} Heterogeneity analysis by journal quality (JCR Q1 vs. Others)") ///
    keep(did author_year ref_year sef_year) ///
    coeflabels(did "Post-retraction (DID)") ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    mtitle(`mt_jcr') ///
    nonumber label nogap compress ///
    stats(n_treated n_control N r2_a, ///
          labels("Treated papers" "Control papers" "Observations" "Adj. R-squared") ///
          fmt(%9.0f %9.0f %9.0f %9.3f)) ///
    addnotes("Note: The dependent variable is Log(Annual citations + 1). Standard errors (in parentheses) are clustered at the paper level. 'Other Journals' includes JCR Q2-Q4 and non-indexed journals. * p < 0.05, ** p < 0.01, *** p < 0.001.")			 
			 
/**# 异质性4：RJCR分区 Table3:撤稿论文JCR分区异质性（分组回归）				 
			 //2.参考文献JCR分区的异质性
//（1）分组回归
* 执行回归并存储结果 
// 组别 1: rjcr Q1 (引用的文献水平极高)
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if rjcr == 1, absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
local nt = string(`r(N)')
estadd local n_treated "`nt'"
quietly count if group == 0 & tag == 1
local nc = string(`r(N)')
estadd local n_control "`nc'"
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_rjcr1

//组别 2: rjcr Q2-Q4 (引用的文献水平中等) 
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if rjcr <= 4 & rjcr > 1, absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
local nt = string(`r(N)')
estadd local n_treated "`nt'"
quietly count if group == 0 & tag == 1
local nc = string(`r(N)')
estadd local n_control "`nc'"
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_rjcr24

// --- 组别 3: rjcr 其他 (引用的文献水平较低或未分类) ---
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if rjcr == 5, absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
local nt = string(`r(N)')
estadd local n_treated "`nt'"
quietly count if group == 0 & tag == 1
local nc = string(`r(N)')
estadd local n_control "`nc'"
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_rjcr5


* --- 1. 完善变量标签 ---
label var did "Post-retraction (DID)"
label var author_year "Author seniority (Trend)"
label var ref_year "Ref. quality (Trend)"
label var sef_year "Self-retraction (Trend)"

* --- 2. 定义列标题 (使用复合双引号防止空格错位) ---
local mt_rjcr `" "rJCR Q1" "rJCR Q2-Q4" "Other Journals" "'

* --- 3. 导出表格 ---
esttab m_rjcr1 m_rjcr24 m_rjcr5 using rJCR_Heterogeneity_Results.rtf, replace ///
    title("{\b Table 13.} Heterogeneity analysis by quality of referenced journals (rJCR)") ///
    keep(did author_year ref_year sef_year) ///
    coeflabels(did "Post-retraction (DID)") ///
    b(%9.3f) se(%9.3f) ///         // 核心修改：使用标准误 (SE)，不要置信区间
    star(* 0.05 ** 0.01 *** 0.001) /// // 核心要求：*** 对应 0.001
    mtitle(`mt_rjcr') ///
    nonumber label nogap compress ///
    stats(n_treated n_control n_papers N r2_a, ///
          labels("Treated papers" "Control papers" "Unique papers" "Observations" "Adj. R-squared") ///
          fmt(%9.0f %9.0f %9.0f %9.0f %9.3f)) /// // 样本量强制为整数
    addnotes("Note: The dependent variable is Log(Annual citations + 1)." ///
             "Standard errors (in parentheses) are clustered at the paper level." ///
             "rJCR refers to the JCR quartile of the journals cited by the paper." ///
             "* p < 0.05, ** p < 0.01, *** p < 0.001.")			 
*/
*# 异质性4：RJCR分区 Table3: 撤稿论文JCR分区异质性（分组回归）
// 2. 参考文献JCR分区的异质性
// （1）分组回归

* --- 执行回归并存储结果 ---

// 组别 1: rjcr Q1 (引用的文献水平极高)
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if rjcr == 1, absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
local nt = string(`r(N)')
estadd local n_treated "`nt'"
quietly count if group == 0 & tag == 1
local nc = string(`r(N)')
estadd local n_control "`nc'"
quietly count if tag == 1
local np = string(`r(N)')
estadd local n_papers "`np'"
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_rjcr_q1

// 组别 2: rjcr Others (引用的文献水平中等及以下，包含Q2-Q4及其他) 
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if rjcr > 1, absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
local nt = string(`r(N)')
estadd local n_treated "`nt'"
quietly count if group == 0 & tag == 1
local nc = string(`r(N)')
estadd local n_control "`nc'"
quietly count if tag == 1
local np = string(`r(N)')
estadd local n_papers "`np'"
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_rjcr_others


* --- 1. 完善变量标签 ---
label var did "Post-retraction (DID)"
label var author_year "Author seniority (Trend)"
label var ref_year "Ref. quality (Trend)"
label var sef_year "Self-retraction (Trend)"

* --- 2. 定义列标题 ---
local mt_rjcr `" "rJCR Q1" "Other Journals" "'

* --- 3. 导出表格 ---
esttab m_rjcr_q1 m_rjcr_others using rJCR_Heterogeneity_Results.rtf, replace ///
    title("{\b Table 13.} Heterogeneity analysis by quality of referenced journals (rJCR)") ///
    keep(did author_year ref_year sef_year) ///
    coeflabels(did "Post-retraction (DID)") ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    mtitle(`mt_rjcr') ///
    nonumber label nogap compress ///
    stats(n_treated n_control n_papers N r2_a, ///
          labels("Treated papers" "Control papers" "Unique papers" "Observations" "Adj. R-squared") ///
          fmt(%9.0f %9.0f %9.0f %9.0f %9.3f)) ///
    addnotes("Note: The dependent variable is Log(Annual citations + 1)." ///
             "Standard errors (in parentheses) are clustered at the paper level." ///
             "rJCR refers to the JCR quartile of the journals cited by the paper. 'Other Journals' includes rJCR Q2-Q5." ///
             "* p < 0.05, ** p < 0.01, *** p < 0.001.")			 
			 

//===================异质性：冲击年作者的高引论文数======================//
//1.实验组作者 前10%top论文数 num_top10max num_top10mean
//2.撤稿论文作者 前10%top论文数 rnum_top10max rnum_top10mean
//拓展：
//顶级文章数量：
//3.实验组作者 前1%top论文数 num_top1max num_top1mean
//4.撤稿论文作者 前1%top论文数 rnum_top1max rnum_top1mean
//5%高引文章数：
//5.实验组作者 前5%top论文数 num_top5max num_top5mean
//6.撤稿论文作者 前5%top论文数 rnum_top5max rnum_top5mean
//========================================================================//
//决定先只看前10%，这个大家的论文数都多一些，能看出更普适的规律
//之后再缩小到5%以及1%的高引文论文数，进行结论的深挖
**# 异质性4：作者声誉——目标论文作者MAX声誉（分组回归）
//1.实验组作者 前10%top论文数 num_top10max num_top10mean
//=========================================================================//
////////////////* --- (1a) num_top10max 异质性分析 ---///////////////////////
//=========================================================================//
///////////////////////////////////分组回归//////////////////////////////////
summarize num_top10max, detail //分位数判断
//8，22，52，1276
eststo clear

// Group 1: [0, 8]
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if num_top10max >= 0 & num_top10max <= 8, absorb(paper_numid year age) cluster(paper_numid)
cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_max_q1

// Group 2: (8, 22]
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if num_top10max > 8 & num_top10max <= 22, absorb(paper_numid year age) cluster(paper_numid)
cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_max_q2

// Group 3: (22, 52]
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if num_top10max > 22 & num_top10max <= 52, absorb(paper_numid year age) cluster(paper_numid)
cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_max_q3

// Group 4: > 52
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if num_top10max > 52, absorb(paper_numid year age) cluster(paper_numid)
cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m_max_q4

* --- 1. 确保变量标签简洁（防止标题被拉宽） ---
label var did "Post-retraction (DID)"
label var author_year "Author seniority (Trend)"
label var ref_year "Ref. quality (Trend)"
label var sef_year "Self-retraction (Trend)"

* --- 2. 定义分位数标题（使用复合双引号） ---
local mt_top10 `" "Q1: 0-8" "Q2: 8-22" "Q3: 22-52" "Q4: >52" "'

* --- 3. 导出表格 ---
esttab m_max_q1 m_max_q2 m_max_q3 m_max_q4 using Table_Top10Max_Hetero.rtf, replace ///
    title("{\b Table 14.} Heterogeneity by author's maximum Top 10% paper count") ///
    keep(did author_year ref_year sef_year) ///
    coeflabels(did "Post-retraction (DID)") ///
    b(%9.3f) se(%9.3f) ///         
    star(* 0.05 ** 0.01 *** 0.001) /// 
    mtitle(`mt_top10') ///          // 强制使用自定义分位数标题
    mgroups("Dependent Variable: Log(Annual citations + 1)", pattern(1 0 0 0) prefix(\line\em ) span) /// // 在标题上方增加说明
    nonumber label nogap compress ///
    stats(n_treated n_control n_papers N r2_a, ///
          labels("Treated papers" "Control papers" "Unique papers" "Observations" "Adj. R-squared") ///
          fmt(%9.0f %9.0f %9.0f %9.0f %9.3f)) /// 
    addnotes("Note: Standard errors (in parentheses) are clustered at the paper level." ///
             "Quartiles are based on the maximum number of Top 10% papers among all authors of the paper." ///
             "* p < 0.05, ** p < 0.01, *** p < 0.001.")
* --- 2. 定义分位数标题 (Q1-Q4) ---
local mt_top10 `" "Q1: 0-8" "Q2: 8-22" "Q3: 22-52" "Q4: >52" "'




**# 异质性4：作者声誉——目标论文作者MAX声誉（交互回归）
	/////////////////////////////////////交互项回归///////////////////////////////////////

* 交互项版本：验证 num_top10max (分位数区间) 异质性的显著性差异


* 根据分位数生成分类哑变量 (Categorical Variable)
cap drop max_cat
gen max_cat = .
replace max_cat = 1 if num_top10max >= 0 & num_top10max <= 8   // Q1
replace max_cat = 2 if num_top10max > 8  & num_top10max <= 22  // Q2
replace max_cat = 3 if num_top10max > 22 & num_top10max <= 52  // Q3
replace max_cat = 4 if num_top10max > 52 & !missing(num_top10max) // Q4

label define max_lab 1 "0-8" 2 "8-22" 3 "22-52" 4 ">52"
label values max_cat max_lab

* 执行全样本交互项回归
* 使用 i.max_cat#c.did 得到各组的 DID 系数
reghdfe log_yearlycitation ///
    i.max_cat#c.did ///
    author_year ref_year sef_year  ///
    , absorb(paper_numid year age) cluster(paper_numid)

* 组间差异显著性检验 (Wald Test)
* 验证学术地位最高的组 (Q4) 是否比地位最低的组 (Q1) 遭受了更显著的打击
test 4.max_cat#c.did = 1.max_cat#c.did
local p_4_1 = r(p)

* 验证 Q4 与 Q3 之间是否有显著差异
test 4.max_cat#c.did = 3.max_cat#c.did
local p_4_3 = r(p)

* 统计各组样本量 (去重统计)
cap drop tag
egen tag = tag(paper_numid) if e(sample)

forvalues i = 1/4 {
    quietly count if group == 1 & tag == 1 & max_cat == `i'
    local nt`i' = r(N)
    quietly count if group == 0 & tag == 1 & max_cat == `i'
    local nc`i' = r(N)
}

* 5. 存储结果并添加统计量
estadd scalar p_q4_q1 = `p_4_1'
estadd scalar p_q4_q3 = `p_4_3'
forvalues i = 1/4 {
    estadd local nt`i' "`nt`i''"
    estadd local nc`i' "`nc`i''"
}

eststo m_max_inter

* --- 1. 完善变量标签 ---
label var author_year "Author seniority (Trend)"
label var ref_year "Ref. quality (Trend)"
label var sef_year "Self-retraction (Trend)"

* --- 2. 导出表格 ---
esttab m_max_inter using Top10Max_Interaction_Validation.rtf, replace ///
    title("{\b Table 15.} Interaction analysis of author academic standing (Top 10% papers)") ///
    keep(*.max_cat#c.did) ///
    coeflabels(1.max_cat#c.did "DID × Q1 (0-8)" ///
               2.max_cat#c.did "DID × Q2 (8-22)" ///
               3.max_cat#c.did "DID × Q3 (22-52)" ///
               4.max_cat#c.did "DID × Q4 (>52)") ///
    b(%9.3f) se(%9.3f) ///         // 核心修改：使用标准误 (SE)，不要置信区间
    star(* 0.05 ** 0.01 *** 0.001) /// // 核心要求：*** 对应 0.001
    nonumber label nogap compress ///
    stats(p_q4_q1 p_q4_q3 nt4 nc4 N r2_a, ///
          labels("P-val (Q4=Q1)" "P-val (Q4=Q3)" "Treated (Q4)" "Control (Q4)" "Observations" "Adj. R-squared") ///
          fmt(%9.3f %9.3f %9.0f %9.0f %9.0f %9.3f)) /// // P值保留3位，样本量为整数
    addnotes("Note: Standard errors (in parentheses) are clustered at the paper level." ///
             "The independent variables are interactions between the Post-retraction (DID) dummy and quartiles of the authors' maximum Top 10% paper count." ///
             "P-values are derived from Wald tests of coefficient equality." ///
             "* p < 0.05, ** p < 0.01, *** p < 0.001.")
	
**# 异质性4：作者声誉——撤稿论文作者MAX声誉（分组回归）
	//（2）撤稿论文作者 前10%top论文数 rnum_top10max rnum_top10mean
//=========================================================================//
///////////////* --- (2a) rnum_top10max 异质性分析 ---///////////////////////
//=========================================================================//	
//分组回归
summarize rnum_top10max, detail //分位数判断
//18，45，101，551
eststo clear

// Group 1: [0, 18]
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if rnum_top10max >= 0 & rnum_top10max <= 18, absorb(paper_numid year age) cluster(paper_numid)
cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo rm_max_q1

// Group 2: (18, 45]
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if rnum_top10max > 18 & rnum_top10max <= 45, absorb(paper_numid year age) cluster(paper_numid)
cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo rm_max_q2

// Group 3: (45, 101]
reghdfe log_yearlycitation did author_year ref_year sef_year ///
    if rnum_top10max > 45 & rnum_top10max <= 101, absorb(paper_numid year age) cluster(paper_numid)
cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo rm_max_q3

// Group 4: > 101
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if rnum_top10max > 101, absorb(paper_numid year age) cluster(paper_numid)
cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo rm_max_q4

* --- 1. 完善变量标签 ---
label var did "Post-retraction (DID)"
label var author_year "Author seniority (Trend)"
label var ref_year "Ref. quality (Trend)"
label var sef_year "Self-retraction (Trend)"

* --- 2. 定义分位数标题 (Q1-Q4) ---
local mt_rtop10 `" "Q1: 0-18" "Q2: 18-45" "Q3: 45-101" "Q4: >101" "'

* --- 3. 导出表格 ---
esttab rm_max_q1 rm_max_q2 rm_max_q3 rm_max_q4 using Table_RTop10Max_Hetero.rtf, replace ///
    title("{\b Table 16.} Heterogeneity by cited author's maximum Top 10% paper count") ///
    keep(did author_year ref_year sef_year) ///
    coeflabels(did "Post-retraction (DID)") ///
    b(%9.3f) se(%9.3f) ///         // 核心修改：使用标准误 (SE)，移除置信区间
    star(* 0.05 ** 0.01 *** 0.001) /// // 核心要求：*** 对应 0.001
    mtitle(`mt_rtop10') ///         // 强制显示分位数区间标题
    mgroups("Dependent Variable: Log(Annual citations + 1)", pattern(1 0 0 0) prefix(\line\em ) span) ///
    nonumber label nogap compress ///
    stats(n_treated n_control n_papers N r2_a, ///
          labels("Treated papers" "Control papers" "Unique papers" "Observations" "Adj. R-squared") ///
          fmt(%9.0f %9.0f %9.0f %9.0f %9.3f)) /// // 样本量强制为整数
    addnotes("Note: Standard errors (in parentheses) are clustered at the paper level." ///
             "Quartiles are based on the maximum number of Top 10% papers among authors of the cited references (rnum_top10max)." ///
             "* p < 0.05, ** p < 0.01, *** p < 0.001.")

**# 异质性4：作者声誉——撤稿论文作者MAX声誉（交互回归）	
	//交互回归
* --- 1. 创建基于分位数的分类变量 (18, 45, 101) ---
gen rmax_cat = .
replace rmax_cat = 1 if rnum_top10max >= 0  & rnum_top10max <= 18
replace rmax_cat = 2 if rnum_top10max > 18  & rnum_top10max <= 45
replace rmax_cat = 3 if rnum_top10max > 45  & rnum_top10max <= 101
replace rmax_cat = 4 if rnum_top10max > 101 & rnum_top10max < .

* --- 2. 交互项回归 ---
* 使用 i.rmax_cat#c.did 直接估计四个组的系数
reghdfe log_yearlycitation i.rmax_cat#c.did author_year ref_year sef_year, ///
    absorb(paper_numid year age) cluster(paper_numid)

* --- 3. 统计学差异检验 (Wald Tests) ---
* 检验最高分位数 (Q4) 与最低分位数 (Q1) 的系数是否相等
test 4.rmax_cat#c.did = 1.rmax_cat#c.did
estadd scalar p_q4_q1 = r(p)

* 检验最高分位数 (Q4) 与次高分位数 (Q3) 的系数是否相等
test 4.rmax_cat#c.did = 3.rmax_cat#c.did
estadd scalar p_q4_q3 = r(p)

* --- 4. 统计各子样本中的 Treated 和 Control 数量 ---
forvalues i = 1/4 {
    cap drop tag
    egen tag = tag(paper_numid) if e(sample) & rmax_cat == `i'
    
    quietly count if group == 1 & tag == 1
    estadd scalar nt`i' = r(N)
    
    quietly count if group == 0 & tag == 1
    estadd scalar nc`i' = r(N)
}

eststo m_rmax_inter
* --- 1. 完善变量标签 ---
label var author_year "Author seniority (Trend)"
label var ref_year "Ref. quality (Trend)"
label var sef_year "Self-retraction (Trend)"
* --- 2. 导出表格 ---
esttab m_rmax_inter using RTop10Max_Interaction_Table.rtf, replace ///
    title("{\b Table 17.} Interaction analysis of cited author's academic standing (rTop10% papers)") ///
    keep(*.rmax_cat#c.did) ///
    coeflabels(1.rmax_cat#c.did "DID × Q1 (0-18)" ///
               2.rmax_cat#c.did "DID × Q2 (18-45)" ///
               3.rmax_cat#c.did "DID × Q3 (45-101)" ///
               4.rmax_cat#c.did "DID × Q4 (>101)") ///
    b(%9.3f) se(%9.3f) ///         // 核心修改：使用标准误 (SE)，移除置信区间
    star(* 0.05 ** 0.01 *** 0.001) /// // 核心要求：*** 对应 0.001
    nonumber label nogap compress ///
    stats(p_q4_q1 p_q4_q3 nt1 nc1 nt4 nc4 N r2_a, ///
          labels("P-val (Q4=Q1)" "P-val (Q4=Q3)" "Treated (Q1)" "Control (Q1)" "Treated (Q4)" "Control (Q4)" "Observations" "Adj. R-squared") ///
          fmt(%9.3f %9.3f %9.0f %9.0f %9.0f %9.0f %9.0f %9.3f)) /// // P值3位小数，样本量整数
    addnotes("Note: Standard errors (in parentheses) are clustered at the paper level." ///
             "The independent variables are interactions between the Post-retraction (DID) dummy and quartiles of the cited authors' maximum Top 10% paper count." ///
             "P-values for coefficient equality are based on Wald tests after reghdfe." ///
             "* p < 0.05, ** p < 0.01, *** p < 0.001.")

	
//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX//  
//X===================== 异质性 5：观测区间长度 =========================X//
//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX//
//（1）分组回归：
eststo clear

* --- (1) 上升观测期 (1-2年) ---
reghdfe log_yearlycitation did author_year ref_year sef_year ///
    if t_ptor >= 1 & t_ptor <= 2, absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m1

* --- (2) 短观测期 (2-5年) ---
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if t_ptor > 2 & t_ptor <= 5, absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m2

* --- (3) 中长观测期 (> 5年) ---
reghdfe log_yearlycitation did author_year ref_year sef_year  ///
    if t_ptor > 5, absorb(paper_numid year age) cluster(paper_numid)

cap drop tag
egen tag = tag(paper_numid) if e(sample)
quietly count if group == 1 & tag == 1
estadd local n_treated = string(`r(N)')
quietly count if group == 0 & tag == 1
estadd local n_control = string(`r(N)')
estadd local hasPaperFE "Yes"
estadd local hasYearFE "Yes"
estadd local hasAgeFE "Yes"
eststo m3

* --- 1. 完善变量标签 ---
label var did "Post-retraction (DID)"
label var author_year "Author seniority (Trend)"
label var ref_year "Ref. quality (Trend)"
label var sef_year "Self-retraction (Trend)"

* --- 2. 定义列标题 (使用复合双引号防止空格错位) ---
local mt_tptor `" "Ascending (1-2y)" "Short-term (2-5y)" "Mid-Long (>5y)" "'

* --- 3. 导出表格 ---
esttab m1 m2 m3 using "heterogeneity_results_t_ptor.rtf", replace ///
    title("{\b Table 18.} Heterogeneity by publication-to-retraction interval (t_ptor)") ///
    keep(did author_year ref_year sef_year) ///
    coeflabels(did "Post-retraction (DID)") ///
    b(%9.3f) se(%9.3f) ///         // 核心修改：使用标准误 (SE)，移除置信区间
    star(* 0.05 ** 0.01 *** 0.001) /// // 核心要求：*** 对应 0.001
    mtitle(`mt_tptor') ///          // 分组标题
    mgroups("Dependent Variable: Log(Annual citations + 1)", pattern(1 0 0) prefix(\line\em ) span) ///
    nonumber label nogap compress ///
    stats(n_treated n_control n_papers N r2_a, ///
          labels("Treated papers" "Control papers" "Unique papers" "Observations" "Adj. R-squared") ///
          fmt(%9.0f %9.0f %9.0f %9.0f %9.3f)) /// // 样本量强制为整数
    addnotes("Note: Standard errors (in parentheses) are clustered at the paper level." ///
             "t_ptor represents the time interval (in years) between publication and retraction." ///
             "All models include Paper, Year, and Age Fixed Effects." ///
             "* p < 0.05, ** p < 0.01, *** p < 0.001.")
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	