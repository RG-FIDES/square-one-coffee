# RAP-0-R: Edmonton Coffee Competition Intelligence (R/Tidyverse Version)

**Version**: 1.0.0  
**Last Updated**: 2025-12-12  
**Language**: R with tidyverse/ggplot2

---

## Overview

This is the **R/tidyverse implementation** of the RAP-0 competition intelligence pipeline. It emphasizes R's strengths in statistical analysis and ggplot2's powerful visualization grammar.

**Parallel Version**: For Python implementation, see `../rap-0-py/`

---

## Key Features

### R/Tidyverse Strengths
- **ggplot2 Graphics**: Full control over visualization aesthetics with grammar of graphics
- **dplyr Data Wrangling**: Pipe-based data transformations for readable code
- **Statistical Integration**: Native R statistical functions and packages
- **RMarkdown Ready**: Scripts designed for literate programming

### Differences from Python Version
- **Visualization Engine**: ggplot2 instead of matplotlib/seaborn
- **Data Manipulation**: tidyverse (dplyr/tidyr) instead of pandas
- **Code Style**: R pipe (`%>%`) and functional programming patterns
- **Output Format**: Optimized for RMarkdown/Quarto rendering

---

## Directory Structure

```
rap-0-R/
├── README.md                          # This file
├── rap-1-task-assignment.md          # Original requirements
├── data-collection/
│   ├── generate-synthetic-data.R     # R data generator
│   └── ferry-to-derived.R           # R transformation script
├── data-documentation/
│   ├── data-sources.md              # Shared documentation
│   ├── ferry-process.md
│   └── validation-rules.md
├── analysis-scripts/
│   ├── rap-0-market-overview.R      # Market analysis (9 ggplot2 graphs)
│   └── rap-0-competitive-position.R # Positioning (6 ggplot2 graphs)
└── prints/                          # Generated visualizations
```

---

## Prerequisites

### R Packages Required

```r
# Core tidyverse
install.packages(c("dplyr", "tidyr", "ggplot2", "stringr", "forcats", "scales"))

# Database connectivity
install.packages(c("DBI", "RSQLite"))

# Optional (for advanced features)
install.packages(c("devtools", "here"))
```

### Quick Setup

```r
# Install all required packages at once
required_packages <- c("dplyr", "tidyr", "ggplot2", "stringr", "forcats", 
                       "scales", "DBI", "RSQLite")
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)
```

---

## Usage

### Option 1: Run in R Console/RStudio

```r
# Set working directory to project root
setwd("/path/to/square-one-coffee")

# Generate synthetic data
source("analysis/rap-0-R/data-collection/generate-synthetic-data.R")

# Transform to derived database
source("analysis/rap-0-R/data-collection/ferry-to-derived.R")

# Generate market analysis (9 graphs)
source("analysis/rap-0-R/analysis-scripts/rap-0-market-overview.R")

# Generate competitive analysis (6 graphs)
source("analysis/rap-0-R/analysis-scripts/rap-0-competitive-position.R")

# View results
list.files("analysis/rap-0-R/prints/")
```

### Option 2: Command Line (Rscript)

```bash
# From project root
Rscript analysis/rap-0-R/data-collection/generate-synthetic-data.R
Rscript analysis/rap-0-R/data-collection/ferry-to-derived.R
Rscript analysis/rap-0-R/analysis-scripts/rap-0-market-overview.R
Rscript analysis/rap-0-R/analysis-scripts/rap-0-competitive-position.R
```

### Option 3: RMarkdown Rendering

```r
# Render scripts as reports
rmarkdown::render("analysis/rap-0-R/analysis-scripts/rap-0-market-overview.R")
rmarkdown::render("analysis/rap-0-R/analysis-scripts/rap-0-competitive-position.R")
```

---

## Graph Families (ggplot2)

All visualizations use ggplot2's grammar of graphics for maximum flexibility and aesthetic control.

### G2 Family: Geographic Distribution
- **g21**: Horizontal bar chart with `coord_flip()`
- **g22**: Scatter plot with custom shapes and colors
- **g23**: Stacked bar chart with location zones

### G3 Family: Pricing Landscape
- **g31**: Histogram with overlaid density and reference lines
- **g32**: Grouped bar chart with dodge positioning
- **g33**: Scatter plot with continuous scales

### G4 Family: Market Segmentation
- **g41**: Horizontal stacked bar chart
- **g42**: Pie chart using `coord_polar()`
- **g43**: Grouped bar chart with custom labels

### G5 Family: Market Positioning
- **g51**: Grouped bar chart with normalized metrics
- **g52**: Scatter plot with quadrant lines
- **g53**: Stacked percentage bar chart

### G6 Family: Quality & Reputation
- **g61**: Boxplot with overlaid means
- **g62**: Bubble chart with `size` aesthetic
- **g63**: Grouped bar chart with custom annotations

---

## ggplot2 Advantages

