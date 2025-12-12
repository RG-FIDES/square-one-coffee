#!/usr/bin/env python3
"""
RAP-0 Market Overview Analysis

Analyzes the Edmonton coffee market competitive landscape with focus on:
- Geographic distribution (g2 family)
- Pricing landscape (g3 family)
- Market segmentation (g4 family)

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
DB_PATH = "./data-private/derived/rap-0-competition-intel.sqlite"
PRINTS_FOLDER = "./analysis/rap-0/prints/"
FIG_WIDTH = 8.5
FIG_HEIGHT = 5.5

print("=" * 70)
print("RAP-0 MARKET OVERVIEW ANALYSIS")
print("=" * 70)
print(f"Edmonton Coffee Market Competitive Intelligence")
print()

# Create prints folder
Path(PRINTS_FOLDER).mkdir(parents=True, exist_ok=True)
print(f"✓ Prints folder: {PRINTS_FOLDER}")

# ===== LOAD DATA =====
print("\n## Loading Data")

conn = sqlite3.connect(DB_PATH)

cafes = pd.read_sql_query("SELECT * FROM cafes_complete", conn)
soc = pd.read_sql_query("SELECT * FROM soc_locations", conn)
competitors = pd.read_sql_query("SELECT * FROM competitors", conn)

conn.close()

print(f"✓ Loaded {len(cafes)} cafes ({len(soc)} SOC + {len(competitors)} competitors)")
print()

# ===== G2 FAMILY: GEOGRAPHIC DISTRIBUTION =====
print("## G2 Family: Geographic Distribution Analysis")
print("   Question: Where are cafes concentrated in Edmonton?")
print()

# ---- g2-data-prep ----
print("### g2-data-prep: Preparing geographic summary")

g2_data = cafes.copy()
g2_data['is_soc'] = g2_data['name'].str.contains('Square One', case=False, na=False)

geo_summary = g2_data.groupby(['neighborhood', 'is_soc']).agg({
    'cafe_id': 'count',
    'avg_beverage_price': 'mean',
    'google_rating': 'mean',
    'review_count': 'sum'
}).reset_index()
geo_summary.columns = ['neighborhood', 'is_soc', 'count', 'avg_price', 'avg_rating', 'total_reviews']

print(f"✓ Geographic summary prepared: {len(geo_summary)} neighborhood-type combinations")

# ---- g21 ----
print("\n### g21: Cafe concentration by neighborhood")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Aggregate by neighborhood
neighborhood_counts = g2_data.groupby('neighborhood')['cafe_id'].count().sort_values(ascending=True)

# Create bar chart
colors = ['#2E86AB' if nbhd in soc['neighborhood'].values else '#A23B72' 
          for nbhd in neighborhood_counts.index]

neighborhood_counts.plot(kind='barh', ax=ax, color=colors)

ax.set_xlabel('Number of Cafes', fontsize=11)
ax.set_ylabel('Neighborhood', fontsize=11)
ax.set_title('Cafe Concentration Across Edmonton Neighborhoods', 
             fontsize=13, fontweight='bold', pad=15)
ax.grid(axis='x', alpha=0.3)

# Add legend
from matplotlib.patches import Patch
legend_elements = [
    Patch(facecolor='#2E86AB', label='Has SOC location'),
    Patch(facecolor='#A23B72', label='No SOC presence')
]
ax.legend(handles=legend_elements, loc='lower right', framealpha=0.9)

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g21_cafe_concentration.png", bbox_inches='tight')
print(f"✓ Saved: g21_cafe_concentration.png")
plt.close()

# ---- g22 ----
print("\n### g22: Geographic distribution map")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Scatter plot by location type
for is_soc_val, label, color, marker, size in [
    (True, 'Square One Coffee', '#E63946', 'D', 120),
    (False, 'Competitors', '#457B9D', 'o', 60)
]:
    mask = g2_data['is_soc'] == is_soc_val
    subset = g2_data[mask]
    
    ax.scatter(subset['longitude'], subset['latitude'],
              s=size, c=color, marker=marker, 
              alpha=0.7, label=label, edgecolors='white', linewidth=1.5)

ax.set_xlabel('Longitude', fontsize=11)
ax.set_ylabel('Latitude', fontsize=11)
ax.set_title('Edmonton Cafe Geographic Distribution', 
             fontsize=13, fontweight='bold', pad=15)
ax.legend(loc='best', framealpha=0.9, fontsize=9)
ax.grid(alpha=0.3)

# Add downtown reference
ax.scatter([-113.4909], [53.5444], s=200, c='gold', marker='*', 
          edgecolors='black', linewidth=2, label='Downtown Core', zorder=3)

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g22_geographic_map.png", bbox_inches='tight')
print(f"✓ Saved: g22_geographic_map.png")
plt.close()

# ---- g23 ----
print("\n### g23: Location zones distribution")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Prepare data
zone_data = g2_data.groupby(['location_zone', 'is_soc']).size().unstack(fill_value=0)
zone_data = zone_data.reindex(['core', 'inner', 'outer', 'peripheral'], fill_value=0)

# Stacked bar chart
zone_data.plot(kind='bar', stacked=True, ax=ax, 
               color=['#457B9D', '#E63946'], 
               width=0.6)

ax.set_xlabel('Location Zone', fontsize=11)
ax.set_ylabel('Number of Cafes', fontsize=11)
ax.set_title('Cafe Distribution by Distance from Downtown', 
             fontsize=13, fontweight='bold', pad=15)
ax.set_xticklabels(['Core\n(<2 km)', 'Inner\n(2-5 km)', 'Outer\n(5-10 km)', 'Peripheral\n(>10 km)'], 
                   rotation=0)
ax.legend(['Competitors', 'Square One Coffee'], framealpha=0.9)
ax.grid(axis='y', alpha=0.3)

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g23_location_zones.png", bbox_inches='tight')
print(f"✓ Saved: g23_location_zones.png")
plt.close()

print()

# ===== G3 FAMILY: PRICING LANDSCAPE =====
print("## G3 Family: Pricing Landscape Analysis")
print("   Question: How does pricing position competitors in the market?")
print()

# ---- g3-data-prep ----
print("### g3-data-prep: Preparing pricing analysis")

g3_data = cafes[cafes['avg_beverage_price'].notna()].copy()
g3_data['is_soc'] = g3_data['name'].str.contains('Square One', case=False, na=False)

print(f"✓ Pricing data prepared: {len(g3_data)} cafes with price information")

# ---- g31 ----
print("\n### g31: Price distribution histogram")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Separate SOC and competitor prices
soc_prices = g3_data[g3_data['is_soc']]['avg_beverage_price']
comp_prices = g3_data[~g3_data['is_soc']]['avg_beverage_price']

# Histograms
ax.hist(comp_prices, bins=15, alpha=0.6, color='#457B9D', label='Competitors', edgecolor='black')
ax.hist(soc_prices, bins=10, alpha=0.8, color='#E63946', label='Square One Coffee', edgecolor='black')

# Add mean lines
ax.axvline(comp_prices.mean(), color='#1D3557', linestyle='--', linewidth=2, 
          label=f'Competitor Mean: ${comp_prices.mean():.2f}')
ax.axvline(soc_prices.mean(), color='#A01A1A', linestyle='--', linewidth=2, 
          label=f'SOC Mean: ${soc_prices.mean():.2f}')

ax.set_xlabel('Average Beverage Price (CAD)', fontsize=11)
ax.set_ylabel('Number of Cafes', fontsize=11)
ax.set_title('Edmonton Coffee Market Price Distribution', 
             fontsize=13, fontweight='bold', pad=15)
ax.legend(framealpha=0.9, fontsize=9)
ax.grid(axis='y', alpha=0.3)

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g31_price_distribution.png", bbox_inches='tight')
print(f"✓ Saved: g31_price_distribution.png")
plt.close()

# ---- g32 ----
print("\n### g32: Price categories by location type")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Prepare data
price_cat_data = g3_data.groupby(['price_category', 'is_soc']).size().unstack(fill_value=0)
price_cat_data = price_cat_data.reindex(['budget', 'moderate', 'premium', 'luxury'], fill_value=0)

# Grouped bar chart
price_cat_data.plot(kind='bar', ax=ax, 
                    color=['#457B9D', '#E63946'], 
                    width=0.7)

ax.set_xlabel('Price Category', fontsize=11)
ax.set_ylabel('Number of Cafes', fontsize=11)
ax.set_title('Market Segmentation by Price Point', 
             fontsize=13, fontweight='bold', pad=15)
ax.set_xticklabels(['Budget\n(<$3.50)', 'Moderate\n($3.50-$5.00)', 
                   'Premium\n($5.00-$6.50)', 'Luxury\n(>$6.50)'], rotation=0)
ax.legend(['Competitors', 'Square One Coffee'], framealpha=0.9)
ax.grid(axis='y', alpha=0.3)

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g32_price_categories.png", bbox_inches='tight')
print(f"✓ Saved: g32_price_categories.png")
plt.close()

# ---- g33 ----
print("\n### g33: Price vs Quality positioning")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Scatter plot
for is_soc_val, label, color, marker, size in [
    (False, 'Competitors', '#457B9D', 'o', 80),
    (True, 'Square One Coffee', '#E63946', 'D', 150)
]:
    mask = g3_data['is_soc'] == is_soc_val
    subset = g3_data[mask]
    
    ax.scatter(subset['avg_beverage_price'], subset['google_rating'],
              s=size, c=color, marker=marker, 
              alpha=0.7, label=label, edgecolors='white', linewidth=1.5)

ax.set_xlabel('Average Beverage Price (CAD)', fontsize=11)
ax.set_ylabel('Google Rating (1-5)', fontsize=11)
ax.set_title('Price-Quality Positioning Map', 
             fontsize=13, fontweight='bold', pad=15)
ax.legend(loc='best', framealpha=0.9)
ax.grid(alpha=0.3)
ax.set_ylim(3.3, 5.1)

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g33_price_quality_map.png", bbox_inches='tight')
print(f"✓ Saved: g33_price_quality_map.png")
plt.close()

print()

# ===== G4 FAMILY: MARKET SEGMENTATION =====
print("## G4 Family: Market Segmentation Analysis")
print("   Question: How do cafe types and characteristics segment the market?")
print()

# ---- g4-data-prep ----
print("### g4-data-prep: Preparing market segmentation")

g4_data = cafes.copy()
g4_data['is_soc'] = g4_data['name'].str.contains('Square One', case=False, na=False)

print(f"✓ Segmentation data prepared: {len(g4_data)} cafes")

# ---- g41 ----
print("\n### g41: Cafe type distribution")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Prepare data
type_data = g4_data.groupby(['cafe_type', 'is_soc']).size().unstack(fill_value=0)

# Horizontal bar chart
type_data.plot(kind='barh', stacked=True, ax=ax, 
               color=['#457B9D', '#E63946'])

ax.set_xlabel('Number of Cafes', fontsize=11)
ax.set_ylabel('Cafe Type', fontsize=11)
ax.set_title('Edmonton Market Segmentation by Cafe Type', 
             fontsize=13, fontweight='bold', pad=15)
ax.legend(['Competitors', 'Square One Coffee'], framealpha=0.9, loc='lower right')
ax.grid(axis='x', alpha=0.3)

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g41_cafe_type_distribution.png", bbox_inches='tight')
print(f"✓ Saved: g41_cafe_type_distribution.png")
plt.close()

# ---- g42 ----
print("\n### g42: Ownership structure")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Count by ownership
ownership_counts = g4_data['ownership'].value_counts()

colors = ['#E63946', '#457B9D', '#F1A208', '#2A9D8F']
explode = [0.05 if own == 'independent' else 0 for own in ownership_counts.index]

ax.pie(ownership_counts.values, labels=ownership_counts.index, autopct='%1.1f%%',
       colors=colors, explode=explode, startangle=90, 
       textprops={'fontsize': 10})

ax.set_title('Edmonton Coffee Market Ownership Structure', 
             fontsize=13, fontweight='bold', pad=15)

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g42_ownership_structure.png", bbox_inches='tight')
print(f"✓ Saved: g42_ownership_structure.png")
plt.close()

# ---- g43 ----
print("\n### g43: Food offerings comparison")

fig, ax = plt.subplots(figsize=(FIG_WIDTH, FIG_HEIGHT))

# Prepare data
food_data = g4_data.groupby(['has_food', 'is_soc']).size().unstack(fill_value=0)
food_order = ['none', 'pastries_only', 'sandwiches_pastries', 'full_menu']
food_data = food_data.reindex(food_order, fill_value=0)

# Grouped bar chart
food_data.plot(kind='bar', ax=ax, 
               color=['#457B9D', '#E63946'], 
               width=0.7)

ax.set_xlabel('Food Offerings', fontsize=11)
ax.set_ylabel('Number of Cafes', fontsize=11)
ax.set_title('Food Service Offerings Across Market', 
             fontsize=13, fontweight='bold', pad=15)
ax.set_xticklabels(['None', 'Pastries\nOnly', 'Sandwiches &\nPastries', 'Full\nMenu'], rotation=0)
ax.legend(['Competitors', 'Square One Coffee'], framealpha=0.9)
ax.grid(axis='y', alpha=0.3)

plt.tight_layout()
plt.savefig(f"{PRINTS_FOLDER}g43_food_offerings.png", bbox_inches='tight')
print(f"✓ Saved: g43_food_offerings.png")
plt.close()

print()

# ===== SUMMARY =====
print("=" * 70)
print("ANALYSIS COMPLETE")
print("=" * 70)
print(f"\nGenerated Visualizations:")
print(f"  G2 Family (Geographic): 3 graphs")
print(f"  G3 Family (Pricing): 3 graphs")
print(f"  G4 Family (Segmentation): 3 graphs")
print(f"  Total: 9 visualizations in {PRINTS_FOLDER}")
print()
print("Key Insights:")
print(f"  - {len(cafes)} total cafes analyzed")
print(f"  - {len(soc)} Square One Coffee locations")
print(f"  - {len(competitors)} competitor cafes")
print(f"  - SOC avg price: ${soc_prices.mean():.2f} vs Competitors: ${comp_prices.mean():.2f}")
print(f"  - SOC avg rating: {soc['google_rating'].mean():.2f} vs Competitors: {competitors['google_rating'].mean():.2f}")
print()
print("✅ Market overview analysis complete!")
print("=" * 70)
