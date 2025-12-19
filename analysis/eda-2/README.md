# EDA-2: Cafe Undersaturation Analysis

**Research Question**: Which Edmonton neighborhoods are over- or under-served by cafes?

**Analysis Date**: December 19, 2025  
**Status**: ✅ Complete

---

## Overview

This analysis identifies geographic gaps in Edmonton's cafe coverage by calculating service metrics (people per cafe, cafes per 1,000 residents) at the neighborhood level. The analysis aggregates data from the Ellis-6 pipeline, which spatially joins cafe locations with demographic information.

### Key Outputs

- **Neighborhood-level service metrics** (cafe count, people per cafe, cafes per capita)
- **Visualizations** comparing coverage across population density categories
- **Rankings** of most underserved and best-served neighborhoods
- **Statistical analysis** (correlation, ANOVA, outlier detection)
- **Strategic recommendations** for Square One Coffee expansion

---

## Files in This Directory

```
eda-2/
├── eda-2.R              # Development script (run chunks interactively)
├── eda-2.qmd            # Publication document (render for HTML report)
├── README.md            # This file
├── data-local/          # Intermediate datasets (gitignored)
│   ├── ds_neighborhood.rds
│   └── ds_neighborhood_categorized.rds
└── prints/              # Saved visualizations (300 DPI PNG)
    ├── g1_population_vs_cafes.png
    ├── g11_population_vs_cafes_density.png
    ├── g2_cafes_by_density.png
    ├── g21_underserved_top20.png
    ├── g22_wellserved_top20.png
    ├── g3_distribution.png
    └── g31_boxplot_density.png
```

---

## Data Sources

### Primary Dataset
- **Table**: `ellis_6_cafes_with_demographics`
- **Database**: `data-private/derived/global-data.sqlite`
- **Records**: 1,864 cafes with neighborhood assignments
- **Key Fields**: 
  - `name`, `address` (cafe identifiers)
  - `neighborhood` (spatial join from Ellis-4)
  - `population`, `area`, `density_of_population` (demographics from Ellis-5)

### Dependencies
- **Ellis-0**: Google Places cafe data (lat/lng, business details)
- **Ellis-4**: Neighborhood boundary geometries (GeoJSON polygons)
- **Ellis-5**: Population by neighborhood
- **Ellis-6**: Spatial transformation combining above sources

---

## Methodology

### Service Metrics

**People per Cafe** (Primary undersaturation metric):
```
people_per_cafe = neighborhood_population / cafe_count
```
- **Interpretation**: Higher values = more underserved
- **Typical range**: 200-1,500 people per cafe
- **Outlier threshold**: >2 SD above mean (severe undersaturation)

**Cafes per 1,000 Residents** (Alternative coverage metric):
```
cafes_per_1000 = (cafe_count / population) * 1000
```
- **Interpretation**: Higher values = better served
- **Typical range**: 0.5-5 cafes per 1,000 people

### Density Categories

Neighborhoods classified by population density (people per sq km):
- **Low**: <2,000
- **Moderate**: 2,000-5,000
- **High**: 5,000-10,000
- **Very High**: >10,000

### Statistical Tests

1. **Correlation**: Pearson correlation between population density and cafes per capita
2. **ANOVA**: Test if cafe coverage differs across density categories
3. **Outlier Detection**: Identify neighborhoods >2 SD above mean people-per-cafe

---

## Workflow

### Interactive Development (eda-2.R)

**Recommended execution pattern**:

1. **Setup** (run once per session):
   ```r
   # Execute setup chunks
   # ---- load-packages ----
   # ---- load-sources ----
   # ---- declare-globals ----
   ```

2. **Load data**:
   ```r
   # ---- load-data ----
   # ---- inspect-data-0 ----
   # ---- tweak-data-0 ----
   ```

3. **Develop analysis** (iterate on chunks):
   ```r
   # ---- g1-data-prep ----      # Create ds_neighborhood
   # ---- inspect-data-1 ----    # Examine aggregation
   # ---- g1 ----                # Generate visualization
   # Check prints/g1_population_vs_cafes.png
   ```

4. **Continue through families**:
   - g1 family: Population vs cafe scatter plots
   - g2 family: Density category comparisons and rankings
   - g3 family: Distribution analyses
   - t1-t3: Statistical tests

### Publication (eda-2.qmd)

**Render HTML report**:
```r
quarto::quarto_render("analysis/eda-2/eda-2.qmd")
```

Or in terminal:
```bash
quarto render analysis/eda-2/eda-2.qmd
```

**Output**: `analysis/eda-2/eda-2.html` (self-contained report)

---

## Key Findings

### Undersaturation Patterns

1. **Population drives presence**: Strong positive correlation between population and cafe count
2. **Density matters**: Coverage (cafes per capita) varies significantly across density categories
3. **Outliers exist**: 20+ neighborhoods are statistically underserved (>2 SD threshold)
4. **Not just density**: Low-density neighborhoods show highest variability in service coverage

