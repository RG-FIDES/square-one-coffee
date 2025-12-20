# Edmonton Neighborhood Explorer

Interactive Shiny app for visualizing and exploring Edmonton neighborhoods.

## Features

- **Interactive Map**: Displays all 403 neighborhoods in Greater Edmonton area
- **Searchable Dropdown**: Type to search and select neighborhoods quickly
- **Dynamic Highlighting**: Selected neighborhoods are highlighted in red with zoom-to-fit
- **Clean UI**: Simple, focused interface following Shiny gallery best practices

## Data Source

- **Database**: `./data-private/derived/global-data.sqlite`
- **Table**: `ellis_4_open_data` (403 neighborhood polygons)
- **Geometry**: WKT format in EPSG:4326 (WGS84) coordinate system
- **Source**: Edmonton Open Data Portal

## Usage

### Launch App

**Option 1: VSCode Task**
- Press `Ctrl+Shift+P` → "Tasks: Run Task" → "Run Shiny App - Neighborhood Explorer"

**Option 2: R Console**
```r
shiny::runApp("analysis/shiny-1", port = 3838)
```

**Option 3: RStudio**
- Open `app.R` and click "Run App" button

### Interact with App

1. **Browse Map**: Pan and zoom to explore Edmonton neighborhoods
2. **Select Neighborhood**: Click dropdown or type to search by name
3. **View Highlight**: Selected neighborhood zooms into view with red highlight
4. **Clear Selection**: Select "Select a neighborhood..." to reset view

## Dependencies

Required R packages:
- `shiny` - Web application framework
- `leaflet` - Interactive maps
- `sf` - Simple features (spatial data)
- `DBI`, `RSQLite` - Database connectivity
- `dplyr` - Data manipulation

Install missing packages:
```r
install.packages(c("shiny", "leaflet"))
```

## Technical Details

### Map Configuration
- **Base Tiles**: CartoDB Positron (clean, minimal style)
- **Default View**: Edmonton city center (53.5461°N, 113.4938°W) at zoom level 11
- **Neighborhood Borders**: Gray outlines with hover effects
- **Highlight Color**: Red (#ff6b6b) with thicker border for selected neighborhood

### Performance
- Data loaded once at startup (403 polygons, ~2MB)
- Reactive highlighting using `leafletProxy` for smooth updates
- No caching needed due to fast load times

## Future Enhancements

Potential additions for subsequent versions:
- Display neighborhood demographics (population, area, density)
- Show coffee shop locations within selected neighborhood
- Multi-neighborhood comparison mode
- Export selected neighborhood data
- Filter neighborhoods by characteristics (population, ward, etc.)
- Add custom map controls and legends

## File Structure

```
shiny-1/
├── app.R           # Main Shiny application
├── README.md       # This file
└── data-local/     # (Reserved for cached data if needed)
```

## Related Analysis

- **EDA-1**: Exploratory data analysis of Edmonton neighborhoods
- **Ellis-4**: Raw neighborhood boundary data processing
- **Ellis-5**: Demographic data enrichment
- **Ellis-6**: Cafe location spatial analysis

---

**Created**: 2025-12-19  
**Project**: Square One Coffee Research  
**Purpose**: Market research support for specialty coffee retail strategy
