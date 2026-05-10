# 撤稿论文引用分析项目

## 项目概述

本项目研究撤稿论文（Retracted Papers）的引用模式。核心问题是：论文被撤稿后，引用它的后续论文是否会受到"惩罚"（引用量下降）。

项目使用 Dimensions 2024 数据库，通过匹配实验组（引用了撤稿论文的论文）和对照组（未引用撤稿论文但特征相似的论文），对比两者在撤稿事件前后的引用量变化。

## 项目结构

```
retraction-analysis/
+-- config.py                  # 集中配置文件（所有路径在这里定义）
+-- README.md                  # 本文件
+-- .gitignore                 # Git 忽略规则
+-- notebooks/                 # Jupyter Notebook（按模块拆分）
|   +-- 01_load_and_clean.ipynb        # 模块(一) 数据加载与清洗
|   +-- 02_control_matching.ipynb      # 模块(二) 四维度对照组匹配
|   +-- 03_citation_calculation.ipynb  # 模块(三) 事前事后引用计算
|   +-- 04_control_screening.ipynb     # 模块(四) 事前趋势筛选
|   +-- 05_panel_and_covariates.ipynb  # 模块(五) 面板数据与协变量
|   +-- 06_stata_plots.ipynb           # 模块(六) Stata 补充绘图
|   +-- 07_heterogeneity.ipynb         # 模块(七) 异质性分析
|   +-- 08_visualization.ipynb         # 模块(八) 可视化
|   +-- 09_concept_relevance.ipynb     # 模块(九) Relevance Score
+-- output/                    # 输出（不入 git）
|   +-- figures/
|   +-- tables/
+-- docs/
    +-- data_dictionary.md     # 变量/列名释义
```

## 数据来源

| 数据 | 位置 | 说明 |
|------|------|------|
| Dimensions 原始数据 | /data6/Data1/DATA/Dimensions2024/20240101/ | Papers, PaperReferences, PaperAuthor 等 |
| 撤稿论文名单 | /Data4/yutao_wen/matched_output2.csv | 预先匹配的撤稿论文列表 |
| 中间处理数据 | /Data4/yutao_wen/25.11.10/ ~ 26.4.21/ | 各阶段产出（按日期分代） |
| 统一输出目录 | /Data4/yutao_wen/processed/ | 重构后所有新产出的统一位置 |

## 快速开始

### 1. 环境配置

确保已安装必要的 Python 包：
```
pip install pandas numpy matplotlib seaborn duckdb pyarrow openpyxl tqdm
```

### 2. 运行 Notebook

```bash
cd ~/retraction-analysis
jupyter lab
```

然后在浏览器中按顺序打开 notebooks/ 下的 .ipynb 文件。

### 3. 配置路径

所有路径定义在 config.py 中。如果数据位置发生变化，只需修改这一个文件。

## 模块说明

| 模块 | Notebook | 功能 | 主要输入 | 主要输出 |
|------|----------|------|----------|----------|
| (一) | 01_load_and_clean.ipynb | 匹配引用撤稿论文的文献并清洗 | PaperReferences + matched_output2 | df_containretra3.csv |
| (二) | 02_control_matching.ipynb | 四维度 Exactly 匹配对照组 | df_containretra3 + 维度字典 | df_match.csv |
| (三) | 03_citation_calculation.ipynb | 计算事前事后逐年引用量 | df_match + ALLyear_paper_refs | E_C_df.csv |
| (四) | 04_control_screening.ipynb | 基于事前趋势筛选对照组 | E_C_df.csv | panel_df_*.csv |
| (五) | 05_panel_and_covariates.ipynb | 添加协变量、创建面板数据 | panel_df + H_index + PaperAuthor | DOM_*.csv |
| (六) | 06_stata_plots.ipynb | Stata 补充绘图与回归诊断 | DOM_*.csv | 图表 |
| (七) | 07_heterogeneity.ipynb | 异质性（撤稿原因/领域/JCR/H指数） | DOM_*.csv | 带标签面板数据 |
| (八) | 08_visualization.ipynb | 可视化（生命周期/热力图/散点图） | 带标签面板数据 | PDF/PNG 图表 |
| (九) | 09_concept_relevance.ipynb | Relevance Score 与新Treat生成 | paper_concept + E_C_df | Final_Panel_*.csv |

## 运维说明

- 改数据路径：编辑 config.py，重新运行 notebook
- 重新运行中间步骤：打开对应 notebook，从头执行所有 cell
- 回退：原 notebook 备份在 ~/backup_2026_04_21.ipynb
- Git 仓库：git@github.com:moonnotwhite30/retraction-citation-analysis.git

## 注意事项

- 部分原始数据文件极大（如 paper_concept.parquet 43GB），确保有足够内存
- 远程开发时使用 VS Code Remote SSH 连接 wenyutao@10.181.6.114
- 数据文件不入 git（已在 .gitignore 中排除）