### Strategic Implications

**For Square One Coffee**:
- **Expansion opportunities**: Top 20 underserved neighborhoods represent unmet demand
- **Saturation risk**: Top 20 best-served neighborhoods face intense competition
- **Further analysis needed**: Cross-reference with transit, property values, competitor quality

**Next Steps**:
1. Join Ellis-0 data to weight cafe count by quality/ratings
2. Spatial proximity analysis to identify neighborhoods near existing SOC locations
3. Demographic profiling to match underserved areas with SOC target customers
4. Feasibility assessment (property costs, transit access, traffic volume)

---

## Visualization Guide

### Graph Families

**G1 Family: Population-Cafe Relationships**
- `g1`: Basic scatter plot with linear regression
- `g11`: Same scatter, colored by density category
- **Use case**: Understand how population predicts cafe presence

**G2 Family: Undersaturation Rankings**
- `g2`: Average cafes per 1,000 by density category
- `g21`: Top 20 most underserved neighborhoods (horizontal bars)
- `g22`: Top 20 best served neighborhoods (horizontal bars)
- **Use case**: Identify specific expansion targets or saturated markets

**G3 Family: Distribution Analyses**
- `g3`: Histogram of people per cafe (overall distribution)
- `g31`: Boxplot of people per cafe by density category
- **Use case**: Understand service coverage variability and outliers

### Design Specifications

All visualizations follow eda-1 style guide:
- **Dimensions**: 8.5 × 5.5 inches (letter half-page portrait)
- **Resolution**: 300 DPI
- **Format**: PNG
- **Theme**: `theme_minimal()` with custom adjustments
- **Colors**: Colorblind-safe palettes (from graph-presets.R)

---

## Reproducibility Notes

### R Session Requirements

**Core packages**:
```r
tidyverse (dplyr, ggplot2, tidyr, forcats, stringr)
DBI, RSQLite      # Database access
fs                # File system operations
scales            # Number formatting
```

**Custom utilities**:
```r
scripts/common-functions.R      # print_all(), neat(), etc.
scripts/operational-functions.R # Database helpers
scripts/graphing/graph-presets.R # Color palettes
```

### Data Dependencies

**Required files**:
- `data-private/derived/global-data.sqlite` (Ellis pipeline output)
  - Must contain `ellis_6_cafes_with_demographics` table
  - Run Ellis pipeline (ellis-0 through ellis-last) if missing

**Generated files** (gitignored):
- `analysis/eda-2/data-local/*.rds` (intermediate datasets)
- `analysis/eda-2/prints/*.png` (visualizations)
- `data-private/derived/eda-2/*.csv` (final outputs for external use)

### Execution Time

- **eda-2.R** (interactive): ~5-10 minutes (depending on database connection)
- **eda-2.qmd** (render): ~2-3 minutes (chunks cached after first run)

---

## Chunk Reference

### Setup Chunks
- `load-packages`: Library attachments
- `load-sources`: Source utility functions
- `declare-globals`: Directory paths and creation
- `declare-functions`: Analysis-specific functions (if needed)
- `httpgd`: VS Code interactive plotting

### Data Chunks
- `load-data`: Connect to SQLite, load ellis_6 table
- `inspect-data-0`: Initial data exploration
- `tweak-data-0`: Filter out missing neighborhoods
- `inspect-data-1`: Examine neighborhood aggregation

### Analysis Chunks
- `g1-data-prep`: Create ds_neighborhood (service metrics)
- `g2-data-prep`: Add density categories
- `g1`, `g11`: Population vs cafe scatter plots
- `g2`, `g21`, `g22`: Density comparisons and rankings
- `g3`, `g31`: Distribution analyses
- `t1-correlation`: Correlation test
- `t2-anova`: ANOVA with post-hoc
- `t3-outliers`: Identify statistically underserved neighborhoods

---

## Questions for Further Exploration

1. **Quality weighting**: Should we weight cafe count by ratings/reviews from Ellis-0?
2. **Transit accessibility**: How many underserved neighborhoods are transit-accessible (Ellis-2)?
3. **Property costs**: Can SOC afford locations in underserved areas (Ellis-1)?
4. **Traffic visibility**: Do underserved neighborhoods have high-traffic sites (Ellis-3)?
5. **Temporal changes**: Has undersaturation changed over time (requires historical data)?
6. **Customer demographics**: Do underserved neighborhoods match SOC target profile?
7. **Competitor analysis**: What's the quality of cafes in "well-served" neighborhoods?
8. **Supply vs demand**: Do high people-per-cafe ratios reflect unmet demand or low demand density?

---

## Contact & Contribution

**Project**: Square One Coffee Research Partnership  
**Repository**: RB-FIDES/square-one-coffee  
**Documentation**: See `ai/project/` for mission, methodology, glossary

**Questions or issues**: Document in `ai/memory/memory-human.md` for collaborative review
