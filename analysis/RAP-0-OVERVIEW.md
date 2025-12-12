# RAP-0: Competition Intelligence Pipeline - Dual Implementation

**Project**: Square One Coffee Edmonton Market Intelligence  
**Version**: 1.0.0  
**Last Updated**: 2025-12-12  

---

## Overview

RAP-0 is a **Reproducible Analytical Pipeline** for competitive intelligence analysis. It comes in **two parallel implementations** that emphasize different programming paradigms and visualization philosophies:

1. **RAP-0-py** (`./rap-0-py/`): Python implementation with pandas/matplotlib
2. **RAP-0-R** (`./rap-0-R/`): R implementation with tidyverse/ggplot2

Both versions produce equivalent intelligence outputs but leverage the unique strengths of their respective languages.

---

## Quick Comparison

| Aspect | RAP-0-py (Python) | RAP-0-R (R/ggplot2) |
|--------|-------------------|---------------------|
| **Primary Use** | CI/CD automation, production | Statistical reports, publications |
| **Visualization** | matplotlib + seaborn | ggplot2 (grammar of graphics) |
| **Data Wrangling** | pandas | dplyr/tidyr (tidyverse) |
| **Code Style** | Imperative, object-oriented | Functional, pipe-based |
| **Execution Speed** | Faster for large datasets | Optimized for statistical ops |
| **Graph Control** | Direct API calls | Layered grammar approach |
| **Learning Curve** | Gentler for basic tasks | Steeper, more powerful |
| **Ecosystem** | Machine learning, web apps | Statistical modeling, RMarkdown |
| **CI Compatibility** | ✅ Fully operational | ⚠️ Requires R environment |

---

## Directory Structure

```
analysis/
├── RAP-0-OVERVIEW.md          # This file
│
├── rap-0-py/                  # Python Implementation
│   ├── README.md              # Python-specific docs
│   ├── data-collection/
│   │   ├── generate-synthetic-data.py
│   │   └── ferry-to-derived.py
│   ├── data-documentation/    # Shared docs
│   ├── analysis-scripts/
│   │   ├── rap-0-market-overview.py
│   │   └── rap-0-competitive-position.py
│   └── prints/                # 15 matplotlib visualizations
│
└── rap-0-R/                   # R Implementation
    ├── README.md              # R-specific docs
    ├── data-collection/
    │   ├── generate-synthetic-data.R
    │   └── ferry-to-derived.R
    ├── data-documentation/    # Shared docs
    ├── analysis-scripts/
    │   ├── rap-0-market-overview.R
    │   └── rap-0-competitive-position.R
    └── prints/                # 15 ggplot2 visualizations
```

---

## Shared Infrastructure

### Data Layer
Both implementations use the same SQLite databases:
- **Raw**: `./data-private/raw/edmonton_cafes.sqlite`
- **Derived**: `./data-private/derived/rap-0-competition-intel.sqlite`

### Documentation
Shared documentation in both directories:
- `data-sources.md`: Data catalog and collection methods
- `ferry-process.md`: Transformation methodology
- `validation-rules.md`: Quality assurance rules

