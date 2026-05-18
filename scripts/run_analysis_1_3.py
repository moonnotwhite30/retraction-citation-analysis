#!/usr/bin/env python3
"""运行模块(十) #1-#3 分析代码，产出分布图 + 统计表 + 论文案例"""
import sys, time, os, re
sys.path.insert(0, '/home/wenyutao/retraction-analysis')
from config import G6, G1, FIGURE_DIR, TABLE_DIR, RAW, get_db
FIGURE_DIR.mkdir(parents=True, exist_ok=True)
TABLE_DIR.mkdir(parents=True, exist_ok=True)

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
import duckdb

sns.set_theme(style="whitegrid")
plt.rcParams['font.size'] = 12
plt.rcParams['axes.unicode_minus'] = False

FILE = G6 / "Final_Panel_with_DualSim.csv"
PAPERS = RAW / "Papers.csv"

print("=" * 70)
print("  模块(十) #1-#3 联合分析")
print("=" * 70)

# ---- Load data ----
print("\n读取 DualSim...")
df = pd.read_csv(FILE)
mask = (df['group'] == 1) & df['sim_jr'].notna()
df_treat = df[mask].copy()
pairs = df_treat[['focal_id', 'paper_id', 'ja_sameconcept', 'sim_jr', 'quadrant', 'sim_ij_high', 'sim_jr_high']].drop_duplicates()
print(f"唯一配对数: {len(pairs):,}")

# ============================================================
# #1: Sim 分布深化
# ============================================================
print("\n" + "=" * 70)
print("  #1: Sim 分布深化分析")
print("=" * 70)

def describe_sim(series, name):
    s = series.dropna()
    qs = [0.01, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.99]
    lines = []
    lines.append(f"\n  {name} 分布报告 (N={len(s):,})")
    lines.append(f"  {'-'*50}")
    lines.append(f"  Mean={s.mean():.4f}  Std={s.std():.4f}")
    lines.append(f"  Min={s.min():.4f}  Max={s.max():.4f}")
    lines.append(f"  Skewness={s.skew():.2f}  Kurtosis={s.kurtosis():.2f}")
    lines.append(f"  >0 比例: {(s>0).mean()*100:.1f}%")
    lines.append(f"  分位数: " + " | ".join([f"P{int(q*100)}={s.quantile(q):.4f}" for q in qs]))
    return "\n".join(lines)

print(describe_sim(pairs['ja_sameconcept'], 'Sim(i,j) = ja_sameconcept'))
print(describe_sim(pairs['sim_jr'], 'Sim(j,r) = sim_jr'))

# Bootstrap CI for >0 proportion
def bootstrap_gt0(series, n_boot=1000, seed=42):
    rng = np.random.default_rng(seed)
    s = series.dropna().values
    props = [(rng.choice(s, size=len(s), replace=True) > 0).mean() for _ in range(n_boot)]
    props = np.array(props)
    return np.percentile(props, 2.5), np.percentile(props, 97.5)

ci_ij = bootstrap_gt0(pairs['ja_sameconcept'])
ci_jr = bootstrap_gt0(pairs['sim_jr'])
print(f"\n  Bootstrap 95%CI for >0 proportion:")
print(f"    Sim(i,j): [{ci_ij[0]*100:.1f}%, {ci_ij[1]*100:.1f}%]")
print(f"    Sim(j,r): [{ci_jr[0]*100:.1f}%, {ci_jr[1]*100:.1f}%]")

# ---- Joint distribution plots ----
fig, axes = plt.subplots(2, 3, figsize=(18, 12))

ax = axes[0, 0]
ax.hist(pairs['ja_sameconcept'].clip(0, 0.15), bins=50, color='steelblue', edgecolor='white', alpha=0.8)
ax.axvline(pairs['ja_sameconcept'].median(), color='red', linestyle='--', linewidth=2, label=f"Median={pairs['ja_sameconcept'].median():.3f}")
ax.set_xlabel('Sim(i,j)'); ax.set_ylabel('Count')
ax.set_title('Sim(i,j) Distribution (clipped at 0.15)'); ax.legend()

