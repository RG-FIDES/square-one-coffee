#!/usr/bin/env python3
"""
RAP-1 Ferry: Raw to Derived Transformation (Python Implementation)

This script transforms raw Edmonton cafe data into analysis-ready datasets,
following the Ellis-pattern for data transformation.

Author: Research Team
Last Updated: 2025-12-12
"""

import sqlite3
import pandas as pd
import numpy as np
from datetime import datetime
import os
import sys
import math

# Configuration
INPUT_DB = "./data-private/raw/edmonton_cafes.sqlite"
OUTPUT_DB = "./data-private/derived/rap-1-competition-intel.sqlite"

# Edmonton geographic boundaries
EDMONTON_BOUNDS = {
    'lat_min': 53.40,
    'lat_max': 53.70,
    'lng_min': -113.70,
    'lng_max': -113.30
}

# Downtown reference point
DOWNTOWN_REF = {
    'lat': 53.5444,
    'lng': -113.4909
}

# Price range validation
PRICE_RANGE = {
    'min': 2.00,
    'max': 10.00
}

print("=" * 60)
print("RAP-1 FERRY: Raw → Derived Transformation")
print("=" * 60)
print(f"Start time: {datetime.now()}")
print()

# ===== 1. ENVIRONMENT SETUP =====
print("## 1. Environment Setup")
print(f"Input database: {INPUT_DB}")
print(f"Output database: {OUTPUT_DB}")

# Ensure output directory exists
output_dir = os.path.dirname(OUTPUT_DB)
if not os.path.exists(output_dir):
    os.makedirs(output_dir, exist_ok=True)
    print(f"✓ Created output directory: {output_dir}")

print("✓ Configuration loaded")
print()

# ===== 2. DATA IMPORT =====
print("## 2. Data Import")

# Connect to raw database
conn_raw = sqlite3.connect(INPUT_DB)

# List tables
cursor = conn_raw.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [row[0] for row in cursor.fetchall()]
print(f"Available tables: {', '.join(tables)}")

# Load cafes table
ds_raw = pd.read_sql_query("SELECT * FROM cafes", conn_raw)
conn_raw.close()

print(f"✓ Raw data loaded: {len(ds_raw)} records")
print(f"  Dimensions: {ds_raw.shape[0]} rows × {ds_raw.shape[1]} columns")
print()

# ===== 3. DATA VALIDATION =====
print("## 3. Data Validation")

validation_errors = 0
validation_warnings = 0

# Check required fields
print("\n### Validating required fields")
required_fields = ['cafe_id', 'name', 'neighborhood', 'cafe_type']
missing_required = ds_raw[required_fields].isna().any(axis=1)

if missing_required.any():
    print(f"❌ ERROR: {missing_required.sum()} records have missing required fields")
    print(ds_raw[missing_required][required_fields])
    sys.exit(1)
else:
    print("✓ All required fields present")

# Check uniqueness
print("\n### Validating uniqueness")
duplicates = ds_raw['cafe_id'].duplicated()
if duplicates.any():
    print(f"❌ ERROR: {duplicates.sum()} duplicate cafe_ids detected")
    sys.exit(1)
else:
    print("✓ No duplicate cafe_ids")

# Geographic validation
print("\n### Validating geographic coordinates")
has_coords = ds_raw['latitude'].notna() & ds_raw['longitude'].notna()
out_of_bounds = (
    (ds_raw['latitude'] < EDMONTON_BOUNDS['lat_min']) |
    (ds_raw['latitude'] > EDMONTON_BOUNDS['lat_max']) |
    (ds_raw['longitude'] < EDMONTON_BOUNDS['lng_min']) |
    (ds_raw['longitude'] > EDMONTON_BOUNDS['lng_max'])
)
location_warnings = has_coords & out_of_bounds

if location_warnings.any():
    print(f"⚠️  WARNING: {location_warnings.sum()} cafes have coordinates outside expected Edmonton bounds")
    validation_warnings += location_warnings.sum()
else:
    print("✓ All coordinates within expected bounds")

# Price validation
print("\n### Validating pricing data")
has_price = ds_raw['avg_beverage_price'].notna()
price_suspicious = (
    (ds_raw['avg_beverage_price'] < PRICE_RANGE['min']) |
    (ds_raw['avg_beverage_price'] > PRICE_RANGE['max'])
)
price_warnings = has_price & price_suspicious