### Grammar of Graphics
```r
# Layered approach allows fine-grained control
ggplot(data, aes(x = var1, y = var2)) +
  geom_point() +                    # Geometry layer
  scale_color_manual(values = ...) + # Scale layer
  labs(title = ...) +               # Labels layer
  theme_minimal() +                 # Theme layer
  theme(plot.title = ...)           # Theme customization
```

### Consistent Theming
```r
# Reusable theme components
theme_rap0 <- theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

# Apply to any plot
ggplot(...) + ... + theme_rap0
```

### Flexible Scales
```r
# Custom color palettes
scale_fill_manual(
  values = c("SOC" = "#E63946", "Competitor" = "#457B9D"),
  labels = c("Square One Coffee", "Competitors")
)

# Continuous transformations
scale_y_continuous(
  trans = "log10",
  labels = scales::comma
)
```

---

## Code Style

### R Conventions

**Pipe Operator**:
```r
data %>%
  filter(condition) %>%
  group_by(variable) %>%
  summarise(mean = mean(value)) %>%
  arrange(desc(mean))
```

**Function Naming**:
- Snake_case for variables: `avg_price`, `business_type`
- CamelCase avoided except in ggplot2 functions
- Clear, descriptive names

**Comments**:
```r
# ---- chunk-name -----------------------------------------------------------
# Descriptive comment explaining the chunk's purpose
```

---

## Visualization Standards

### Dimensions & Quality
- **Size**: 8.5 × 5.5 inches (letter half-page)
- **Resolution**: 300 DPI (publication quality)
- **Format**: PNG

### Saving Plots
```r
ggsave(
  filename = paste0(PRINTS_FOLDER, "g21_cafe_concentration.png"),
  plot = g21,
  width = FIG_WIDTH,
  height = FIG_HEIGHT,
  dpi = FIG_DPI
)
```

### Color Palette
- **SOC**: `#E63946` (red)
- **Competitors**: `#457B9D` (blue)
- **Neutral**: `#2E86AB`, `#A23B72`, `#F1A208`, `#2A9D8F`

---

## Integration with Project

### Shared Data Layer
- Uses same SQLite databases as Python version
- `data-private/raw/edmonton_cafes.sqlite` (input)
- `data-private/derived/rap-0-competition-intel.sqlite` (output)

### Documentation
- Shares data documentation with Python version
- Methodology consistent across both implementations

### Flow.R Integration (Future)
```r
# Add to flow.R
ds_rail <- tibble::tribble(
  ~fx         , ~path,
  # RAP-0-R: Competition Intelligence (R Version)
  "run_r"     , "analysis/rap-0-R/data-collection/generate-synthetic-data.R",
  "run_r"     , "analysis/rap-0-R/data-collection/ferry-to-derived.R",
  "run_r"     , "analysis/rap-0-R/analysis-scripts/rap-0-market-overview.R",
  "run_r"     , "analysis/rap-0-R/analysis-scripts/rap-0-competitive-position.R"
)
```

---

## Comparison: R vs Python

| Aspect | RAP-0-R (This Version) | RAP-0-py |
|--------|------------------------|----------|
| **Visualization** | ggplot2 | matplotlib + seaborn |
| **Data Wrangling** | dplyr/tidyr | pandas |
| **Code Style** | Pipe-based, functional | Object-oriented, imperative |
| **Strengths** | Statistical analysis, grammar of graphics | Fast execution, extensive libraries |
| **Use Case** | Statistical reports, publication graphics | Production pipelines, automation |
| **Learning Curve** | Steeper for graphics grammar | Gentler for basic plots |

---

## Best Practices

### When to Use R Version
- ✅ Statistical analysis emphasis
- ✅ Publication-quality graphics required
- ✅ RMarkdown/Quarto reporting workflow
- ✅ Collaboration with R-focused teams
- ✅ Need for ggplot2 flexibility

### When to Use Python Version
- ✅ CI/CD automation required
- ✅ Integration with Python ecosystem
- ✅ Faster execution needed
- ✅ Web deployment
- ✅ Machine learning integration

---

## Troubleshooting

### Common Issues

**Issue**: `Error: could not find function "%>%"`  
**Solution**: Load `dplyr` or `magrittr` package

**Issue**: `Error: package 'ggplot2' not found`  
**Solution**: Install missing packages (see Prerequisites)

**Issue**: Plots don't appear  
**Solution**: Ensure working directory is project root

**Issue**: Database not found  
**Solution**: Run data generation and ferry scripts first

---

## Future Enhancements

### Phase 2: Real Data Integration
- Web scraping with `rvest`
- API integration with `httr2`
- Advanced spatial analysis with `sf`

### Phase 3: Interactive Visualizations
- `plotly` for interactive plots
- `shiny` for interactive dashboards
- `flexdashboard` for reporting

---

## References

- **ggplot2 Documentation**: https://ggplot2.tidyverse.org/
- **Tidyverse**: https://www.tidyverse.org/
- **R for Data Science**: https://r4ds.had.co.nz/
- **Project EDA Style Guide**: `../eda-1/eda-style-guide.md`

---

**Maintainer**: Research Team  
**Version**: 1.0.0  
**Status**: ✅ Operational (requires R environment)
