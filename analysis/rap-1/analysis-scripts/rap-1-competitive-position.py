#!/usr/bin/env python3
"""
RAP-1 Competitive Positioning Analysis

Analyzes Square One Coffee's positioning relative to competitors across key dimensions:
- Market positioning comparison (g5 family)
- Quality and reputation analysis (g6 family)
- Strategic advantages/vulnerabilities (g7 family)

All graphs follow the EDA style guide: 8.5 × 5.5 inches, 300 DPI, unique identifiers
"""

import sqlite3
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.dpi'] = 300
plt.rcParams['savefig.dpi'] = 300
plt.rcParams['font.size'] = 10

# Configuration
DB_PATH = "./data-private/derived/rap-1-competition-intel.sqlite"
PRINTS_FOLDER = "./analysis/rap-1/prints/"
FIG_WIDTH = 8.5
FIG_HEIGHT = 5.5

print("=" * 70)
print("RAP-1 COMPETITIVE POSITIONING ANALYSIS")
print("=" * 70)
print(f"Square One Coffee vs Edmonton Market")
print()

# Create prints folder
Path(PRINTS_FOLDER).mkdir(parents=True, exist_ok=True)

# ===== LOAD DATA =====
print("\n## Loading Data")

conn = sqlite3.connect(DB_PATH)

cafes = pd.read_sql_query("SELECT * FROM cafes_complete", conn)
soc = pd.read_sql_query("SELECT * FROM soc_locations", conn)
competitors = pd.read_sql_query("SELECT * FROM competitors", conn)

conn.close()

print(f"✓ Loaded {len(cafes)} cafes ({len(soc)} SOC + {len(competitors)} competitors)")
print()

# ===== G5 FAMILY: MARKET POSITIONING COMPARISON =====
print("## G5 Family: Market Positioning Comparison")
print("   Question: How does SOC position relative to competitors?")
print()

# ---- g5-data-prep ----
print("### g5-data-prep: Preparing positioning metrics")

g5_data = cafes.copy()
g5_data['business_type'] = g5_data['name'].str.contains('Square One', case=False, na=False).map({
    True: 'Square One Coffee',
    False: 'Competitors'
})

# Calculate key metrics by type
positioning_metrics = g5_data.groupby('business_type').agg({
    'avg_beverage_price': 'mean',
    'google_rating': 'mean',
    'review_count': 'mean',
    'quality_score': 'mean',
    'seating_capacity': 'mean'
}).round(2)

print(f"✓ Positioning metrics calculated")
print(positioning_metrics)
print()

# ---- g51 ----
print("\n### g51: Key metrics comparison")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Prepare normalized metrics for radar chart style comparison
metrics_to_compare = ['avg_beverage_price', 'google_rating', 'quality_score', 'seating_capacity']
metric_labels = ['Avg Price', 'Rating', 'Quality Score', 'Seating']

# Normalize to 0-100 scale for comparison
soc_metrics = []
comp_metrics = []

for metric in metrics_to_compare:
    min_val = g5_data[metric].min()
    max_val = g5_data[metric].max()
    
    soc_val = positioning_metrics.loc['Square One Coffee', metric]
    comp_val = positioning_metrics.loc['Competitors', metric]
    
    # Normalize
    soc_norm = ((soc_val - min_val) / (max_val - min_val)) * 100 if max_val != min_val else 50
    comp_norm = ((comp_val - min_val) / (max_val - min_val)) * 100 if max_val != min_val else 50
    
    soc_metrics.append(soc_norm)
    comp_metrics.append(comp_norm)

# Bar chart comparison
x = np.arange(len(metric_labels))
width = 0.35

bars1 = ax.bar(x - width/2, comp_metrics, width, label='Competitors', 
               color='#457B9D', alpha=0.8, edgecolor='black')
bars2 = ax.bar(x + width/2, soc_metrics, width, label='Square One Coffee', 
               color='#E63946', alpha=0.8, edgecolor='black')

ax.set_xlabel('Performance Dimension', fontsize=11)
ax.set_ylabel('Normalized Score (0-100)', fontsize=11)
ax.set_title('SOC vs Market: Key Performance Metrics', 
             fontsize=13, fontweight='bold', pad=15)
ax.set_xticks(x)
ax.set_xticklabels(metric_labels)
ax.legend(framealpha=0.9)
ax.grid(axis='y', alpha=0.3)
ax.set_ylim(0, 105)

# Add value labels on bars
for bars in [bars1, bars2]:
    for bar in bars:
        height = bar.get_height()
        ax.text(bar.get_x() + bar.get_width()/2., height,
                f'{height:.0f}',
                ha='center', va='bottom', fontsize=8)

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g51_metrics_comparison.png", bbox_inches='tight')
print(f"✓ Saved: g51_metrics_comparison.png")
plt.close()

# ---- g52 ----
print("\n### g52: Price-Quality positioning matrix")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Calculate averages for quadrant lines
avg_price = g5_data['avg_beverage_price'].mean()
avg_rating = g5_data['google_rating'].mean()