ax = axes[0, 1]
ax.hist(pairs['sim_jr'].clip(0, 0.15), bins=50, color='coral', edgecolor='white', alpha=0.8)
ax.axvline(pairs['sim_jr'].median(), color='red', linestyle='--', linewidth=2, label=f"Median={pairs['sim_jr'].median():.3f}")
ax.set_xlabel('Sim(j,r)'); ax.set_ylabel('Count')
ax.set_title('Sim(j,r) Distribution (clipped at 0.15)'); ax.legend()

ax = axes[0, 2]
hb = ax.hexbin(pairs['ja_sameconcept'].clip(0, 0.2), pairs['sim_jr'].clip(0, 0.2), gridsize=40, cmap='YlOrRd', mincnt=1)
ax.axhline(pairs['sim_jr'].median(), color='coral', linestyle='--', linewidth=1.5)
ax.axvline(pairs['ja_sameconcept'].median(), color='steelblue', linestyle='--', linewidth=1.5)
ax.set_xlabel('Sim(i,j)'); ax.set_ylabel('Sim(j,r)')
ax.set_title('Joint Distribution (hexbin)')
plt.colorbar(hb, ax=ax, label='Count')

ax = axes[1, 0]
pos_ij = pairs.loc[pairs['ja_sameconcept'] > 0, 'ja_sameconcept']
ax.hist(np.log10(pos_ij), bins=50, color='steelblue', edgecolor='white', alpha=0.8)
ax.set_xlabel('log10(Sim(i,j))'); ax.set_ylabel('Count')
ax.set_title('Sim(i,j) > 0 -- log10 Scale')

ax = axes[1, 1]
pos_jr = pairs.loc[pairs['sim_jr'] > 0, 'sim_jr']
ax.hist(np.log10(pos_jr), bins=50, color='coral', edgecolor='white', alpha=0.8)
ax.set_xlabel('log10(Sim(j,r))'); ax.set_ylabel('Count')
ax.set_title('Sim(j,r) > 0 -- log10 Scale')

ax = axes[1, 2]
x_ij = np.sort(pairs['ja_sameconcept'].dropna())
x_jr = np.sort(pairs['sim_jr'].dropna())
ax.plot(x_ij, np.linspace(0, 1, len(x_ij)), color='steelblue', linewidth=2, label='Sim(i,j)')
ax.plot(x_jr, np.linspace(0, 1, len(x_jr)), color='coral', linewidth=2, label='Sim(j,r)')
ax.set_xlim(0, 0.1); ax.set_xlabel('Similarity'); ax.set_ylabel('CDF')
ax.set_title('Cumulative Distribution (0 to 0.1)'); ax.legend()

plt.tight_layout()
fig.savefig(FIGURE_DIR / 'sim_distribution_report.pdf', dpi=150, bbox_inches='tight')
fig.savefig(FIGURE_DIR / 'sim_distribution_report.png', dpi=150, bbox_inches='tight')
plt.close()
print("  Charts saved: sim_distribution_report.pdf/png")

# ---- Threshold sensitivity ----
thresholds = [
    ('median', pairs['ja_sameconcept'].median(), pairs['sim_jr'].median()),
    ('mean', pairs['ja_sameconcept'].mean(), pairs['sim_jr'].mean()),
    ('P75', pairs['ja_sameconcept'].quantile(0.75), pairs['sim_jr'].quantile(0.75)),
    ('P90', pairs['ja_sameconcept'].quantile(0.90), pairs['sim_jr'].quantile(0.90)),
    ('>0 (jr only)', pairs['ja_sameconcept'].median(), 0.0),
]
print(f"\n  阈值敏感性分析:")
print(f"  {'Threshold':<20} {'Sim(i,j)':>10} {'Sim(j,r)':>10} {'远离':>8} {'安全替代':>8} {'同源污染':>8} {'污染近邻':>8}")
print(f"  {'-'*20} {'-'*10} {'-'*10} {'-'*8} {'-'*8} {'-'*8} {'-'*8}")
for name, t_ij, t_jr in thresholds:
    hi = (pairs['ja_sameconcept'] > t_ij).astype(int)
    hj = (pairs['sim_jr'] > t_jr).astype(int)
    print(f"  {name:<20} {t_ij:>10.4f} {t_jr:>10.4f} {((hi==0)&(hj==0)).mean()*100:>7.1f}% {((hi==1)&(hj==0)).mean()*100:>7.1f}% {((hi==0)&(hj==1)).mean()*100:>7.1f}% {((hi==1)&(hj==1)).mean()*100:>7.1f}%")

