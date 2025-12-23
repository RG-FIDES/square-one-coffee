# Edmonton Neighborhood Explorer

Interactive Shiny app for visualizing and exploring Edmonton neighborhoods and their places of interest.

## Features

- **Interactive Map**: Displays all 403 neighborhoods in Greater Edmonton area
- **Choropleth Visualization**: Color neighborhoods by population, density, or other metrics
- **Square One Coffee Locations**: Shows 5 operational locations (blue markers) + 1 coming soon (orange marker)
- **Dynamic Metrics**: Simple dropdown to switch between demographic indicators
- **Modular Design**: Easy to add new metrics (cafes, restaurants, etc.) via data-provisioning.R
- **Clean UI**: Minimal sidebar focusing on metric selection

## Data Source

- **Database**: `./data-private/derived/global-data.sqlite`
- **Neighborhood Boundaries**: `ellis_4_open_data` (403 polygons)
- **SOC Operational Locations**: `ellis_0_cafes` (5 locations from Google Places API)
- **SOC Coming Soon**: Millwoods location geocoded from announced address
- **Geometry**: WKT format in EPSG:4326 (WGS84) coordinate system
- **Source**: Edmonton Open Data Portal + Google Places API + OpenStreetMap Nominatim

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
2. **Select Metric**: Use dropdown to color neighborhoods by population or density
3. **View Legend**: Color scale appears when metric is selected
4. **Click Neighborhoods**: Popups show metric values for each neighborhood
5. **View SOC Locations**: Blue markers indicate operational locations, orange for coming soon
6. **Click SOC Markers**: Popups show address, rating, reviews, phone, and website

## Dependencies

Required R packages:
- `shiny` - Web application framework
- `leaflet` - Interactive maps
- `sf` - Simple features (spatial data)
- `DBI`, `RSQLite` - Database connectivity
- `dplyr` - Data manipulation

Install missing packages:
```r
install.packages(c("shiny", "leaflet", "sf"))
```

## Architecture

### Modular Design
The app uses a modular architecture to facilitate adding new metrics:

**data-provisioning.R** - Isolated data pr(adjust based on metric selection)
- **Choropleth Colors**: RColorBrewer palettes (YlOrRd for population, YlGnBu for density)
- **Operational Markers**: Blue circle markers (#3b82f6) for 5 operational locations
- **Coming Soon Markers**: Orange circle markers (#f59e0b) for Millwoods pre-opening location
- **Dynamic Legend**: Appears when metric selected, shows value ranges and colors

### Current Metrics Available
1. **None (Gray)** - Default gray neighborhoods
2. **Total Population** - Yellow-Orange-Red gradient
3. **Population Density (per km²)** - Yellow-Green-Blue gradient

**app.R** - Shiny application logic
- Sources data-provisioning.R for all data operations
- UI renders metric dropdown dynamically from definitions
- Server updates map reactively based on selected metric

### Adding New Metrics
To add metrics like cafe count, restaurant count, etc.:

1. Open `data-provisioning.R`
2. In `provision_neighborhood_metrics()`, add data queries/joins
3. In `get_metric_definitions()`, add new metric definition:
```r
list(
  id = "cafe_count",
  label = "Number of Cafes",
  column = "cafe_count",
  palette = "PuRd",
  reverse = FALSE
)
```
4. App automatically picks up new metrics - no changes to app.R needed

## Technical Details

### Map Configuration
- **Base Tiles**: CartoDB Positron (clean, minimal style)
- **Default View**: Edmonton city center (53.5461°N, 113.4938°W) at zoom level 11
- **Neighborhood Borders**: Gray outlines with hover effects
- **Highlight Color**: Red (#ff6b6b) with thicker border for selected neighborhood
- **Operational Markers**: Blue circle markers (#3b82f6) for 5 operational locations
- **Coming Soon Markers**: Orange circle markers (#f59e0b) for Millwoods pre-opening location

### Performance
- Data loaded once at startup (403 polygons + 6 SOC locations, ~2MB)
- Reactive highlighting using `leafletProxy` for smooth updates
- No caching needed due to fast load times

## Square One Coffee Locations

The app displays all Square One Coffee locations:

### Operational (5 locations - Blue Markers)
1. **Square 1 Coffee - Aspen Gardens** (15 Fairway Dr NW) - Rating: 4.7 (1,898 reviews)
2. **Square 1 Coffee - Glenora** (14055 West Block Dr NW) - Rating: 4.7 (750 reviews)
3. **Square 1 Coffee - Mayfield** (16819 111 Ave NW) - Rating: 4.8 (236 reviews)
4. **Square 1 Coffee - Sherwood Park** (115 Tisbury St, Sherwood Park) - Rating: 4.8 (98 reviews)
5. **Square 1 Coffee - Windsor** (11728 87 Ave NW) - Rating: 4.7 (127 reviews)

### Coming Soon (1 location - Orange Marker)
6. **Square 1 Coffee - Millwoods** (7319 29 Ave NW) - Status: Pre-opening

Click any marker to see detailed information. Blue markers show ratings and contact info; orange marker indicates announced but not-yet-open location.

## Future Enhancements
competitor cafe locations from `ellis_0_cafes` table
- Show cafe density heatmap by neighborhood
- Display neighborhood demographics (population, area, density)
- Calculate and display distance from SOC locations to selected neighborhood
- Multi-neighborhood comparison mode
- Filter cafes by rating threshold
- Export selected neighborhood data
- Add custom map controls and legends
- Show transit stops near SOC location
- Filter neighborhoods by characteristics (population, ward, etc.)
- Add custom map con        # Main Shiny application (UI + Server)
├── data-provisioning.R     # Isolated data preparation and metric definitions
├── README.md               # This file
└── data-local/        re

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
