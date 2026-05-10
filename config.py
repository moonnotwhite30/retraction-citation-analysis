# ============================================================
# config.py — 撤稿论文引用分析项目 集中配置文件
# ============================================================
# 所有数据路径在这里统一定义，不要在 notebook 里硬编码路径
# 修改路径只需要改这一个文件

from pathlib import Path
import os

# ============================================================
# 一、项目根目录
# ============================================================
PROJECT_ROOT = Path('/home/wenyutao/retraction-analysis')
OUTPUT_DIR = PROJECT_ROOT / 'output'
FIGURE_DIR = OUTPUT_DIR / 'figures'
TABLE_DIR = OUTPUT_DIR / 'tables'

# ============================================================
# 二、原始数据 (Read-Only)
# ============================================================
# Dimensions 数据库 — 可能挂在两个地方
_DATA1 = Path('/Data1/DATA/Dimensions2024/20240101')
_DATA6 = Path('/data6/Data1/DATA/Dimensions2024/20240101')

# 自动检测哪个路径可用
if _DATA6.exists():
    RAW = _DATA6
elif _DATA1.exists():
    RAW = _DATA1
else:
    RAW = _DATA1  # 默认值

# ============================================================
# 三、基础参考数据（在 /Data4/yutao_wen/ 根目录下）
# ============================================================
BASE = Path('/Data4/yutao_wen')

# 撤稿论文名单
MATCHED_OUTPUT = BASE / 'matched_output2.csv'

# 全年引用字典
ALL_YEAR_REFS = BASE / 'ALLyear_paper_refs.json'

# 维度字典（模块二用）
DIC_YEAR = BASE / '2part_Dic/total/papers_year_dic.json'
DIC_JOURNAL = BASE / '2part_Dic/total/papers_journal_numA_numR_dic.json'

# 概念数据
PAPER_CONCEPT_CSV = BASE / 'paper_concept.csv'
PAPER_CONCEPT_PQ = BASE / 'paper_concept.parquet'

# 期刊 / JCR 数据
JOURNAL_IF_ISSN = BASE / 'journal_if_issn_eissn.csv'
JOURNAL_IF_ISSN_2025 = BASE / 'journal_if_issn_eissn2025.csv'
JCR_2025 = BASE / 'jcr2025.csv'
PAPER_JOURNAL_ISSN = BASE / 'paper_journal_issn.csv'

# H指数
H_INDEX = BASE / '25.11.10/H_index.csv'

# 领域分类
DIMENSIONS_FIELD0 = Path('/Data4/Yang_wenlong/dimensions_field0.csv')

# ============================================================
# 四、中间数据（按代标记，Read-Only 旧数据）
# ============================================================
GEN = {
    # gen1: 模块(一)~(三) 核心输出
    'GEN1': BASE / '25.11.10',
    # gen2: 模块(四)~(五) H指数、清洗
    'GEN2': BASE / '25.12.05',
    'GEN3': BASE / '25.12.17',
    # gen4: 模块(七)~(八) 异质性、可视化
    'GEN4': BASE / '26.1.19',
    'GEN5': BASE / '26.1.30',
    # gen6: 模块(九) Relevance Score 新流程
    'GEN6': BASE / '26.4.21',
}

# ============================================================
# 五、统一输出目录（所有新产出统一放这里）
# ============================================================
PROCESSED = BASE / 'processed'

# ============================================================
# 六、工具函数
# ============================================================
def ensure_dirs():
    """创建所有需要的输出目录"""
    for d in [PROCESSED, FIGURE_DIR, TABLE_DIR]:
        d.mkdir(parents=True, exist_ok=True)

# ============================================================
# 七、常用文件映射（给 notebook 用的快捷变量）
# ============================================================
G1 = GEN['GEN1']   # 25.11.10
G2 = GEN['GEN2']   # 25.12.05
G3 = GEN['GEN3']   # 25.12.17
G4 = GEN['GEN4']   # 26.1.19
G5 = GEN['GEN5']   # 26.1.30
G6 = GEN['GEN6']   # 26.4.21

# 特定文件快捷路径
DF_CONTAINRETRA3 = G1 / 'df_containretra3.csv'
DF_MATCH = G1 / 'df_match.csv'
DF_MERGED_ECR = G1 / 'df_merged_ECR2.csv'
E_C_DF = G1 / 'E_C_df.csv'
SELF_RETRA = G1 / 'SelfRetra_papers.csv'
E_C_DF_CLEAN = G3 / 'E_C_df_clean.csv'
E_C_DF_MERGED = G2 / 'E_C_df_merged_check.csv'

if __name__ == '__main__':
    print(f'项目根目录: {PROJECT_ROOT}')
    print(f'原始数据路径: {RAW}  (可用: {RAW.exists()})')
    print(f'基础数据路径: {BASE}  (可用: {BASE.exists()})')
    print(f'输出目录: {PROCESSED}')
    print()
    print('各代数据:')
    for name, path in GEN.items():
        status = 'OK' if path.exists() else 'MISSING'
        print(f'  {name}: {path}  ({status})')