if price_warnings.any():
    print(f"⚠️  WARNING: {price_warnings.sum()} cafes have prices outside typical range ($2-$10)")
    validation_warnings += price_warnings.sum()
else:
    print("✓ All prices within expected range")

# Rating validation
print("\n### Validating ratings data")
has_rating = ds_raw['google_rating'].notna()
invalid_rating = (
    (ds_raw['google_rating'] < 1.0) |
    (ds_raw['google_rating'] > 5.0)
)
rating_warnings = has_rating & invalid_rating

if rating_warnings.any():
    print(f"⚠️  WARNING: {rating_warnings.sum()} cafes have invalid ratings (will be set to NA)")
    validation_warnings += rating_warnings.sum()
else:
    print("✓ All ratings valid (1-5 scale)")

print()

# ===== 4. DATA TRANSFORMATION =====
print("## 4. Data Transformation")

# Create working copy
ds = ds_raw.copy()

# Standardization
print("\n### Standardizing categorical fields")
ds['neighborhood'] = ds['neighborhood'].str.strip().str.title()
ds['cafe_type'] = ds['cafe_type'].str.strip().str.lower()
ds['ownership'] = ds['ownership'].str.strip().str.lower()

# Fix invalid ratings
ds.loc[invalid_rating, 'google_rating'] = np.nan

# Ensure review_count is non-negative
ds.loc[ds['review_count'] < 0, 'review_count'] = np.nan

print("✓ Categorical fields standardized")

# Enrichment
print("\n### Adding derived fields")

# SOC identification
ds['is_soc'] = ds['name'].str.contains('square one', case=False, na=False)

# Price category
ds['price_category'] = pd.cut(
    ds['avg_beverage_price'],
    bins=[0, 3.50, 5.00, 6.50, float('inf')],
    labels=['budget', 'moderate', 'premium', 'luxury']
)

# Popularity percentile
ds['popularity_percentile'] = ds['review_count'].rank(pct=True)

# Quality score
ds['quality_score'] = ds['google_rating'] * np.log(ds['review_count'] + 1)

# Distance from downtown
def calculate_distance(row):
    if pd.isna(row['latitude']) or pd.isna(row['longitude']):
        return np.nan
    lat_diff = row['latitude'] - DOWNTOWN_REF['lat']
    lng_diff = row['longitude'] - DOWNTOWN_REF['lng']
    return math.sqrt(lat_diff**2 + lng_diff**2) * 111  # Convert to km

ds['distance_from_downtown'] = ds.apply(calculate_distance, axis=1)

# Location zone
ds['location_zone'] = pd.cut(
    ds['distance_from_downtown'],
    bins=[0, 2, 5, 10, float('inf')],
    labels=['core', 'inner', 'outer', 'peripheral']
)

print("✓ Derived fields added:")
print("  - is_soc: SOC location identifier")
print("  - price_category: budget/moderate/premium/luxury")
print("  - popularity_percentile: review count ranking")
print("  - quality_score: rating × log(reviews + 1)")
print("  - distance_from_downtown: km from downtown core")
print("  - location_zone: core/inner/outer/peripheral")

# Quality flags
print("\n### Adding quality flags")

ds['flag_missing_location'] = ds['latitude'].isna() | ds['longitude'].isna()
ds['flag_no_rating'] = ds['google_rating'].isna()
ds['flag_no_price'] = ds['avg_beverage_price'].isna()
ds['flag_location_out_of_bounds'] = out_of_bounds.fillna(False)
ds['flag_suspicious_price'] = price_suspicious.fillna(False)

# Count quality issues
quality_flags = [
    'flag_missing_location', 'flag_no_rating', 'flag_no_price',
    'flag_location_out_of_bounds', 'flag_suspicious_price'
]
ds['quality_flag_count'] = ds[quality_flags].sum(axis=1)

# Quality tier
ds['quality_tier'] = pd.cut(
    ds['quality_flag_count'],
    bins=[-1, 0, 1, 2, float('inf')],
    labels=['excellent', 'good', 'acceptable', 'poor']
)

print("✓ Quality flags added")
print()

# ===== 5. CREATE ANALYSIS TABLES =====
print("## 5. Create Analysis Tables")

cafes_complete = ds.copy()
soc_locations = ds[ds['is_soc']].drop(columns=['is_soc']).copy()
competitors = ds[~ds['is_soc']].drop(columns=['is_soc']).copy()