# ============================================================
# #2: 四象限分组统计
# ============================================================
print("\n" + "=" * 70)
print("  #2: 四象限分组统计")
print("=" * 70)

treat = df[(df['group'] == 1) & (df['quadrant'] != '控制组/缺失')].copy()
pairs2 = treat[['focal_id', 'paper_id', 'quadrant', 'sim_ij_high', 'sim_jr_high']].drop_duplicates()

quadrants = ['安全替代', '污染近邻', '远离论文', '同源污染']
stats = {}
for q in quadrants:
    sub = pairs2[pairs2['quadrant'] == q]
    stats[q] = {
        'unique_pairs': len(sub),
        'unique_j': sub['paper_id'].nunique(),
        'unique_focal': sub['focal_id'].nunique(),
        'pct_pairs': len(sub) / len(pairs2) * 100,
        'avg_j_per_focal': len(sub) / sub['focal_id'].nunique() if sub['focal_id'].nunique() > 0 else 0,
        'avg_sim_ij': pairs[pairs['quadrant']==q]['ja_sameconcept'].mean(),
        'avg_sim_jr': pairs[pairs['quadrant']==q]['sim_jr'].mean(),
    }
    print(f"\n  [{q}]")
    print(f"    Unique pairs:    {stats[q]['unique_pairs']:>8,}  ({stats[q]['pct_pairs']:.1f}%)")
    print(f"    Unique j papers: {stats[q]['unique_j']:>8,}")
    print(f"    Unique focals:   {stats[q]['unique_focal']:>8,}")
    print(f"    Avg j/focal:     {stats[q]['avg_j_per_focal']:.1f}")
    print(f"    Avg Sim(i,j):    {stats[q]['avg_sim_ij']:.4f}")
    print(f"    Avg Sim(j,r):    {stats[q]['avg_sim_jr']:.4f}")

# Save stats table
stats_df = pd.DataFrame(stats).T
stats_df.to_csv(TABLE_DIR / 'quadrant_stats.csv')
print(f"\n  Stats saved: tables/quadrant_stats.csv")

# Charts
fig, axes = plt.subplots(1, 3, figsize=(18, 6))
labels_short = ['Safe Sub.', 'Contam.Neigh.', 'Distant', 'Same-Src']
colors = ['#2ecc71', '#e74c3c', '#95a5a6', '#f39c12']
explode = (0.05, 0, 0, 0)

ax = axes[0]
sizes = [stats[q]['unique_pairs'] for q in quadrants]
wedges, texts, autotexts = ax.pie(sizes, explode=explode, labels=labels_short, colors=colors,
                                   autopct='%1.1f%%', startangle=90, pctdistance=0.6)
for at in autotexts: at.set_fontsize(11)
ax.set_title('Unique (i, j) Pairs by Quadrant')

ax = axes[1]
j_counts = [stats[q]['unique_j'] for q in quadrants]
bars = ax.bar(labels_short, j_counts, color=colors, edgecolor='white', linewidth=1.5)
for bar, val in zip(bars, j_counts):
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 500,
            f'{val:,}', ha='center', va='bottom', fontsize=11, fontweight='bold')
ax.set_ylabel('Unique Papers'); ax.set_title('Unique j Papers by Quadrant')
ax.tick_params(axis='x', rotation=15)

ax = axes[2]
focal_j_counts = pairs2.groupby(['focal_id', 'quadrant']).size().reset_index(name='n_j')
bp_data = [focal_j_counts[focal_j_counts['quadrant']==q]['n_j'].values for q in quadrants]
bp = ax.boxplot(bp_data, labels=labels_short, patch_artist=True)
for patch, color in zip(bp['boxes'], colors):
    patch.set_facecolor(color); patch.set_alpha(0.6)
ax.set_ylabel('Number of j per focal'); ax.set_title('j-per-Focal by Quadrant')
ax.tick_params(axis='x', rotation=15)

plt.tight_layout()
fig.savefig(FIGURE_DIR / 'quadrant_distribution.pdf', dpi=150, bbox_inches='tight')
fig.savefig(FIGURE_DIR / 'quadrant_distribution.png', dpi=150, bbox_inches='tight')
plt.close()
print("  Charts saved: quadrant_distribution.pdf/png")

