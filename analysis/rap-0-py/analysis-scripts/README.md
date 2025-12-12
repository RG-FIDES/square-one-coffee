# RAP-0 Analysis Scripts

This directory contains the analysis scripts for the Edmonton Coffee Competition Intelligence pipeline.

## Overview

These scripts transform derived data into actionable intelligence through comprehensive market analysis and visualization. All scripts follow the EDA style guide with standardized dimensions (8.5 × 5.5 inches, 300 DPI) and graph family organization.

## Scripts

### 1. `rap-0-market-overview.py`

**Purpose**: Comprehensive market analysis of Edmonton's coffee landscape

**Graph Families**:

- **G2 Family - Geographic Distribution** (Question: Where are cafes concentrated?)
  - `g21_cafe_concentration.png` - Cafe count by neighborhood
  - `g22_geographic_map.png` - Spatial distribution map with coordinates
  - `g23_location_zones.png` - Distribution by distance from downtown

- **G3 Family - Pricing Landscape** (Question: How does pricing position competitors?)
  - `g31_price_distribution.png` - Price distribution histogram with SOC vs competitors
  - `g32_price_categories.png` - Market segmentation by price point
  - `g33_price_quality_map.png` - Price-quality positioning scatter plot

- **G4 Family - Market Segmentation** (Question: How do characteristics segment the market?)
  - `g41_cafe_type_distribution.png` - Distribution by cafe type
  - `g42_ownership_structure.png` - Ownership structure pie chart
  - `g43_food_offerings.png` - Food service offerings comparison

**Output**: 9 visualizations in `../prints/`

**Key Insights**:
- Market size and competitive density
- Geographic concentration patterns
- Price positioning across market segments
- SOC's market presence vs competitors

---

### 2. `rap-0-competitive-position.py`

**Purpose**: Square One Coffee competitive positioning analysis

**Graph Families**:

- **G5 Family - Market Positioning** (Question: How does SOC position relative to competitors?)
  - `g51_metrics_comparison.png` - Key performance metrics bar chart
  - `g52_positioning_matrix.png` - Price-quality positioning quadrant analysis
  - `g53_market_share_zones.png` - Market share by location zone

- **G6 Family - Quality & Reputation** (Question: How does SOC's reputation compare?)
  - `g61_rating_distribution.png` - Rating distribution boxplot comparison
  - `g62_quality_score.png` - Quality score scatter with review volume
  - `g63_reputation_strength.png` - Reputation metrics comparison

**Output**: 6 visualizations in `../prints/`

**Key Insights**:
- SOC premium positioning ($5.38 vs $4.98 competitor average)
- Rating advantage (+0.47 points higher than competitors)
- Quality score advantage (+4.53 points)
- Geographic coverage and market share by zone

---

## Data Flow

```
Derived Database (rap-0-competition-intel.sqlite)
    ↓
[Analysis Scripts] (Python with pandas, matplotlib, seaborn)
    ↓
Visualizations (../prints/*.png)
    ↓
Business Intelligence Reports
```

## Running the Scripts

### Prerequisites

```bash
pip install pandas numpy matplotlib seaborn
```

### Execution

```bash
# Market overview analysis
python3 rap-0-market-overview.py

# Competitive positioning analysis
python3 rap-0-competitive-position.py
```

**Note**: Scripts expect the derived database at `./data-private/derived/rap-0-competition-intel.sqlite`. Run the ferry script first if database doesn't exist.

## Graph Family Concept

Each analysis uses the **graph family** pattern from the EDA style guide:

- **Data Ancestor** (`gX-data-prep`): Common data preparation representing an analytical perspective
- **Family Members** (`gX1`, `gX2`, `gX3`...): Individual visualizations exploring that perspective
- **Unique Identifiers**: Each graph has a memorable ID for easy reference

**Example**:
```python
# ---- g2-data-prep ----
# Data ancestor: "Where are cafes concentrated in Edmonton?"
geo_summary = cafes.groupby(['neighborhood', 'cafe_type']).agg(...)

# ---- g21 ----
# Family member: Overall concentration
g21_cafe_map = geo_summary.plot(...)

# ---- g22 ----
# Family member: Detailed spatial view
g22_downtown_detail = geo_summary[subset].plot(...)
```

## Visualization Standards

All graphs adhere to project standards:

- **Dimensions**: 8.5 × 5.5 inches (letter half-page portrait)
- **Resolution**: 300 DPI (publication quality)
- **Format**: PNG
- **Naming**: Descriptive with unique graph ID (e.g., `g21_cafe_concentration.png`)
- **Color Scheme**: 
  - SOC: `#E63946` (red)
  - Competitors: `#457B9D` (blue)
  - Neutral: `#2E86AB`, `#A23B72`, `#F1A208`, `#2A9D8F`

## Output Organization

```
analysis/rap-0/prints/
├── g21_cafe_concentration.png       # Market overview - geographic
├── g22_geographic_map.png
├── g23_location_zones.png
├── g31_price_distribution.png       # Market overview - pricing
├── g32_price_categories.png
├── g33_price_quality_map.png
├── g41_cafe_type_distribution.png   # Market overview - segmentation
├── g42_ownership_structure.png
├── g43_food_offerings.png
├── g51_metrics_comparison.png       # Competitive positioning
├── g52_positioning_matrix.png
├── g53_market_share_zones.png
├── g61_rating_distribution.png      # Quality & reputation
├── g62_quality_score.png
└── g63_reputation_strength.png
```

## Key Findings Summary

### Market Overview
- **30 total cafes** analyzed (6 SOC + 24 competitors)
- **15 neighborhoods** covered across Edmonton
- **Average price**: $5.09 CAD (range: $3.00-$7.50)
- **Market segments**: Budget (9%), Moderate (43%), Premium (37%), Luxury (11%)
- **Ownership**: 70% independent, 30% chains

### SOC Competitive Position
- **Premium pricing**: $0.40 higher than market average
- **Quality leadership**: 4.58/5.0 rating (vs 4.11 competitor average)
- **Strong reputation**: 314 avg reviews (vs 209 competitor average)
- **Geographic presence**: Well-distributed across core and inner zones
- **Quality score**: 25.99 (vs 21.46 competitor average)

### Strategic Implications
1. **Value Proposition**: SOC justifies premium pricing with superior quality and reputation
2. **Market Position**: High-quality, premium segment leader
3. **Growth Opportunities**: Potential expansion in outer/peripheral zones
4. **Competitive Moat**: Strong ratings and review volume create customer trust

## Future Enhancements

**Phase 2 Additions**:
- Review sentiment analysis (customer voice graphs)
- Social media engagement metrics
- Temporal trends (how market changes over time)
- Expansion opportunity scoring

**Phase 3 Automation**:
- Automated data refresh and graph regeneration
- Anomaly detection (significant market changes)
- Predictive analytics (market trends, expansion ROI)

## Maintenance

**Update Frequency**: 
- Monthly: Run ferry + analysis scripts for current market snapshot
- Quarterly: Deep dive analysis with strategic recommendations
- Annual: Comprehensive market review and trend analysis

**Script Updates**:
- Add new graph families as analytical questions emerge
- Refine visualizations based on stakeholder feedback
- Incorporate new data sources (reviews, social media) when available

## References

- **EDA Style Guide**: `../../eda-1/eda-style-guide.md`
- **Data Sources**: `../data-documentation/data-sources.md`
- **Ferry Process**: `../data-documentation/ferry-process.md`
- **Task Assignment**: `../rap-0-task-assignment.md`

---

**Last Updated**: 2025-12-12  
**Maintainer**: Research Team  
**Version**: 1.0.0