print("✓ Tables created:")
print(f"  - cafes_complete: {len(cafes_complete)} records")
print(f"  - soc_locations: {len(soc_locations)} records")
print(f"  - competitors: {len(competitors)} records")

# Quality metrics
print("\n### Calculating quality metrics")

completeness_metrics = pd.DataFrame({
    'field': ds_raw.columns,
    'total_records': len(ds_raw),
    'complete_count': ds_raw.notna().sum(),
    'missing_count': ds_raw.isna().sum(),
    'complete_rate': ds_raw.notna().sum() / len(ds_raw)
}).sort_values('complete_rate')

quality_distribution = ds['quality_tier'].value_counts().reset_index()
quality_distribution.columns = ['quality_tier', 'count']
quality_distribution['percentage'] = (quality_distribution['count'] / len(ds) * 100).round(1)

print("✓ Quality metrics calculated")

# Metadata
print("\n### Creating metadata record")

metadata = pd.DataFrame([{
    'ferry_date': datetime.now().isoformat(),
    'python_version': sys.version.split()[0],
    'pandas_version': pd.__version__,
    'input_file': INPUT_DB,
    'input_records': len(ds_raw),
    'output_file': OUTPUT_DB,
    'output_records': len(ds),
    'validation_errors': validation_errors,
    'validation_warnings': validation_warnings,
    'avg_completeness': completeness_metrics['complete_rate'].mean() * 100
}])

print("✓ Metadata created")
print()

# ===== 6. WRITE TO DERIVED DATABASE =====
print("## 6. Write to Derived Database")

# Remove existing database if it exists
if os.path.exists(OUTPUT_DB):
    os.remove(OUTPUT_DB)

# Connect to derived database
conn_derived = sqlite3.connect(OUTPUT_DB)

# Write all tables
cafes_complete.to_sql('cafes_complete', conn_derived, index=False)
soc_locations.to_sql('soc_locations', conn_derived, index=False)
competitors.to_sql('competitors', conn_derived, index=False)
completeness_metrics.to_sql('completeness_metrics', conn_derived, index=False)
quality_distribution.to_sql('quality_distribution', conn_derived, index=False)
metadata.to_sql('metadata', conn_derived, index=False)

conn_derived.close()

print(f"✓ All tables written to: {OUTPUT_DB}")
print("  Tables: cafes_complete, soc_locations, competitors, completeness_metrics, quality_distribution, metadata")
print()

# ===== 7. FERRY SUMMARY REPORT =====
print("## 7. Ferry Summary Report")
print()
print("===== FERRY VALIDATION REPORT =====")
print(f"Input records: {len(ds_raw)}")
print(f"Output records: {len(ds)}")
print(f"Records dropped: {len(ds_raw) - len(ds)}")
print()
print(f"ERROR-level issues: {validation_errors}")
if validation_errors == 0:
    print("  (Ferry would have stopped if errors occurred)")
print()
print(f"WARNING-level issues: {validation_warnings}")
if location_warnings.any():
    print(f"  - Out-of-bounds coordinates: {location_warnings.sum()} records")
if price_warnings.any():
    print(f"  - Suspicious pricing: {price_warnings.sum()} records")
if rating_warnings.any():
    print(f"  - Invalid ratings: {rating_warnings.sum()} records")
print()
print("INFO messages:")
print(f"  - Average completeness: {completeness_metrics['complete_rate'].mean() * 100:.1f}%")
low_complete = completeness_metrics[completeness_metrics['complete_rate'] < 0.75]
if not low_complete.empty:
    print(f"  - Low completeness fields: {', '.join(low_complete['field'].tolist())}")
print()
print("Quality tier distribution:")
for _, row in quality_distribution.iterrows():
    print(f"  - {row['quality_tier']}: {row['count']} ({row['percentage']}%)")
print()
print("Square One Coffee:")
print(f"  - Locations: {len(soc_locations)}")
print(f"  - Avg quality score: {soc_locations['quality_score'].mean():.2f}")
print()
print("Competitors:")
print(f"  - Count: {len(competitors)}")
print(f"  - Avg quality score: {competitors['quality_score'].mean():.2f}")
print()
print("===================================")
print()
print(f"✅ Ferry completed successfully at {datetime.now()}")
print("=" * 60)