# Focal quadrant coverage
focal_quadrants = pairs2.groupby('focal_id')['quadrant'].apply(lambda x: list(set(x))).reset_index()
focal_quadrants['n_quadrants'] = focal_quadrants['quadrant'].apply(len)
print(f"\n  每个 focal 覆盖的四象限数量分布:")
for n, cnt in focal_quadrants['n_quadrants'].value_counts().sort_index().items():
    print(f"    {n} quadrant(s): {cnt:,} focals")
print(f"  同时覆盖全部4类: {(focal_quadrants['n_quadrants']==4).sum():,} focals")

# ============================================================
# #3: 双高论文定性特征
# ============================================================
print("\n" + "=" * 70)
print("  #3: 双高论文定性特征提取")
print("=" * 70)

hh = pairs[pairs['quadrant'] == '污染近邻'].copy()
hh['composite'] = hh['ja_sameconcept'] * hh['sim_jr']
hh_top = hh.nlargest(30, 'composite')
print(f"  双高配对: {len(hh):,}  |  unique j: {hh['paper_id'].nunique():,}  |  unique focal: {hh['focal_id'].nunique():,}")

# Extract titles from Papers.csv via DuckDB
all_ids = pd.concat([hh_top['focal_id'], hh_top['paper_id']]).unique()
id_df = pd.DataFrame({'id': all_ids})

con = get_db()
con.register('target_ids', id_df)
query = f"""
    SELECT p.id, p.title, p.date_normal
    FROM read_csv_auto('{PAPERS}') p
    INNER JOIN target_ids t ON p.id = t.id
"""
papers_info = con.execute(query).df()
con.close()
papers_info['year'] = pd.to_datetime(papers_info['date_normal'], errors='coerce').dt.year
title_map = dict(zip(papers_info['id'], papers_info['title']))
year_map = dict(zip(papers_info['id'], papers_info['year']))

print(f"\n  {'='*90}")
print(f"  Top 15 双高论文典型案例")
print(f"  {'='*90}")
for rank, (_, row) in enumerate(hh_top.head(15).iterrows(), 1):
    fi = row['focal_id']; ji = row['paper_id']
    print(f"\n  #{rank} Sim(i,j)={row['ja_sameconcept']:.4f} Sim(j,r)={row['sim_jr']:.4f} composite={row['composite']:.4f}")
    ti = title_map.get(fi, 'N/A')
    tj = title_map.get(ji, 'N/A')
    print(f"  Focal (i): {ti[:130]}")
    print(f"  J-paper:   {tj[:130]}")
    print(f"  Year: i={year_map.get(fi,'?')}, j={year_map.get(ji,'?')}")

# Compare with Safe Substitute cases
safe = pairs[pairs['quadrant'] == '安全替代'].copy()
safe['composite'] = safe['ja_sameconcept'] * safe['sim_jr']
safe_top = safe.nlargest(10, 'ja_sameconcept')

print(f"\n  {'='*90}")
print(f"  Top 10 安全替代典型案例 (按 Sim(i,j) 排序)")
print(f"  {'='*90}")
safe_ids = pd.concat([safe_top['focal_id'], safe_top['paper_id']]).unique()
id_df2 = pd.DataFrame({'id': safe_ids})
con2 = get_db()
con2.register('target_ids', id_df2)
papers_info2 = con2.execute(query).df()
con2.close()
title_map2 = dict(zip(papers_info2['id'], papers_info2['title']))
year_map2 = dict(zip(papers_info2['id'], pd.to_datetime(papers_info2['date_normal'], errors='coerce').dt.year))

for rank, (_, row) in enumerate(safe_top.iterrows(), 1):
    fi = row['focal_id']; ji = row['paper_id']
    print(f"\n  #{rank} Sim(i,j)={row['ja_sameconcept']:.4f} Sim(j,r)={row['sim_jr']:.4f}")
    print(f"  Focal (i): {title_map2.get(fi, 'N/A')[:130]}")
    print(f"  J-paper:   {title_map2.get(ji, 'N/A')[:130]}")

print("\n" + "=" * 70)
print("  #1-#3 全部完成！")
print("=" * 70)