# Scatter plot
for biz_type, label, color, marker, size in [
    ('Competitors', 'Competitors', '#457B9D', 'o', 80),
    ('Square One Coffee', 'Square One Coffee', '#E63946', 'D', 150)
]:
    mask = g5_data['business_type'] == biz_type
    subset = g5_data[mask]
    
    ax.scatter(subset['avg_beverage_price'], subset['google_rating'],
              s=size, c=color, marker=marker, 
              alpha=0.7, label=label, edgecolors='white', linewidth=1.5)

# Add quadrant lines
ax.axvline(avg_price, color='gray', linestyle='--', alpha=0.5, linewidth=2)
ax.axhline(avg_rating, color='gray', linestyle='--', alpha=0.5, linewidth=2)

# Label quadrants
ax.text(avg_price - 1.5, avg_rating + 0.35, 'High Quality\nLower Price', 
        ha='center', va='center', fontsize=9, style='italic', color='gray',
        bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
ax.text(avg_price + 1.5, avg_rating + 0.35, 'High Quality\nHigher Price', 
        ha='center', va='center', fontsize=9, style='italic', color='gray',
        bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

ax.set_xlabel('Average Beverage Price (CAD)', fontsize=11)
ax.set_ylabel('Google Rating (1-5)', fontsize=11)
ax.set_title('Competitive Positioning: Price vs Quality', 
             fontsize=13, fontweight='bold', pad=15)
ax.legend(loc='lower right', framealpha=0.9)
ax.grid(alpha=0.3)
ax.set_ylim(3.3, 5.1)

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g52_positioning_matrix.png", bbox_inches='tight')
print(f"✓ Saved: g52_positioning_matrix.png")
plt.close()

# ---- g53 ----
print("\n### g53: Market share by location zones")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Prepare data
zone_share = g5_data.groupby(['location_zone', 'business_type']).size().unstack(fill_value=0)
zone_share = zone_share.reindex(['core', 'inner', 'outer', 'peripheral'], fill_value=0)

# Calculate percentages
zone_share_pct = zone_share.div(zone_share.sum(axis=1), axis=0) * 100

# Stacked bar chart
zone_share_pct.plot(kind='bar', stacked=True, ax=ax, 
                    color=['#457B9D', '#E63946'], 
                    width=0.6)

ax.set_xlabel('Location Zone', fontsize=11)
ax.set_ylabel('Market Share (%)', fontsize=11)
ax.set_title('SOC Market Presence by Location Zone', 
             fontsize=13, fontweight='bold', pad=15)
ax.set_xticklabels(['Core\n(<2 km)', 'Inner\n(2-5 km)', 'Outer\n(5-10 km)', 'Peripheral\n(>10 km)'], 
                   rotation=0)
ax.legend(['Competitors', 'Square One Coffee'], framealpha=0.9, loc='upper left')
ax.grid(axis='y', alpha=0.3)
ax.set_ylim(0, 100)

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g53_market_share_zones.png", bbox_inches='tight')
print(f"✓ Saved: g53_market_share_zones.png")
plt.close()

print()

# ===== G6 FAMILY: QUALITY & REPUTATION ANALYSIS =====
print("## G6 Family: Quality & Reputation Analysis")
print("   Question: How does SOC's reputation compare?")
print()

# ---- g6-data-prep ----
print("### g6-data-prep: Preparing quality metrics")

g6_data = g5_data.copy()

print(f"✓ Quality data prepared: {len(g6_data)} cafes")

# ---- g61 ----
print("\n### g61: Rating distribution comparison")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Box plot
data_to_plot = [
    competitors['google_rating'].dropna(),
    soc['google_rating'].dropna()
]

bp = ax.boxplot(data_to_plot, labels=['Competitors', 'Square One Coffee'],
                patch_artist=True, widths=0.6,
                boxprops=dict(facecolor='lightblue', edgecolor='black'),
                medianprops=dict(color='red', linewidth=2),
                whiskerprops=dict(color='black'),
                capprops=dict(color='black'))

# Color boxes
colors = ['#457B9D', '#E63946']
for patch, color in zip(bp['boxes'], colors):
    patch.set_facecolor(color)
    patch.set_alpha(0.7)

# Add mean markers
means = [data.mean() for data in data_to_plot]
ax.plot([1, 2], means, 'D', color='gold', markersize=10, 
        markeredgecolor='black', markeredgewidth=1.5, label='Mean', zorder=3)

ax.set_ylabel('Google Rating (1-5)', fontsize=11)
ax.set_title('Rating Distribution: SOC vs Competitors', 
             fontsize=13, fontweight='bold', pad=15)
ax.legend(framealpha=0.9)
ax.grid(axis='y', alpha=0.3)
ax.set_ylim(3.3, 5.1)

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g61_rating_distribution.png", bbox_inches='tight')
print(f"✓ Saved: g61_rating_distribution.png")
plt.close()

# ---- g62 ----
print("\n### g62: Quality score comparison")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Scatter plot with size = review count
for biz_type, label, color, marker in [
    ('Competitors', 'Competitors', '#457B9D', 'o'),
    ('Square One Coffee', 'Square One Coffee', '#E63946', 'D')
]:
    mask = g6_data['business_type'] == biz_type
    subset = g6_data[mask]
    
    # Size proportional to review count
    sizes = (subset['review_count'] / subset['review_count'].max() * 200) + 50
    
    ax.scatter(subset['google_rating'], subset['quality_score'],
              s=sizes, c=color, marker=marker, 
              alpha=0.6, label=label, edgecolors='white', linewidth=1.5)

ax.set_xlabel('Google Rating (1-5)', fontsize=11)
ax.set_ylabel('Quality Score (rating × log(reviews+1))', fontsize=11)
ax.set_title('Quality Score Analysis (bubble size = review volume)', 
             fontsize=13, fontweight='bold', pad=15)
ax.legend(loc='lower right', framealpha=0.9)
ax.grid(alpha=0.3)

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g62_quality_score.png", bbox_inches='tight')
print(f"✓ Saved: g62_quality_score.png")
plt.close()

# ---- g63 ----
print("\n### g63: Reputation strength (reviews vs rating)")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Calculate average metrics
soc_avg_reviews = soc['review_count'].mean()
comp_avg_reviews = competitors['review_count'].mean()
soc_avg_rating = soc['google_rating'].mean()
comp_avg_rating = competitors['google_rating'].mean()

# Bar chart for comparison
categories = ['Review Volume\n(count)', 'Customer Rating\n(1-5 scale)']
x = np.arange(len(categories))
width = 0.35

# Normalize review count for visual comparison (scale to similar range as rating)
review_scale_factor = 5 / max(soc_avg_reviews, comp_avg_reviews)

comp_values = [comp_avg_reviews * review_scale_factor, comp_avg_rating]
soc_values = [soc_avg_reviews * review_scale_factor, soc_avg_rating]

bars1 = ax.bar(x - width/2, comp_values, width, label='Competitors', 
               color='#457B9D', alpha=0.8, edgecolor='black')
bars2 = ax.bar(x + width/2, soc_values, width, label='Square One Coffee', 
               color='#E63946', alpha=0.8, edgecolor='black')

ax.set_ylabel('Normalized Score', fontsize=11)
ax.set_title('Reputation Strength Comparison', 
             fontsize=13, fontweight='bold', pad=15)
ax.set_xticks(x)
ax.set_xticklabels(categories)
ax.legend(framealpha=0.9)
ax.grid(axis='y', alpha=0.3)

# Add actual values as labels
for bars, values, actual_reviews in [(bars1, comp_values, [comp_avg_reviews, comp_avg_rating]), 
                                      (bars2, soc_values, [soc_avg_reviews, soc_avg_rating])]:
    for i, bar in enumerate(bars):
        height = bar.get_height()
        if i == 0:  # Review count
            label = f'{actual_reviews[i]:.0f}'
        else:  # Rating
            label = f'{actual_reviews[i]:.2f}'
        ax.text(bar.get_x() + bar.get_width()/2., height,
                label, ha='center', va='bottom', fontsize=9, fontweight='bold')

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g63_reputation_strength.png", bbox_inches='tight')
print(f"✓ Saved: g63_reputation_strength.png")
plt.close()

print()

# ===== SUMMARY =====
print("=" * 70)
print("COMPETITIVE ANALYSIS COMPLETE")
print("=" * 70)
print(f"\nGenerated Visualizations:")
print(f"  G5 Family (Positioning): 3 graphs")
print(f"  G6 Family (Quality/Reputation): 3 graphs")
print(f"  Total: 6 visualizations in {PRINTS_FOLDER}")
print()
print("Key Competitive Insights:")
print(f"\nSquare One Coffee:")
print(f"  - Locations: {len(soc)}")
print(f"  - Avg Price: ${soc['avg_beverage_price'].mean():.2f}")
print(f"  - Avg Rating: {soc['google_rating'].mean():.2f}")
print(f"  - Avg Reviews: {soc['review_count'].mean():.0f}")
print(f"  - Quality Score: {soc['quality_score'].mean():.2f}")
print(f"\nCompetitor Average:")
print(f"  - Count: {len(competitors)}")
print(f"  - Avg Price: ${competitors['avg_beverage_price'].mean():.2f}")
print(f"  - Avg Rating: {competitors['google_rating'].mean():.2f}")
print(f"  - Avg Reviews: {competitors['review_count'].mean():.0f}")
print(f"  - Quality Score: {competitors['quality_score'].mean():.2f}")
print(f"\nCompetitive Advantages:")
price_diff = soc['avg_beverage_price'].mean() - competitors['avg_beverage_price'].mean()
rating_diff = soc['google_rating'].mean() - competitors['google_rating'].mean()
print(f"  - Price positioning: ${price_diff:+.2f} vs competitors (premium)")
print(f"  - Rating advantage: {rating_diff:+.2f} points")
print(f"  - Quality score advantage: {soc['quality_score'].mean() - competitors['quality_score'].mean():+.2f}")
print()
print("✅ Competitive positioning analysis complete!")
print("=" * 70)
