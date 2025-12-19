# Ellis Data Pipeline Study
## Comprehensive Analysis of Edmonton Cafe Data Collection System

**Study Date**: December 19, 2025  
**Author**: GitHub Copilot (Project Manager Persona)  
**Purpose**: Understand the Ellis pipeline architecture, data flow, and transformation logic

---

## Table of Contents
1. [Pipeline Overview](#pipeline-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Stage-by-Stage Analysis](#stage-by-stage-analysis)
4. [Data Flow Visualization](#data-flow-visualization)
5. [Database Schema](#database-schema)
6. [Key Design Patterns](#key-design-patterns)
7. [Error Handling & Robustness](#error-handling--robustness)
8. [Execution Strategies](#execution-strategies)

---

## Pipeline Overview

The **Ellis Pipeline** is a multi-stage ETL (Extract, Transform, Load) system designed to collect, process, and consolidate diverse data sources about Edmonton's cafe ecosystem and urban context. The pipeline demonstrates a systematic approach to open data integration for research purposes.

### Core Objectives
- **Comprehensive Coverage**: Systematically catalog all cafes in Edmonton
- **Contextual Enrichment**: Add demographic and urban planning data
- **Research-Ready Output**: Produce analysis-ready datasets in multiple formats
- **Reproducibility**: Document all data sources and transformations

### Pipeline Stages
```
Ellis-0 → Ellis-1 → Ellis-2 → Ellis-3 → Ellis-4 → Ellis-5 → Ellis-6 → Ellis-Last
  ↓         ↓         ↓         ↓         ↓         ↓         ↓         ↓
Google   Property Business Community  Neighbor. Population  Transform  Consolidate
Places   Assessment License Services  Geometry  Data                   to SQLite
API                                    (GeoJSON)
```

---

## Architecture Diagram

### High-Level System Architecture
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ELLIS DATA PIPELINE                                  │
│                   Square One Coffee Research Project                         │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA SOURCES (INPUT)                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐  ┌─────────────────────────────────────────────────┐ │
│  │  Google Places   │  │      Edmonton Open Data Portal (SODA2 API)      │ │
│  │       API        │  │  - Property Assessments                         │ │
│  │   (ellis-0)      │  │  - Business Licenses                            │ │
│  │                  │  │  - Community Services                           │ │
│  │  Python Script   │  │  - Neighborhood Geometries                      │ │
│  │  Grid Search     │  │  - Population Demographics                      │ │
│  │  ~1,785 cafes    │  │                                                 │ │
│  └──────────────────┘  └─────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        EXTRACTION LAYER (Ellis 0-5)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   │
│  │  Ellis-0    │   │  Ellis-1    │   │  Ellis-2    │   │  Ellis-3    │   │
│  │  (Python)   │   │  (R)        │   │  (R)        │   │  (R)        │   │
│  │             │   │             │   │             │   │             │   │
│  │  Google     │   │  Property   │   │  Business   │   │  Community  │   │
│  │  Places     │   │  Assessment │   │  Licenses   │   │  Services   │   │
│  │             │   │             │   │             │   │             │   │
│  │  CSV + RDS  │   │  CSV + RDS  │   │  CSV + RDS  │   │  CSV + RDS  │   │
│  └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘   │
│         │                  │                  │                  │          │
│  ┌─────────────┐   ┌─────────────┐                                         │
│  │  Ellis-4    │   │  Ellis-5    │                                         │
│  │  (R)        │   │  (R)        │                                         │
│  │             │   │             │                                         │
│  │  Neighbor.  │   │  Population │                                         │
│  │  Geometry   │   │  Data       │                                         │
│  │  (GeoJSON)  │   │             │                                         │
│  │             │   │             │                                         │
│  │  CSV + RDS  │   │  CSV + RDS  │                                         │
│  └─────────────┘   └─────────────┘                                         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      TRANSFORMATION LAYER (Ellis-6)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                          Ellis-6 Transform                             │ │
│  │                                (R + sf)                                │ │
│  │                                                                        │ │
│  │  [1] Spatial Join: Cafes → Neighborhoods                              │ │
│  │      • Convert cafe lat/lng to sf points (CRS: 4326)                  │ │
│  │      • Load neighborhood geometries from ellis-4                      │ │
│  │      • st_within() to assign neighborhoods to cafes                   │ │
│  │                                                                        │ │
│  │  [2] Demographic Enrichment                                           │ │
│  │      • Join population data from ellis-5                              │ │
│  │      • Calculate neighborhood area (sq km)                            │ │
│  │      • Compute population density                                     │ │
│  │                                                                        │ │
│  │  [3] Output: Cafes with full demographic context                      │ │
│  │      • name, address, neighborhood                                    │ │
│  │      • population, area, density_of_population                        │ │
│  │                                                                        │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      CONSOLIDATION LAYER (Ellis-Last)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                    Ellis-Last: SQLite Consolidation                    │ │
│  │                                                                        │ │
│  │  • Load all CSV files from ellis-0 through ellis-6                    │ │
│  │  • Create unified SQLite database: global-data.sqlite                 │ │
│  │  • 7 tables representing each pipeline stage                          │ │
│  │  • Overwrite mode for reproducibility                                 │ │
│  │                                                                        │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         FINAL OUTPUT (data-private/derived/)                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                      global-data.sqlite                                │ │
│  │                                                                        │ │
│  │  Tables:                                                               │ │
│  │  1. ellis_0_cafes                    (~1,785 records)                 │ │
│  │  2. ellis_1_property_assessment      (~1,000 records)                 │ │
│  │  3. ellis_2_business_licenses        (~1,000 records)                 │ │
│  │  4. ellis_3_community_services       (~1,000 records)                 │ │
│  │  5. ellis_4_open_data                (neighborhood geometries)        │ │
│  │  6. ellis_5_open_data                (population data)                │ │
│  │  7. ellis_6_cafes_with_demographics  (analysis-ready rectangle)       │ │
│  │                                                                        │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  Plus individual CSV and RDS files for each stage                            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Stage-by-Stage Analysis

### Ellis-0: Google Places Cafe Scanner (Python)
**File**: `ellis-0-scan.py`  
**Runtime**: ~2-3 minutes (API rate-limited)  
**Language**: Python 3

#### Purpose
Comprehensive geographic search for all cafes in Edmonton using Google Places API.

#### Algorithm: Grid-Based Search Strategy
```
┌────────────────────────────────────────────────────────────────┐
│           GRID-BASED SEARCH COVERAGE STRATEGY                  │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Edmonton Bounding Box:                                         │
│  North: 53.7°   South: 53.4°   (0.3° latitude range)          │
│  West: -113.7°  East: -113.3°  (0.4° longitude range)          │
│                                                                 │
│  Grid Size: 0.05° (~5km per cell)                              │
│  Search Radius: 3,500m (ensures cell overlap)                  │
│                                                                 │
│  Visual Grid Pattern:                                           │
│                                                                 │
│     -113.7    -113.65   -113.6    -113.55   -113.5   -113.3   │
│  53.7  ●────────●────────●────────●────────●────────●          │
│        │   ◯    │   ◯    │   ◯    │   ◯    │   ◯    │          │
│        │  3.5km │        │        │        │        │          │
│  53.65 ●────────●────────●────────●────────●────────●          │
│        │   ◯    │   ◯    │   ◯    │   ◯    │   ◯    │          │
│        │        │        │        │        │        │          │
│  53.6  ●────────●────────●────────●────────●────────●          │
│        │   ◯    │   ◯    │   ◯    │   ◯    │   ◯    │          │
│        │        │        │        │        │        │          │
│  53.55 ●────────●────────●────────●────────●────────●          │
│        │   ◯    │   ◯    │   ◯    │   ◯    │   ◯    │          │
│        │        │        │        │        │        │          │
│  53.5  ●────────●────────●────────●────────●────────●          │
│        │   ◯    │   ◯    │   ◯    │   ◯    │   ◯    │          │
│        │        │        │        │        │        │          │
│  53.45 ●────────●────────●────────●────────●────────●          │
│        │   ◯    │   ◯    │   ◯    │   ◯    │   ◯    │          │
│        │        │        │        │        │        │          │
│  53.4  ●────────●────────●────────●────────●────────●          │
│                                                                 │
│  ● = Grid point (search center)                                │
│  ◯ = 3,500m search radius                                      │
│                                                                 │
│  Total Grid Points: ~48 (7 lat × 7 lng)                        │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

#### Multi-Dimensional Search
For EACH grid point, the script performs:
```
Search Types (3):          Search Keywords (7):
  • cafe                     • cafe
  • coffee_shop              • coffee
  • bakery                   • espresso
                             • latte
                             • tea house
                             • bubble tea
                             • boba

Total Searches per Point: 10
Total Pipeline Searches: 48 × 10 = 480 API calls
```

#### Data Collection Flow
```
┌─────────────────────────────────────────────────────────────────┐
│              Ellis-0 Processing Pipeline                         │
└─────────────────────────────────────────────────────────────────┘

  1. Generate Grid Points
     ↓
  2. For Each Grid Point:
     ├─→ Search by Type (cafe, coffee_shop, bakery)
     └─→ Search by Keyword (cafe, coffee, espresso, etc.)
     ↓
  3. For Each Search Result:
     ├─→ Check if already found (deduplicate by place_id)
     ├─→ Validate location (within Edmonton bounds)
     ├─→ Filter relevance (is_likely_cafe())
     └─→ Add to collection
     ↓
  4. Enrichment Phase:
     ├─→ Call Places Details API for each unique place_id
     ├─→ Get: address, phone, website, hours, description
     └─→ Merge into main dataset
     ↓
  5. Export:
     ├─→ CSV: ellis-0-scan.csv
     ├─→ RDS: ellis-0-scan.rds (via Rscript conversion)
     └─→ SQLite: ellis_0_cafes table
```

#### Key Functions
- `generate_search_grid()`: Creates lat/lng grid covering Edmonton
- `search_nearby()`: Executes Google Places Nearby Search with pagination
- `get_place_details()`: Fetches detailed info for each place_id
- `is_likely_cafe()`: Filters non-cafe businesses (hotels, gas stations, etc.)
- `process_place()`: Deduplicates and validates each result

#### Output Schema
```
Columns (14):
  - place_id               (unique identifier)
  - name                   (business name)
  - address                (street address)
  - formatted_address      (full address)
  - lat, lng               (coordinates)
  - types                  (comma-separated Google types)
  - rating                 (1-5 stars)
  - user_ratings_total     (review count)
  - business_status        (OPERATIONAL, CLOSED_TEMPORARILY, etc.)
  - price_level            (1-4 scale)
  - phone                  (formatted phone number)
  - website                (URL)
  - hours                  (opening hours text)
  - is_open_now            (boolean)
  - description            (editorial summary)
```

---

### Ellis-1: Property Assessment Data (R)
**File**: `ellis-1-open-data.R`  
**Runtime**: ~30 seconds  
**API**: Edmonton Open Data SODA2

#### Purpose
Fetch property assessment data for understanding real estate context.

#### Data Source
- **Endpoint**: `https://data.edmonton.ca/resource/q7d6-ambg.csv`
- **API Type**: Socrata Open Data API (SODA2)
- **Limit**: 1,000 records (development mode)

#### Processing Pattern
```
┌─────────────────────────────────────────────────────────┐
│        Standard Ellis R Script Pattern                  │
│        (Used by Ellis 1-5)                              │
└─────────────────────────────────────────────────────────┘

  [1] Environment Setup
      ├─→ Load libraries (tidyverse, httr, DBI, RSQLite)
      └─→ Declare globals (API_URL, OUTPUT_DIR, RECORD_LIMIT)

  [2] Declare Functions
      └─→ fetch_*_data(limit): API call with error handling

  [3] Load Data
      ├─→ Create output directory
      ├─→ Execute API call via GET()
      ├─→ Parse CSV response
      └─→ Validate response status

  [4] Verify Values
      └─→ Log record count and column count

  [5] Save to Disk
      ├─→ CSV: data-private/derived/ellis-N/ellis-N.csv
      ├─→ RDS: data-private/derived/ellis-N/ellis-N.rds
      └─→ SQLite: table ellis_N_* in global-data.sqlite

  [6] Verify Save
      └─→ Check file existence and report status
```

#### Error Handling
```r
tryCatch({
  response <- GET(api_url)
  if (status_code(response) != 200) {
    stop("API request failed with status: ", status_code(response))
  }
  data <- read_csv(content(response, "text"), show_col_types = FALSE)
  return(data)
}, error = function(e) {
  message("Error fetching data: ", e$message)
  return(NULL)
})
```

#### Output Format
- **CSV**: Plain text, UTF-8 encoding
- **RDS**: R binary format (preserves data types)
- **SQLite**: `ellis_1_property_assessment` table

---

### Ellis-2: Business License Data (R)
**File**: `ellis-2-open-data.R`  
**Runtime**: ~30 seconds  
**API**: Edmonton Open Data SODA2

#### Purpose
Track business licensing information for cafes and related establishments.

#### Data Source
- **Endpoint**: `https://data.edmonton.ca/resource/bubb-yjc9.csv`
- **Use Case**: Validate business operational status, identify competitors

#### Structure
Identical to Ellis-1, following the standard R pattern. Key differences:
- Different API endpoint
- Different table name: `ellis_2_business_licenses`

---

### Ellis-3: Community Services Data (R)
**File**: `ellis-3-open-data.R`  
**Runtime**: ~30 seconds  
**API**: Edmonton Open Data SODA2

#### Purpose
Catalog community services for understanding neighborhood amenities.

#### Data Source
- **Endpoint**: `https://data.edmonton.ca/resource/b58q-nxjr.csv`
- **Use Case**: Contextualize cafe locations within broader community infrastructure

---

### Ellis-4: Neighborhood Geometry Data (R)
**File**: `ellis-4-open-data.R`  
**Runtime**: ~30 seconds  
**API**: Edmonton Open Data SODA2

#### Purpose
**Critical for Ellis-6**: Provides GeoJSON geometries for spatial joins.

#### Data Source
- **Endpoint**: `https://data.edmonton.ca/resource/5bk4-5txu.csv`
- **Format**: CSV with embedded GeoJSON (`the_geom` column)
- **Content**: Neighborhood boundary polygons

#### Special Handling
```r
# In Ellis-6, this data is converted to sf object:
neighborhoods_geo <- st_as_sf(df, wkt = "the_geom", crs = 4326)
```

---

### Ellis-5: Population Demographics (R)
**File**: `ellis-5-open-data.R`  
**Runtime**: ~30 seconds  
**API**: Edmonton Open Data SODA2

#### Purpose
**Critical for Ellis-6**: Population data for density calculations.

#### Data Source
- **Endpoint**: `https://data.edmonton.ca/resource/eg3i-f4bj.csv`
- **Content**: Population counts by neighborhood

#### Key Fields
- `neighbourhood`: Neighborhood name
- `total_population`: Population count

---

### Ellis-6: Spatial Transformation (R + sf)
**File**: `ellis-6-transform.R`  
**Runtime**: ~1 minute  
**Dependencies**: `sf` (spatial features), `tidyverse`, `DBI`

#### Purpose
**Most Complex Stage**: Combines cafe locations with demographic context using spatial operations.

#### Input Dependencies
```
Ellis-0  →  Cafe locations (lat, lng)
Ellis-4  →  Neighborhood geometries (GeoJSON polygons)
Ellis-5  →  Population by neighborhood
```

#### Transformation Pipeline
```
┌─────────────────────────────────────────────────────────────────┐
│              Ellis-6 Transformation Pipeline                     │
└─────────────────────────────────────────────────────────────────┘

  [1] SPATIAL JOIN: Assign Neighborhoods to Cafes
      │
      ├─→ Convert cafes to sf points:
      │   st_as_sf(cafes_df, coords = c("lng", "lat"), crs = 4326)
      │
      ├─→ Load neighborhood geometries from ellis-4:
      │   st_as_sf(ellis_4_df, wkt = "the_geom", crs = 4326)
      │
      ├─→ Perform spatial join:
      │   st_join(cafes_sf, neighborhoods_sf, join = st_within)
      │
      │   Algorithm: st_within()
      │   ┌──────────────────────────────────────────────────┐
      │   │  For each cafe point:                            │
      │   │    Test if point is WITHIN any neighborhood      │
      │   │    polygon geometry                               │
      │   │                                                   │
      │   │  Point-in-Polygon Test:                          │
      │   │  • Ray casting algorithm                         │
      │   │  • Handles complex polygons                      │
      │   │  • Returns first matching neighborhood           │
      │   └──────────────────────────────────────────────────┘
      │
      └─→ Result: cafes_with_neighborhoods (lat, lng, neighborhood_name)

  [2] AREA CALCULATION
      │
      ├─→ Calculate geometry area:
      │   st_area(neighborhood_polygon) → square meters
      │
      ├─→ Convert to square kilometers:
      │   area_sqkm = area_sqm / 1,000,000
      │
      └─→ Create lookup table: (neighborhood_name, area_sqkm)

  [3] DEMOGRAPHIC ENRICHMENT
      │
      ├─→ Normalize neighborhood names (uppercase, trim whitespace)
      │
      ├─→ Join population data (ellis-5):
      │   left_join(by = "neighbourhood_upper")
      │
      ├─→ Join area data (from step 2):
      │   left_join(by = "neighbourhood_upper")
      │
      └─→ Calculate population density:
          density = population / area_sqkm

  [4] OUTPUT STRUCTURE
      │
      └─→ Final columns:
          • name              (cafe name)
          • address           (street address)
          • neighborhood      (assigned neighborhood)
          • population        (neighborhood total)
          • area              (neighborhood sq km)
          • density_of_population  (people per sq km)
```

#### Spatial Join Visualization
```
┌─────────────────────────────────────────────────────────────────┐
│                 Point-in-Polygon Spatial Join                    │
└─────────────────────────────────────────────────────────────────┘

  Neighborhood Boundary Polygon          Cafe Point Location
  (from ellis-4 GeoJSON)                 (from ellis-0 lat/lng)

        ┌─────────────────────┐
        │                     │
        │   Neighborhood A    │
        │                     │
        │         ●───────────┼── Cafe X (lat, lng)
        │         │           │
        │         │           │
        └─────────┼───────────┘
                  │
                  │
        st_within() test:
          Is point (●) WITHIN polygon boundary?
          → YES → Assign "Neighborhood A"
          → NO  → Try next polygon
```

#### Key Functions
- `extract_neighborhood_from_geometry()`: Spatial join wrapper
- `calculate_population_density()`: Vectorized density calculation
- `st_as_sf()`: Convert data frames to spatial features
- `st_within()`: Point-in-polygon test
- `st_area()`: Calculate polygon area

#### Output Schema
```
Columns (6):
  - name                     (cafe name)
  - address                  (street address)
  - neighborhood             (assigned neighborhood)
  - population               (neighborhood total population)
  - area                     (neighborhood area in sq km)
  - density_of_population    (people per sq km)
```

---

### Ellis-Last: SQLite Consolidation (R)
**File**: `ellis-last.R`  
**Runtime**: ~10 seconds  
**Purpose**: Unified database creation

#### Consolidation Strategy
```
┌─────────────────────────────────────────────────────────────────┐
│            Ellis-Last: Database Consolidation                    │
└─────────────────────────────────────────────────────────────────┘

  [1] Discovery Phase
      │
      ├─→ Scan each ellis-N directory
      ├─→ Look for CSV files (priority)
      └─→ Fall back to RDS files if no CSV

  [2] Load All Datasets
      │
      ├─→ Ellis-0: ellis-0-scan.csv
      ├─→ Ellis-1: ellis-1-open-data.csv
      ├─→ Ellis-2: ellis-2-open-data.csv
      ├─→ Ellis-3: ellis-3-open-data.csv
      ├─→ Ellis-4: ellis-4-open-data.csv
      ├─→ Ellis-5: ellis-5-open-data.csv
      └─→ Ellis-6: ellis-6-transform.csv

  [3] Create SQLite Database
      │
      └─→ Path: data-private/derived/global-data.sqlite

  [4] Write Tables
      │
      ├─→ ellis_0_cafes
      ├─→ ellis_1_property_assessment
      ├─→ ellis_2_business_licenses
      ├─→ ellis_3_community_services
      ├─→ ellis_4_open_data
      ├─→ ellis_5_open_data
      └─→ ellis_6_cafes_with_demographics
      │
      Mode: overwrite = TRUE (reproducibility)

  [5] Verification
      │
      ├─→ List all tables
      ├─→ Count records per table
      └─→ Report database size
```

#### Database Schema
```sql
-- Table Structure in global-data.sqlite

CREATE TABLE ellis_0_cafes (
  place_id TEXT PRIMARY KEY,
  name TEXT,
  address TEXT,
  lat REAL,
  lng REAL,
  rating REAL,
  -- ... (14 total columns)
);

CREATE TABLE ellis_1_property_assessment (
  -- Property assessment fields
);

CREATE TABLE ellis_2_business_licenses (
  -- Business license fields
);

CREATE TABLE ellis_3_community_services (
  -- Community services fields
);

CREATE TABLE ellis_4_open_data (
  -- Neighborhood geometry (with GeoJSON)
);

CREATE TABLE ellis_5_open_data (
  -- Population demographics
);

CREATE TABLE ellis_6_cafes_with_demographics (
  name TEXT,
  address TEXT,
  neighborhood TEXT,
  population INTEGER,
  area REAL,
  density_of_population REAL
);
```

#### Key Functions
- `load_csv_or_rds()`: Flexible file loading
- `create_database_tables()`: Initialize SQLite database
- `save_table_to_db()`: Write data frame to SQLite with overwrite

---

## Data Flow Visualization

### End-to-End Data Lineage
```
┌─────────────────────────────────────────────────────────────────┐
│                  DATA LINEAGE DIAGRAM                            │
│          From Raw Sources to Analysis-Ready Dataset              │
└─────────────────────────────────────────────────────────────────┘

  ELLIS-0                    ELLIS-4                   ELLIS-5
  (Google Places)            (Geometries)              (Population)
       │                          │                         │
       │                          │                         │
       ▼                          ▼                         ▼
  ┌─────────┐              ┌─────────┐              ┌─────────┐
  │ Cafes   │              │ Neighbor│              │ Popula- │
  │ lat/lng │              │ Polygons│              │  tion   │
  │ name    │              │ GeoJSON │              │ Counts  │
  │ address │              │         │              │         │
  └─────────┘              └─────────┘              └─────────┘
       │                          │                         │
       └──────────────┬───────────┴─────────────────────────┘
                      │
                      ▼
                ┌───────────┐
                │  ELLIS-6  │
                │ Transform │
                └───────────┘
                      │
                      │ [Spatial Join]
                      │ [Calculate Density]
                      │ [Merge Demographics]
                      │
                      ▼
              ┌───────────────┐
              │ Cafes with:   │
              │ • Location    │
              │ • Neighborhood│
              │ • Population  │
              │ • Density     │
              └───────────────┘
                      │
                      ▼
                ┌───────────┐
                │ELLIS-LAST │
                │Consolidate│
                └───────────┘
                      │
                      ▼
            ┌─────────────────┐
            │ global-data.    │
            │   sqlite        │
            │                 │
            │ • 7 tables      │
            │ • Queryable     │
            │ • Analysis-ready│
            └─────────────────┘
```

### Data Transformation Detail
```
┌─────────────────────────────────────────────────────────────────┐
│         HOW RAW DATA BECOMES ANALYSIS-READY                      │
└─────────────────────────────────────────────────────────────────┘

  RAW DATA EXAMPLE (Ellis-0):
  ┌──────────────────────────────────────────────────────────┐
  │ place_id: ChIJ...abc123                                  │
  │ name: "Square One Coffee"                                │
  │ lat: 53.5461, lng: -113.4937                            │
  │ address: "8120 Gateway Blvd NW"                         │
  │ rating: 4.5, reviews: 847                                │
  └──────────────────────────────────────────────────────────┘
                      │
                      ▼ (Ellis-6 Step 1: Spatial Join)
  ┌──────────────────────────────────────────────────────────┐
  │ name: "Square One Coffee"                                │
  │ address: "8120 Gateway Blvd NW"                         │
  │ lat: 53.5461, lng: -113.4937                            │
  │ neighborhood: "Ritchie"  ← ADDED via st_within()        │
  └──────────────────────────────────────────────────────────┘
                      │
                      ▼ (Ellis-6 Step 2: Join Population)
  ┌──────────────────────────────────────────────────────────┐
  │ name: "Square One Coffee"                                │
  │ address: "8120 Gateway Blvd NW"                         │
  │ neighborhood: "Ritchie"                                  │
  │ population: 5,234  ← ADDED from ellis-5                 │
  └──────────────────────────────────────────────────────────┘
                      │
                      ▼ (Ellis-6 Step 3: Calculate Area & Density)
  ┌──────────────────────────────────────────────────────────┐
  │ name: "Square One Coffee"                                │
  │ address: "8120 Gateway Blvd NW"                         │
  │ neighborhood: "Ritchie"                                  │
  │ population: 5,234                                        │
  │ area: 2.15 sq km  ← CALCULATED from ellis-4 polygon     │
  │ density_of_population: 2,434 ppl/sq km  ← CALCULATED    │
  └──────────────────────────────────────────────────────────┘
                      │
                      ▼ (Ellis-Last: Save to SQLite)
  ┌──────────────────────────────────────────────────────────┐
  │ Table: ellis_6_cafes_with_demographics                   │
  │                                                          │
  │ SELECT * FROM ellis_6_cafes_with_demographics            │
  │ WHERE name = 'Square One Coffee';                        │
  │                                                          │
  │ → Ready for analysis, visualization, modeling            │
  └──────────────────────────────────────────────────────────┘
```

---

## Database Schema

### SQLite Database: `global-data.sqlite`
```
┌─────────────────────────────────────────────────────────────────┐
│              GLOBAL-DATA.SQLITE STRUCTURE                        │
│         Location: data-private/derived/global-data.sqlite        │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  TABLE: ellis_0_cafes                                         │
│  Source: Google Places API                                    │
│  Records: ~1,785                                             │
│  ────────────────────────────────────────────────────────────│
│  Columns:                                                     │
│    place_id (PK), name, address, formatted_address,          │
│    lat, lng, types, rating, user_ratings_total,              │
│    business_status, price_level, phone, website,             │
│    hours, is_open_now, description                           │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  TABLE: ellis_1_property_assessment                           │
│  Source: Edmonton Open Data                                   │
│  Records: ~1,000                                             │
│  ────────────────────────────────────────────────────────────│
│  Content: Property assessment values and details             │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  TABLE: ellis_2_business_licenses                             │
│  Source: Edmonton Open Data                                   │
│  Records: ~1,000                                             │
│  ────────────────────────────────────────────────────────────│
│  Content: Business licensing information                     │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  TABLE: ellis_3_community_services                            │
│  Source: Edmonton Open Data                                   │
│  Records: ~1,000                                             │
│  ────────────────────────────────────────────────────────────│
│  Content: Community services catalog                         │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  TABLE: ellis_4_open_data                                     │
│  Source: Edmonton Open Data (Neighborhood Boundaries)         │
│  Records: ~375 (neighborhoods)                               │
│  ────────────────────────────────────────────────────────────│
│  Key Column: the_geom (GeoJSON polygon geometries)           │
│  Content: Neighborhood boundary polygons                     │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  TABLE: ellis_5_open_data                                     │
│  Source: Edmonton Open Data (Demographics)                    │
│  Records: ~375 (neighborhoods)                               │
│  ────────────────────────────────────────────────────────────│
│  Key Columns: neighbourhood, total_population                │
│  Content: Population counts by neighborhood                  │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  TABLE: ellis_6_cafes_with_demographics                       │
│  Source: DERIVED (ellis-6 transformation)                     │
│  Records: ~1,785 (same as cafes, enriched)                   │
│  ────────────────────────────────────────────────────────────│
│  Columns:                                                     │
│    name              (cafe name)                             │
│    address           (street address)                        │
│    neighborhood      (assigned via spatial join)             │
│    population        (neighborhood total)                    │
│    area              (neighborhood sq km)                    │
│    density_of_population  (people per sq km)                 │
│  ────────────────────────────────────────────────────────────│
│  ★ PRIMARY ANALYSIS TABLE ★                                  │
│  This is the "analysis-ready rectangle" for cafe research    │
└──────────────────────────────────────────────────────────────┘
```

### Query Examples
```sql
-- Find cafes in high-density neighborhoods
SELECT 
  name, 
  neighborhood, 
  density_of_population
FROM ellis_6_cafes_with_demographics
WHERE density_of_population > 5000
ORDER BY density_of_population DESC;

-- Join with full cafe details
SELECT 
  e6.name,
  e6.neighborhood,
  e6.density_of_population,
  e0.rating,
  e0.user_ratings_total,
  e0.website
FROM ellis_6_cafes_with_demographics e6
LEFT JOIN ellis_0_cafes e0 ON e6.name = e0.name
WHERE e0.rating >= 4.5
ORDER BY e0.user_ratings_total DESC;

-- Aggregate statistics by neighborhood
SELECT 
  neighborhood,
  COUNT(*) as cafe_count,
  AVG(density_of_population) as avg_density,
  MAX(population) as neighborhood_population
FROM ellis_6_cafes_with_demographics
GROUP BY neighborhood
ORDER BY cafe_count DESC;
```

---

## Key Design Patterns

### 1. **Idempotent Operations**
All scripts can be re-run safely:
```r
# Overwrite mode ensures reproducibility
dbWriteTable(conn, "table_name", data, overwrite = TRUE)

# Directory creation is safe
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)
```

### 2. **Fail-Fast with Informative Errors**
```r
if (is.null(data)) {
  message("Failed to fetch data")
  quit(status = 1)  # Exit with error code
}
```

### 3. **Multi-Format Output**
Every stage produces:
- **CSV**: Universal, human-readable
- **RDS**: R-optimized, preserves types
- **SQLite**: Queryable, integrated

### 4. **Staged Processing (Ellis Pattern)**
```
Raw Data → Intermediate Files → Final Database
```
Benefits:
- **Debugging**: Inspect each stage independently
- **Resumability**: Skip completed stages
- **Transparency**: Audit trail of transformations

### 5. **Spatial Data Handling**
```r
# Consistent CRS (Coordinate Reference System): EPSG:4326 (WGS84)
cafes_sf <- st_as_sf(cafes_df, coords = c("lng", "lat"), crs = 4326)
neighborhoods_sf <- st_transform(neighborhoods_sf, 4326)

# Ensures spatial operations work correctly across datasets
```

### 6. **Defensive Null Handling**
```r
# Ellis-Last checks for data before saving
if (is.null(data) || nrow(data) == 0) {
  message("No data to save for table: ", table_name)
  return()
}
```

### 7. **Rate Limiting & API Courtesy**
```python
# Ellis-0: Respect Google's rate limits
time.sleep(0.5)  # Between searches
time.sleep(2)    # Before fetching next page
if response.status == 'OVER_QUERY_LIMIT':
    time.sleep(60)
```

---

## Error Handling & Robustness

### Error Handling Strategy by Stage

#### Ellis-0 (Python)
```python
try:
    response = self.session.get(url, params=params, timeout=30)
    response.raise_for_status()
except requests.exceptions.RequestException as e:
    print(f"Error: {e}")
    return []
```
- **Timeout**: 30 seconds per request
- **Retries**: Manual retry logic for OVER_QUERY_LIMIT
- **Partial Results**: Saves progress if interrupted (Ctrl+C)

#### Ellis 1-5 (R)
```r
tryCatch({
  # API call and processing
}, error = function(e) {
  message("Error fetching data: ", e$message)
  return(NULL)
})

# Check for null results
if (is.null(data)) {
  quit(status = 1)
}
```
- **Graceful Degradation**: Returns NULL on error
- **Exit Codes**: Non-zero exit on failure
- **Logging**: Clear error messages to console

#### Ellis-6 (R)
```r
# Load with fallback
cafes_data <- tryCatch({
  read_csv(ELLIS_0_CSV, show_col_types = FALSE)
}, error = function(e) {
  message("Error loading ellis-0 data: ", e$message)
  NULL
})

# Validate all dependencies loaded
if (is.null(cafes_data) || is.null(neighborhoods_geo) || is.null(population_data)) {
  message("❌ Failed to load required data files")
  quit(status = 1)
}
```
- **Dependency Checking**: Ensures all inputs available
- **Spatial Operation Warnings**: Suppresses non-critical warnings

#### Ellis-Last (R)
```r
# Flexible file discovery
csv_files <- list.files(directory, pattern = "*.csv", full.names = TRUE)
if (length(csv_files) > 0) {
  return(read_csv(csv_files[1]))
}
rds_files <- list.files(directory, pattern = "*.rds", full.names = TRUE)
if (length(rds_files) > 0) {
  return(readRDS(rds_files[1]))
}
return(NULL)  # No data found
```
- **Format Agnostic**: Works with CSV or RDS
- **Skips Missing**: Continues even if some stages failed

---

## Execution Strategies

### Strategy 1: Complete Pipeline (Production)
```powershell
# All stages including Google Places API
python manipulation/ellis-0-scan.py
Rscript manipulation/ellis-1-open-data.R
Rscript manipulation/ellis-2-open-data.R
Rscript manipulation/ellis-3-open-data.R
Rscript manipulation/ellis-4-open-data.R
Rscript manipulation/ellis-5-open-data.R
Rscript manipulation/ellis-6-transform.R
Rscript manipulation/ellis-last.R
```
**Total Runtime**: ~5-10 minutes  
**API Calls**: ~500 (Google Places)

### Strategy 2: Open Data Only (Default)
```powershell
# Skip ellis-0, use existing cafe data
Rscript manipulation/ellis-1-open-data.R
Rscript manipulation/ellis-2-open-data.R
Rscript manipulation/ellis-3-open-data.R
Rscript manipulation/ellis-4-open-data.R
Rscript manipulation/ellis-5-open-data.R
Rscript manipulation/ellis-6-transform.R
Rscript manipulation/ellis-last.R
```
**Total Runtime**: ~3-5 minutes  
**API Calls**: 0 (assuming ellis-0 already run)

### Strategy 3: Task-Based Execution
```powershell
# Using VS Code tasks (defined in .vscode/tasks.json)
# Run task: "Ellis Pipeline - Open Data Only(NEW)"
```
**Benefit**: Integrated with VS Code, error handling built-in

### Strategy 4: Individual Stage Re-run
```powershell
# Re-run just the transformation stage
Rscript manipulation/ellis-6-transform.R
Rscript manipulation/ellis-last.R  # Update database
```
**Use Case**: After modifying ellis-6 logic or adding new calculations

### Strategy 5: Development Mode
```r
# In each ellis-N script, adjust RECORD_LIMIT
RECORD_LIMIT <- 100  # Fast testing
# RECORD_LIMIT <- 1000  # Default development
# RECORD_LIMIT <- NULL  # Production (all records)
```

### Execution Flow Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│                  EXECUTION STRATEGIES                            │
└─────────────────────────────────────────────────────────────────┘

  STRATEGY 1: FULL PIPELINE (First Run or Data Refresh)
  ┌───────────────────────────────────────────────────────────┐
  │  ellis-0 → ellis-1 → ellis-2 → ellis-3 → ellis-4 →       │
  │  ellis-5 → ellis-6 → ellis-last                           │
  │                                                           │
  │  Duration: ~5-10 minutes                                  │
  │  Network: Required (APIs)                                 │
  │  Use Case: Initial data collection or full refresh        │
  └───────────────────────────────────────────────────────────┘

  STRATEGY 2: OPEN DATA ONLY (Daily Updates)
  ┌───────────────────────────────────────────────────────────┐
  │  [skip ellis-0]                                           │
  │  ellis-1 → ellis-2 → ellis-3 → ellis-4 → ellis-5 →       │
  │  ellis-6 → ellis-last                                     │
  │                                                           │
  │  Duration: ~3-5 minutes                                   │
  │  Network: Required (Edmonton Open Data only)              │
  │  Use Case: Update demographics, licenses without cafe     │
  │            rescan (cafe data changes slowly)              │
  └───────────────────────────────────────────────────────────┘

  STRATEGY 3: TRANSFORMATION ONLY (Analysis Refinement)
  ┌───────────────────────────────────────────────────────────┐
  │  [skip ellis-0 through ellis-5]                           │
  │  ellis-6 → ellis-last                                     │
  │                                                           │
  │  Duration: ~1 minute                                      │
  │  Network: Not required (uses cached data)                 │
  │  Use Case: Refining spatial join logic, adding new        │
  │            calculated fields                              │
  └───────────────────────────────────────────────────────────┘

  STRATEGY 4: DATABASE REBUILD (Quick Consolidation)
  ┌───────────────────────────────────────────────────────────┐
  │  [skip ellis-0 through ellis-6]                           │
  │  ellis-last                                               │
  │                                                           │
  │  Duration: ~10 seconds                                    │
  │  Network: Not required                                    │
  │  Use Case: Rebuild SQLite database from existing CSV      │
  │            files (e.g., after database corruption)        │
  └───────────────────────────────────────────────────────────┘
```

---

## Technical Insights

### Why Ellis-0 Takes So Long
```
Grid Points: 48
Searches per Point: 10 (3 types + 7 keywords)
Total Searches: 480
Average Search Time: ~2 seconds (API call + processing)
Pagination: Some searches return 60+ results (3 pages)
Details API: 1,785 places × ~0.5 seconds = ~15 minutes

Total: ~30-40 minutes (with rate limiting)

Optimization in Practice:
• Caching: Deduplicate by place_id (prevents re-fetching)
• Filtering: is_likely_cafe() reduces false positives
• Smart Grid: 0.05° grid size balances coverage vs redundancy
```

### Why Spatial Join (Ellis-6) is Critical
```
Without Spatial Join:
  ❌ Cafe location data isolated from context
  ❌ No way to aggregate cafes by neighborhood
  ❌ Cannot correlate cafe density with demographics

With Spatial Join:
  ✅ Each cafe linked to neighborhood
  ✅ Can answer: "How many cafes in high-density areas?"
  ✅ Enables spatial analysis and visualization
  ✅ Supports questions like: "Underserved neighborhoods?"
```

### Database Design Philosophy
```
Single SQLite File vs. Multiple CSVs:

Advantages of SQLite:
  • Atomic queries across datasets (JOINs)
  • Indexed lookups (faster queries)
  • ACID compliance (data integrity)
  • Single file distribution
  • SQL interface (universal)

Advantages of CSVs:
  • Human-readable (debugging)
  • Version control friendly (git diff)
  • No special tools needed (Excel, pandas, R)
  • Stage-by-stage audit trail

Solution: BOTH
  • CSV for transparency and debugging
  • SQLite for analysis and querying
```

---

## Research Use Cases

### Enabled by This Pipeline
1. **Cafe Density Analysis**: "Where are cafes concentrated in Edmonton?"
2. **Demographic Correlation**: "Do high-income neighborhoods have more cafes?"
3. **Service Gap Identification**: "Which neighborhoods lack coffee shops?"
4. **Competitive Landscape**: "Where is Square One Coffee relative to competitors?"
5. **Expansion Planning**: "Which neighborhoods have high population density but few cafes?"
6. **Trend Analysis**: "How has cafe distribution changed over time?" (re-run ellis-0 periodically)

### Example Research Questions
```sql
-- Q1: Which neighborhoods have the most cafes per capita?
SELECT 
  neighborhood,
  COUNT(*) as cafe_count,
  MAX(population) as pop,
  ROUND(MAX(population) * 1.0 / COUNT(*), 0) as people_per_cafe
FROM ellis_6_cafes_with_demographics
WHERE population IS NOT NULL
GROUP BY neighborhood
ORDER BY people_per_cafe DESC;

-- Q2: High-density neighborhoods with low cafe coverage
SELECT 
  neighborhood,
  COUNT(*) as cafe_count,
  MAX(density_of_population) as density,
  MAX(population) as pop
FROM ellis_6_cafes_with_demographics
WHERE density_of_population > 4000  -- High density threshold
GROUP BY neighborhood
HAVING cafe_count < 5  -- Low cafe count
ORDER BY density DESC;

-- Q3: Cafe ratings by neighborhood demographic
SELECT 
  e6.neighborhood,
  AVG(e0.rating) as avg_rating,
  COUNT(*) as cafe_count,
  MAX(e6.density_of_population) as density
FROM ellis_6_cafes_with_demographics e6
LEFT JOIN ellis_0_cafes e0 ON e6.name = e0.name
WHERE e0.rating IS NOT NULL
GROUP BY e6.neighborhood
ORDER BY avg_rating DESC;
```

---

## Summary & Key Takeaways

### Pipeline Strengths
✅ **Comprehensive**: Grid-based search ensures complete cafe coverage  
✅ **Reproducible**: Idempotent scripts, documented transformations  
✅ **Multi-Format**: CSV, RDS, SQLite outputs for different use cases  
✅ **Contextual**: Links cafes to demographic and geographic context  
✅ **Modular**: Each stage independent, easy to debug/modify  
✅ **Open Data First**: Maximizes free public data sources  
✅ **Research-Ready**: Final output optimized for analysis

### Pipeline Limitations
⚠️ **Ellis-0 Runtime**: 2-3 minutes (API rate-limited, can't parallelize)  
⚠️ **Google API Dependency**: Requires paid API key (though generous free tier)  
⚠️ **Static Data**: Snapshots in time, not real-time updates  
⚠️ **Coordinate Accuracy**: Some cafes may be slightly mislocated  
⚠️ **Neighborhood Boundaries**: Administrative boundaries may not match perceptual neighborhoods

### Best Practices Demonstrated
1. **Staged ETL**: Clear separation of extract, transform, load
2. **Error Handling**: Defensive programming throughout
3. **Documentation**: Self-documenting code with roxygen-style headers
4. **Logging**: Verbose output for monitoring and debugging
5. **Verification**: Post-save checks ensure data integrity
6. **Reproducibility**: Overwrite mode, fixed random seeds (if applicable)

### Recommended Workflow
```
[FIRST RUN]
  1. Run ellis-0 (once, takes time)
  2. Run ellis-1 through ellis-6
  3. Run ellis-last
  4. Verify global-data.sqlite created

[ONGOING UPDATES]
  1. Skip ellis-0 (cafe data stable)
  2. Run ellis-1 through ellis-5 (refresh open data)
  3. Run ellis-6 (recompute transformations)
  4. Run ellis-last (update database)

[ANALYSIS REFINEMENT]
  1. Modify ellis-6 transformation logic
  2. Re-run ellis-6 + ellis-last
  3. Test queries against updated database
```

---

## Appendix: Quick Reference

### File Locations
```
manipulation/
  ├── ellis-0-scan.py           (Python, Google Places)
  ├── ellis-1-open-data.R       (R, Property Assessment)
  ├── ellis-2-open-data.R       (R, Business Licenses)
  ├── ellis-3-open-data.R       (R, Community Services)
  ├── ellis-4-open-data.R       (R, Neighborhood Geometries)
  ├── ellis-5-open-data.R       (R, Population Data)
  ├── ellis-6-transform.R       (R, Spatial Join + Enrichment)
  └── ellis-last.R              (R, SQLite Consolidation)

data-private/derived/
  ├── ellis-0/
  │   ├── ellis-0-scan.csv
  │   └── ellis-0-scan.rds
  ├── ellis-1-open-data/
  │   ├── ellis-1-open-data.csv
  │   └── ellis-1-open-data.rds
  ├── ellis-2-open-data/
  │   ├── ellis-2-open-data.csv
  │   └── ellis-2-open-data.rds
  ├── ellis-3-open-data/
  │   ├── ellis-3-open-data.csv
  │   └── ellis-3-open-data.rds
  ├── ellis-4-open-data/
  │   ├── ellis-4-open-data.csv
  │   └── ellis-4-open-data.rds
  ├── ellis-5-open-data/
  │   ├── ellis-5-open-data.csv
  │   └── ellis-5-open-data.rds
  ├── ellis-6-transform/
  │   ├── ellis-6-transform.csv
  │   └── ellis-6-transform.rds
  └── global-data.sqlite         (Consolidated database)
```

### Key Dependencies
```r
# R Packages
library(tidyverse)  # Data manipulation
library(httr)       # HTTP requests
library(jsonlite)   # JSON parsing
library(DBI)        # Database interface
library(RSQLite)    # SQLite driver
library(sf)         # Spatial features (ellis-6 only)
```

```python
# Python Packages
import requests     # HTTP requests
import pandas       # Data frames
import dotenv       # Environment variables
```

### Environment Variables
```bash
# .Renv file in manipulation/ directory
PLACES_API_KEY=your_google_places_api_key_here
```

### Common Tasks
```powershell
# Full pipeline
python manipulation/ellis-0-scan.py
Rscript manipulation/ellis-1-open-data.R
# ... (continue through ellis-6)
Rscript manipulation/ellis-last.R

# Open data only (skip ellis-0)
Rscript manipulation/ellis-1-open-data.R
# ... (continue through ellis-6)
Rscript manipulation/ellis-last.R

# Transformation only (refine analysis)
Rscript manipulation/ellis-6-transform.R
Rscript manipulation/ellis-last.R

# Database rebuild
Rscript manipulation/ellis-last.R
```

---

**END OF STUDY DOCUMENT**

*This document comprehensively analyzes the Ellis data pipeline architecture, data flow, transformation logic, and execution strategies. All ASCII diagrams and technical details are based on direct examination of the source code as of December 19, 2025.*