### Standards
- **Graph dimensions**: 8.5 × 5.5 inches, 300 DPI
- **Graph families**: g2 (geographic), g3 (pricing), g4 (segmentation), g5 (positioning), g6 (quality)
- **Naming convention**: Unique IDs (g21, g31, etc.)
- **Color palette**: SOC (#E63946), Competitors (#457B9D)

---

## When to Use Each Version

### Use RAP-0-py (Python) When:
✅ Running in CI/CD pipelines (GitHub Actions, Jenkins)  
✅ Automation and scheduling are priorities  
✅ Integration with Python ML libraries needed  
✅ Web deployment or API serving required  
✅ Working with very large datasets  
✅ Team primarily uses Python  

### Use RAP-0-R (R/ggplot2) When:
✅ Publication-quality graphics needed  
✅ Statistical analysis is primary focus  
✅ RMarkdown/Quarto reporting workflow  
✅ Maximum visualization flexibility required  
✅ Integration with R statistical packages  
✅ Team primarily uses R/tidyverse  

---

## Getting Started

### Python Version (rap-0-py)

**Prerequisites**:
```bash
pip install pandas numpy matplotlib seaborn
```

**Run Pipeline**:
```bash
cd /path/to/square-one-coffee

# Execute pipeline
python3 analysis/rap-0-py/data-collection/generate-synthetic-data.py
python3 analysis/rap-0-py/data-collection/ferry-to-derived.py
python3 analysis/rap-0-py/analysis-scripts/rap-0-market-overview.py
python3 analysis/rap-0-py/analysis-scripts/rap-0-competitive-position.py

# View results
ls analysis/rap-0-py/prints/
```

### R Version (rap-0-R)

**Prerequisites**:
```r
install.packages(c("dplyr", "tidyr", "ggplot2", "stringr", 
                   "forcats", "scales", "DBI", "RSQLite"))
```

**Run Pipeline**:
```r
# In R console
setwd("/path/to/square-one-coffee")

source("analysis/rap-0-R/data-collection/generate-synthetic-data.R")
source("analysis/rap-0-R/data-collection/ferry-to-derived.R")
source("analysis/rap-0-R/analysis-scripts/rap-0-market-overview.R")
source("analysis/rap-0-R/analysis-scripts/rap-0-competitive-position.R")

# View results
list.files("analysis/rap-0-R/prints/")
```

Or via command line:
```bash
Rscript analysis/rap-0-R/data-collection/generate-synthetic-data.R
Rscript analysis/rap-0-R/data-collection/ferry-to-derived.R
Rscript analysis/rap-0-R/analysis-scripts/rap-0-market-overview.R
Rscript analysis/rap-0-R/analysis-scripts/rap-0-competitive-position.R
```

---

## Output Comparison

Both versions generate **15 visualizations** (9 market overview + 6 competitive positioning):

### Graph Families

**G2 - Geographic Distribution** (3 graphs):
- g21: Cafe concentration by neighborhood
- g22: Geographic distribution map
- g23: Location zones by distance

**G3 - Pricing Landscape** (3 graphs):
- g31: Price distribution histogram
- g32: Price categories by type
- g33: Price-quality positioning

**G4 - Market Segmentation** (3 graphs):
- g41: Cafe type distribution
- g42: Ownership structure
- g43: Food offerings comparison

**G5 - Market Positioning** (3 graphs):
- g51: Key metrics comparison
- g52: Price-quality matrix
- g53: Market share by zones

**G6 - Quality & Reputation** (3 graphs):
- g61: Rating distribution
- g62: Quality score analysis
- g63: Reputation strength

### Visual Differences

**Python (matplotlib)**:
- More direct control over plot elements
- Familiar to data scientists
- Faster rendering for large datasets
- Standard scientific plotting style

**R (ggplot2)**:
- Layered grammar of graphics
- Easier to customize themes
- More elegant syntax for complex plots
- Professional publication aesthetics

---

## Technical Philosophy

### Python Approach
- **Imperative**: Explicit step-by-step instructions
- **Object-Oriented**: Work with plot objects
- **Pragmatic**: "Get it done" mentality
- **Example**:
```python
fig, ax = plt.subplots(figsize=(8.5, 5.5))
ax.scatter(x, y, c=colors, s=sizes)
ax.set_xlabel('X Label')
ax.set_title('Plot Title')
plt.savefig('output.png', dpi=300)
```

### R Approach
- **Declarative**: Describe what you want
- **Functional**: Transform data through pipelines
- **Aesthetic**: Build plots layer by layer
- **Example**:
```r
ggplot(data, aes(x = x, y = y, color = group, size = value)) +
  geom_point() +
  labs(x = "X Label", title = "Plot Title") +
  theme_minimal() +
  ggsave("output.png", width = 8.5, height = 5.5, dpi = 300)
```

---

## Maintenance Strategy

### Active Development
- **Python version**: Primary for CI/CD and automation
- **R version**: Primary for statistical analysis and publications

### Updates
When updating the pipeline:
1. Implement changes in both versions
2. Ensure output consistency
3. Update shared documentation
4. Test both pipelines end-to-end

### Version Control
- Both versions tracked in same repository
- Shared data documentation
- Independent code evolution allowed

---

## Integration with Project Flow

### Future flow.R Integration

```r
ds_rail <- tibble::tribble(
  ~fx         , ~path,
  
  # Python version (for CI/automation)
  "run_python", "analysis/rap-0-py/data-collection/generate-synthetic-data.py",
  "run_python", "analysis/rap-0-py/data-collection/ferry-to-derived.py",
  "run_python", "analysis/rap-0-py/analysis-scripts/rap-0-market-overview.py",
  "run_python", "analysis/rap-0-py/analysis-scripts/rap-0-competitive-position.py",
  
  # R version (for statistical analysis)
  "run_r"     , "analysis/rap-0-R/data-collection/generate-synthetic-data.R",
  "run_r"     , "analysis/rap-0-R/data-collection/ferry-to-derived.R",
  "run_r"     , "analysis/rap-0-R/analysis-scripts/rap-0-market-overview.R",
  "run_r"     , "analysis/rap-0-R/analysis-scripts/rap-0-competitive-position.R"
)
```

---

## Best Practices

### For Python Users
1. Use virtual environments for dependency management
2. Follow PEP 8 style guidelines
3. Comment complex matplotlib customizations
4. Use type hints for clarity

### For R Users
1. Use renv for package management
2. Follow tidyverse style guide
3. Leverage ggplot2 themes for consistency
4. Document data transformation pipelines

### For Both
1. Keep visualizations at standard dimensions
2. Use consistent color palette
3. Follow graph family organization
4. Document any deviations from standards

---

## Future Enhancements

### Phase 2: Real Data Integration
- **Python**: Web scraping with `beautifulsoup4`, `scrapy`
- **R**: Web scraping with `rvest`, `httr2`
- Both: API integration, scheduled data collection

### Phase 3: Advanced Analytics
- **Python**: Machine learning with `scikit-learn`, `tensorflow`
- **R**: Statistical modeling with `tidymodels`, `caret`
- Both: Predictive analytics, trend forecasting

### Phase 4: Interactive Outputs
- **Python**: Dashboards with `streamlit`, `plotly-dash`
- **R**: Shiny apps, `flexdashboard`, interactive `plotly`
- Both: Web-based intelligence portals

---

## References

### Python Resources
- pandas: https://pandas.pydata.org/
- matplotlib: https://matplotlib.org/
- seaborn: https://seaborn.pydata.org/

### R Resources
- tidyverse: https://www.tidyverse.org/
- ggplot2: https://ggplot2.tidyverse.org/
- R for Data Science: https://r4ds.had.co.nz/

### Project Resources
- Task Assignment: `./rap-0-py/rap-1-task-assignment.md`
- EDA Style Guide: `./eda-1/eda-style-guide.md`
- Project Mission: `../ai/project/mission.md`

---

## Support

**Questions**: Contact @andkov (Project Lead)  
**Issues**: GitHub Issues in square-one-coffee repository  
**Documentation**: See version-specific READMEs in each directory  

---

**Status**: ✅ Both versions operational and tested  
**Recommendation**: Use Python for automation, R for statistical analysis  
**Version**: 1.0.0  
**Last Updated**: 2025-12-12
