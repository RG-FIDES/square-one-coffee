# CACHE Manifest: Ellis Pipeline Output Data

**Last Updated**: December 19, 2025  
**Pipeline Version**: Ellis 1-6 + Last  
**Purpose**: Document analysis-ready datasets produced by the Ellis Island data preparation pattern

---

This manifest provides definitive information and metadata about the files **after they have been prepared** by the Ellis Island pattern. The Ellis pipeline transforms raw data from multiple sources (Google Places API, Edmonton Open Data) into structured, analysis-ready datasets optimized for cafe location research, demographic analysis, and urban planning insights.

## Overview

The Ellis Pipeline produces a consolidated SQLite database (`data-private/derived/global-data.sqlite`) containing 6 tables representing different stages of data collection and transformation. These tables support exploratory data analysis (EDA), reporting, and statistical modeling workflows demonstrated in `./analysis/eda-1/`.

### Data Sources Consolidated
- **Google Places API**: Cafe locations, ratings, business details (Note: ellis-0 not run in current session)
- **Edmonton Open Data Portal**: Property assessments, business licenses, traffic data, neighborhood boundaries, demographics
- **Spatial Transformations**: Neighborhood assignments via spatial joins, population density calculations

### Output Formats
- **Primary**: SQLite database (`global-data.sqlite`) with 6 tables
- **Supporting**: Individual CSV and RDS files per pipeline stage in `data-private/derived/ellis-N/`

---

## Summary Table

| **Database**                  | **Table Name**                      | **Purpose**                                           | **Records** | **Primary Key**           |
|-------------------------------|-------------------------------------|-------------------------------------------------------|-------------|---------------------------|
| `global-data.sqlite`          | `ellis_0_cafes`                     | Comprehensive cafe data from Google Places API        | ~1,864      | `place_id`                |
| `global-data.sqlite`          | `ellis_1_property_assessment`       | Property assessment and valuation data                | 1,000       | `account_number`          |
| `global-data.sqlite`          | `ellis_2_business_licenses`         | Transit stop locations (misnamed - actually ETS data) | 1,000       | `stop_name, stop_lat, stop_lon` |
| `global-data.sqlite`          | `ellis_3_community_services`        | Traffic volume data by site and year                  | 1,000       | `site_number, year`       |
| `global-data.sqlite`          | `ellis_4_open_data`                 | Neighborhood boundary geometries (GeoJSON)            | 403         | `neighbourh` (neighborhood ID) |
| `global-data.sqlite`          | `ellis_5_open_data`                 | Population counts by neighborhood                     | 278         | `neighbourhood_number`    |
| `global-data.sqlite`          | `ellis_6_cafes_with_demographics`   | Cafes enriched with neighborhood demographics         | 1,864       | None (composite: `name, address`) |

**Note**: Table names are standardized as `ellis_N_*` but represent distinct Edmonton Open Data endpoints. Ellis-2 and Ellis-3 endpoints differ from their generic naming.

---

# Cafe Location Data (Ellis-0)

Comprehensive cafe and coffee shop data collected via Google Places API with systematic grid-based search coverage.

## ellis_0_cafes Table Metadata

### Table Overview
- **Database**: `data-private/derived/global-data.sqlite`
- **Table Name**: `ellis_0_cafes`
- **Purpose**: Complete catalog of Edmonton cafes with ratings, reviews, contact info, and business details
- **Coverage**: ~1,864 cafe records (comprehensive Edmonton coverage via grid search)
- **Data Source**: Google Places API - Nearby Search + Place Details endpoints
- **Collection Method**: Grid-based search (0.05° cells, 3,500m radius, 3 types × 7 keywords per point)
- **Relationship**: Source table for `ellis_6`; join on `name` (with caution due to text matching)
- **Special Note**: Requires Google Places API key; not run in every pipeline execution (data relatively static)

### Column Reference

#### Identifiers
- **place_id** (character): Google Places unique identifier (PRIMARY KEY)
  - Format: `ChIJ...` (stable across API calls)
  - Use for deduplication and external Google Maps integration

#### Business Information
- **name** (character): Business name (e.g., "Square One Coffee", "Transcend Coffee")
- **address** (character): Short-form address (vicinity)
- **formatted_address** (character): Complete formatted address with postal code

#### Location Fields
- **lat** (numeric): Latitude in decimal degrees (WGS84)
- **lng** (numeric): Longitude in decimal degrees (WGS84)
- **types** (character): Comma-separated Google Place types (e.g., "cafe,food,point_of_interest")

#### Quality Metrics
- **rating** (numeric): Average Google rating (1.0 to 5.0 scale)
  - NULL if no reviews available
- **user_ratings_total** (integer): Total number of Google reviews
  - Indicates review credibility (prefer >20 for statistical reliability)

#### Operational Status
- **business_status** (character): Current operational status
  - `OPERATIONAL`: Active business
  - `CLOSED_TEMPORARILY`: Temporarily closed
  - `CLOSED_PERMANENTLY`: Out of business
- **price_level** (integer): Price indication (1-4 scale)
  - 1: Inexpensive ($)
  - 2: Moderate ($$)
  - 3: Expensive ($$$)
  - 4: Very Expensive ($$$$)
  - NULL: No price data available

#### Contact & Details
- **phone** (character): Formatted phone number (e.g., "(780) 123-4567")
- **website** (character): Business website URL
- **hours** (character): Semicolon-separated opening hours (e.g., "Monday: 7:00 AM – 5:00 PM; Tuesday: 7:00 AM – 5:00 PM")
- **is_open_now** (logical): Boolean indicating if currently open (at time of API call)
- **description** (character): Google editorial summary (if available)

### Key Business Rules for Queries
- **Primary Key**: Always use `place_id` for unique identification (not name/address)
- **Rating Credibility**: Filter `user_ratings_total >= 20` for statistically reliable ratings
- **Active Businesses**: Filter `business_status = 'OPERATIONAL'` for current market analysis
- **Quality Cafes**: Common threshold: `rating >= 4.0` AND `user_ratings_total >= 50`
- **Name Matching**: Joining with `ellis_6` on name is fuzzy; expect some mismatches

### Place Types Classification
Common type combinations in this dataset:
- **cafe, food, point_of_interest, establishment**: Traditional cafe
- **cafe, bakery, food, store**: Cafe with bakery
- **coffee_shop, cafe, food**: Specialty coffee shop
- **restaurant, cafe, food**: Restaurant with cafe service
- **bar, cafe, food**: Cafe/bar hybrid

### Data Quality Indicators
- **High Confidence**: `user_ratings_total > 100` (well-established)
- **Moderate Confidence**: `user_ratings_total 20-100` (known business)
- **Low Confidence**: `user_ratings_total < 20` (new or niche)
- **Unknown Quality**: `rating IS NULL` (no reviews yet)

### Linking Notes
- **To ellis_6**: Join on `name` (text match) to add ratings/reviews to demographic analysis
  - Warning: Name variations (e.g., "Starbucks" vs "Starbucks Coffee") may cause mismatches
  - Consider fuzzy string matching (e.g., `stringdist` package in R)
- **Spatial Analysis**: Use `lat`/`lng` for distance calculations, proximity analysis, mapping
- **External Integration**: `place_id` links to Google Maps, Street View, additional Place Details API calls

### Usage Notes for AI Queries
- **Competitive Analysis**: Compare SOC locations against competitors by rating, review count
- **Market Research**: Identify high-rated cafes (potential acquisition targets or market leaders)
- **Customer Sentiment**: Higher ratings in certain neighborhoods may indicate demographic preferences
- **Operational Insights**: Check hours patterns (early open times, weekend availability)
- **Website Presence**: Cafes with websites may be more established/professional
- **Price Positioning**: SOC can compare price level against competitors in same neighborhoods
- **Temporal Considerations**: `is_open_now` reflects API call time; use `hours` for analysis
- **Missing Data**: Some fields (website, phone, price_level) frequently NULL for small businesses

### Common Query Patterns

#### Top-Rated Cafes
```sql
SELECT name, rating, user_ratings_total, formatted_address
FROM ellis_0_cafes
WHERE business_status = 'OPERATIONAL'
  AND user_ratings_total >= 50
ORDER BY rating DESC, user_ratings_total DESC
LIMIT 20;
```

#### Square One Coffee Locations
```sql
SELECT name, formatted_address, rating, user_ratings_total, website
FROM ellis_0_cafes
WHERE name LIKE '%Square One%' OR name LIKE '%Square 1%'
ORDER BY rating DESC;
```

#### Cafes with Full Contact Info
```sql
SELECT name, phone, website, rating
FROM ellis_0_cafes
WHERE phone IS NOT NULL 
  AND website IS NOT NULL
  AND business_status = 'OPERATIONAL'
ORDER BY user_ratings_total DESC;
```

---

# Property Assessment Data (Ellis-1)

Data from Edmonton's property assessment system, providing real estate context for cafe locations and neighborhood characteristics.

## ellis_1_property_assessment Table Metadata

### Table Overview
- **Database**: `data-private/derived/global-data.sqlite`
- **Table Name**: `ellis_1_property_assessment`
- **Purpose**: Property assessment values, tax classifications, and geographic locations for real estate analysis
- **Coverage**: 1,000 property records (development sample; production would include all Edmonton properties)
- **Data Source**: Edmonton Open Data - Property Assessments (`q7d6-ambg`)
- **Relationship**: Can be linked to `ellis_4_open_data` via neighborhood name/ID for spatial aggregation

### Column Reference

#### Identifiers
- **account_number** (numeric): Unique property account identifier in city system
- **suite** (numeric): Suite/unit number within property (if applicable)
- **house_number** (numeric): Street address number

#### Location Fields
- **street_name** (character): Street name of property
- **neighbourhood_id** (numeric): Numeric identifier for neighborhood
- **neighbourhood** (character): Neighborhood name (text)
- **ward** (character): Municipal ward designation
- **latitude** (numeric): Property latitude (WGS84)
- **longitude** (numeric): Property longitude (WGS84)
- **point_location** (character): Formatted coordinate string

#### Assessment & Tax Fields
- **assessed_value** (numeric): Total assessed property value (CAD)
- **tax_class** (character): Property tax classification
- **garage** (character): Garage type/presence indicator
- **mill_class_1** (character): Primary mill rate class
- **mill_class_2** (character): Secondary mill rate class (if applicable)
- **mill_class_3** (logical): Tertiary mill rate class (rarely used)
- **tax_class_pct_1** (numeric): Percentage of property in tax class 1
- **tax_class_pct_2** (numeric): Percentage of property in tax class 2
- **tax_class_pct_3** (logical): Percentage of property in tax class 3 (rarely used)

### Key Business Rules for Queries
- **Geocoding**: Use `latitude` and `longitude` for spatial joins with cafe data
- **Neighborhood Aggregation**: Group by `neighbourhood` to analyze property values by area
- **Commercial Properties**: Filter `tax_class` for commercial/retail properties near cafes
- **Ward Analysis**: Use `ward` for political district-level aggregation
- **Development Sample**: Current dataset limited to 1,000 records; production queries should handle full dataset

### Linking Notes
- Link to `ellis_4_open_data` using `neighbourhood` (text match) or `neighbourhood_id`
- Link to `ellis_6_cafes_with_demographics` via `neighbourhood` for property context around cafes
- Spatial join possible using `latitude`/`longitude` with cafe coordinates

### Usage Notes for AI Queries
- Property values (`assessed_value`) provide economic context for cafe location analysis
- Commercial properties near high-rated cafes may indicate strong retail districts
- Ward-level aggregation useful for municipal planning insights
- Tax class percentages indicate mixed-use properties (residential + commercial)
- Missing values in mill_class_3 and tax_class_pct_3 are normal (rarely used)

---

# Transit Stop Data (Ellis-2)

Edmonton Transit System (ETS) stop locations. **Note**: Despite table name suggesting "business licenses," this dataset contains transit stop data.

## ellis_2_business_licenses Table Metadata

### Table Overview
- **Database**: `data-private/derived/global-data.sqlite`
- **Table Name**: `ellis_2_business_licenses` (misleading name - contains ETS stop data)
- **Purpose**: Transit stop locations for analyzing cafe accessibility and foot traffic potential
- **Coverage**: 1,000 ETS stop records (development sample)
- **Data Source**: Edmonton Open Data - ETS Stops (`bubb-yjc9`)
- **Relationship**: Can be spatially joined with cafe locations to analyze transit accessibility

### Column Reference

#### Stop Identification
- **stop_name** (character): Name/description of transit stop (e.g., "Southgate Centre", "University Station")

#### Location Fields
- **stop_lat** (numeric): Stop latitude (WGS84)
- **stop_lon** (numeric): Stop longitude (WGS84)

### Key Business Rules for Queries
- **Proximity Analysis**: Calculate distance from cafes to nearest transit stops
- **Accessibility**: Identify cafes within walking distance (e.g., 500m) of transit
- **Foot Traffic**: Transit stops indicate potential customer flow
- **Development Sample**: Limited to 1,000 stops; production would include full network

### Linking Notes
- Spatial join with `ellis_6_cafes_with_demographics` using stop coordinates
- Distance calculations: Use Haversine formula or spatial functions with lat/lon
- No direct key-based joins; relies on spatial proximity

### Usage Notes for AI Queries
- High cafe density near major transit hubs indicates transit-oriented development
- Cafes >500m from transit may rely more on car traffic or residential customers
- Stop names provide context (e.g., "University" stops indicate student populations)
- Use spatial buffers (e.g., `st_buffer()` in sf package) for "cafes near transit" queries

---

# Traffic Volume Data (Ellis-3)

Traffic volume measurements at monitoring sites across Edmonton, indicating vehicle flow and potential visibility for cafe locations.

## ellis_3_community_services Table Metadata

### Table Overview
- **Database**: `data-private/derived/global-data.sqlite`
- **Table Name**: `ellis_3_community_services` (misleading name - contains traffic data)
- **Purpose**: Annual average daily vehicle volumes for analyzing location visibility and accessibility
- **Coverage**: 1,000 site-year records (development sample)
- **Data Source**: Edmonton Open Data - Traffic Volume (`b58q-nxjr`)
- **Relationship**: Time-series data (site × year); can be spatially joined with cafes

### Column Reference

#### Site Identification
- **site_number** (numeric): Unique traffic monitoring site identifier
- **site_name** (character): Descriptive name/location of monitoring site

#### Temporal Fields
- **year** (numeric): Year of measurement (e.g., 2018, 2019, 2020)

#### Volume Metrics
- **average_daily_volume** (numeric): Average number of vehicles per day at this site during this year

#### Location Fields
- **latitude** (numeric): Site latitude (WGS84)
- **longitude** (numeric): Site longitude (WGS84)
- **location** (character): Formatted address or description
- **geometry_point** (character): Formatted coordinate string

### Key Business Rules for Queries
- **Temporal Analysis**: Filter by recent years for current traffic patterns
- **Proximity to Cafes**: Spatial join to find cafes near high-traffic locations
- **Visibility Hypothesis**: High traffic volume → more potential customers if cafe is visible from road
- **Longitudinal Trends**: Track traffic changes over time using `year` dimension

### Traffic Volume Interpretation
- **<5,000 vehicles/day**: Low-traffic residential streets
- **5,000-15,000**: Moderate neighborhood arterials
- **15,000-30,000**: Major arterials and commercial corridors
- **>30,000**: High-volume expressways (may have high visibility but low accessibility)

### Linking Notes
- Spatial join with `ellis_6_cafes_with_demographics` to analyze cafe placement near traffic
- Link to same table over time using `site_number` to track trends
- No direct join to other tables; relies on spatial relationships

### Usage Notes for AI Queries
- Cafes near high-traffic sites may benefit from drive-by visibility
- Consider trade-off: high traffic may indicate noise/pollution vs. visibility benefits
- Use nearest-neighbor spatial join to assign traffic volume to each cafe
- Temporal analysis: Compare cafe ratings/success in high vs. low traffic areas
- Traffic volumes may have changed significantly during COVID-19 (2020-2021)

---

# Neighborhood Boundaries (Ellis-4)

Geographic boundary polygons for Edmonton neighborhoods, essential for spatial joins and demographic aggregation.

## ellis_4_open_data Table Metadata

### Table Overview
- **Database**: `data-private/derived/global-data.sqlite`
- **Table Name**: `ellis_4_open_data`
- **Purpose**: Neighborhood boundary geometries (GeoJSON polygons) for spatial operations and cartography
- **Coverage**: 403 neighborhood records (complete coverage of Edmonton)
- **Data Source**: Edmonton Open Data - Neighborhood Boundaries (`5bk4-5txu`)
- **Relationship**: **CRITICAL** for `ellis_6` spatial join; used to assign neighborhoods to cafe points
- **Special Handling**: `the_geom` column contains WKT (Well-Known Text) geometry requiring `sf::st_as_sf()` conversion

### Column Reference

#### Geometry (Primary Field)
- **the_geom** (character): Well-Known Text (WKT) representation of neighborhood polygon boundary
  - Format: `MULTIPOLYGON(((-113.xxx 53.yyy, ...)))`
  - CRS: WGS84 (EPSG:4326)
  - Used by `ellis-6-transform.R` for spatial joins

#### Identification
- **name** (character): Official neighborhood name (e.g., "Ritchie", "Oliver", "Downtown")
- **neighbourh** (numeric): Numeric neighborhood identifier (primary key)

#### Metadata Fields
- **descriptiv** (character): Brief descriptive text about neighborhood
- **descriptio** (character): Extended description (may be truncated column name)
- **date_effec** (logical): Effective date (currently all NA in sample)
- **time_effec** (logical): Effective time (currently all NA in sample)
- **date_eff_2** (logical): Secondary effective date (currently all NA in sample)
- **time_eff_2** (logical): Secondary effective time (currently all NA in sample)

### Key Business Rules for Queries
- **Spatial Join Requirement**: Must convert `the_geom` to sf geometry object before spatial operations
- **Point-in-Polygon**: Use `sf::st_within()` to determine which neighborhood contains a given cafe point
- **CRS Consistency**: Ensure all spatial data uses EPSG:4326 before joins
- **Neighborhood Names**: Match on `name` field (character) when joining with demographic data

### Spatial Operations (R sf Package)
```r
# Convert to spatial object
neighborhoods_sf <- st_as_sf(ellis_4_data, wkt = "the_geom", crs = 4326)

# Spatial join example
cafes_sf <- st_as_sf(cafe_data, coords = c("lng", "lat"), crs = 4326)
cafes_with_neighborhood <- st_join(cafes_sf, neighborhoods_sf, join = st_within)
```

### Linking Notes
- **Critical Link**: This table enables the spatial transformation in `ellis_6`
- Link to `ellis_5_open_data` using `name` field (text match on neighborhood name)
- Link to `ellis_1_property_assessment` using `name` or `neighbourh` ID
- Spatial join with any lat/lng data to assign neighborhood membership

### Usage Notes for AI Queries
- This is a **lookup table** for spatial operations, not typically queried directly for analysis
- Use in conjunction with `sf` package for R spatial analysis
- Python users: Convert to GeoDataFrame using `geopandas.from_wkt()`
- Geometry column is large; avoid SELECT * in production queries if possible
- Neighborhood boundaries are administrative and may not match residents' perceptions
- Some cafes may fall outside neighborhood boundaries (e.g., parks, river valley)

---

# Population Demographics (Ellis-5)

Population counts by Edmonton neighborhood, used to calculate density and demographic context.

## ellis_5_open_data Table Metadata

### Table Overview
- **Database**: `data-private/derived/global-data.sqlite`
- **Table Name**: `ellis_5_open_data`
- **Purpose**: Neighborhood-level population totals for demographic context and density calculations
- **Coverage**: 278 neighborhood records (complete Edmonton coverage)
- **Data Source**: Edmonton Open Data - Demographics by Neighborhood (`eg3i-f4bj`)
- **Relationship**: Joins with `ellis_4` via neighborhood name for spatial-demographic integration; used in `ellis_6` transformation

### Column Reference

#### Identification
- **neighbourhood_number** (numeric): Unique neighborhood identifier (primary key)
- **neighbourhood** (character): Neighborhood name (must match `ellis_4.name` for joins)

#### Demographic Fields
- **total_population** (numeric): Total population count for neighborhood (census-based)

#### Administrative
- **ward** (character): Municipal ward designation (matches `ellis_1` ward field)

### Key Business Rules for Queries
- **Name Matching**: Normalize neighborhood names (uppercase, trim whitespace) before joins
- **Population Density**: Combine with area from `ellis_4` geometries: `density = population / area_sqkm`
- **Ward Aggregation**: Sum populations by `ward` for municipal district analysis
- **Zero Population**: Some neighborhoods may have zero population (industrial, parks)

### Linking Notes
- **Primary Link**: Join with `ellis_4_open_data` on `neighbourhood` (text) or `neighbourhood_number`
- Link to `ellis_1_property_assessment` via `neighbourhood` for property-population correlation
- Link to `ellis_6_cafes_with_demographics` via `neighbourhood` (already pre-joined)
- Ward-level aggregation possible with `ellis_1` data using `ward` field

### Usage Notes for AI Queries
- Population data is typically from most recent census; check source metadata for year
- High-population neighborhoods may support more cafes (larger customer base)
- Population density (people/sqkm) is more informative than raw population for cafe analysis
- Consider daytime vs. nighttime population (office districts vs. residential)
- Some neighborhoods may have incomplete data (new developments, annexations)
- Use in combination with property values to understand socioeconomic context

---

# Cafes with Demographics (Ellis-6)

**PRIMARY ANALYSIS TABLE**: Cafe locations enriched with neighborhood demographics through spatial joins and density calculations.

## ellis_6_cafes_with_demographics Table Metadata

### Table Overview
- **Database**: `data-private/derived/global-data.sqlite`
- **Table Name**: `ellis_6_cafes_with_demographics`
- **Purpose**: Analysis-ready dataset combining cafe locations with neighborhood population and density
- **Coverage**: 1,864 cafe records (Note: Ellis-0 not run in current session; number reflects existing data)
- **Data Source**: **DERIVED** - Created by `ellis-6-transform.R` from ellis-0, ellis-4, and ellis-5
- **Relationship**: Final output table for cafe demographic analysis; links back to ellis-0 for detailed cafe attributes
- **Special Note**: This is the "analysis-ready rectangle" optimized for EDA and reporting workflows

### Column Reference

#### Cafe Identification
- **name** (character): Cafe business name (e.g., "Square One Coffee", "Transcend Coffee")
- **address** (character): Street address of cafe location

#### Geographic Context
- **neighborhood** (character): Neighborhood name assigned via spatial join (from `ellis_4`)
  - Source: Point-in-polygon test using `sf::st_within()`
  - May be NA if cafe location falls outside neighborhood boundaries

#### Demographic Context
- **population** (numeric): Total population of the cafe's neighborhood (from `ellis_5`)
- **area** (numeric): Neighborhood area in square kilometers (calculated from `ellis_4` geometry)
- **density_of_population** (numeric): Population density (people per sq km)
  - Calculated: `population / area`
  - Primary metric for understanding neighborhood demographic intensity

### Key Business Rules for Queries
- **Composite Uniqueness**: No single primary key; use `name` + `address` combination
- **Null Neighborhoods**: Some cafes may have `neighborhood = NA` if outside defined boundaries
- **Density Interpretation**: 
  - <2,000 ppl/sqkm: Low-density suburban/rural
  - 2,000-5,000: Moderate suburban
  - 5,000-10,000: Dense urban residential
  - >10,000: Very high-density downtown/core areas
- **Area Precision**: Area calculated from polygon geometry; precision varies by neighborhood size

### Analysis Patterns

#### Cafe Density by Neighborhood Demographics
```r
# Cafes per capita by neighborhood
cafe_density <- ellis_6_data %>%
  group_by(neighborhood) %>%
  summarize(
    cafe_count = n(),
    population = first(population),
    people_per_cafe = population / cafe_count
  ) %>%
  arrange(people_per_cafe)
```

#### High-Density Neighborhoods with Low Cafe Coverage
```sql
-- SQL query for underserved areas
SELECT 
  neighborhood,
  COUNT(*) as cafe_count,
  MAX(density_of_population) as pop_density,
  MAX(population) as population
FROM ellis_6_cafes_with_demographics
WHERE density_of_population > 5000
GROUP BY neighborhood
HAVING cafe_count < 10
ORDER BY pop_density DESC;
```

### Linking Notes
- **No direct foreign keys** but can link back to source tables:
  - Join with ellis-0 cafe data using `name` (if ellis-0 exists) for ratings, hours, reviews
  - Join with `ellis_1` property data using `neighborhood` for real estate context
  - Join with `ellis_2` transit data via spatial proximity for accessibility analysis
  - Join with `ellis_3` traffic data via spatial proximity for visibility analysis
- **Recommended**: Treat as primary table and enrich as needed rather than building from scratch

### Usage Notes for AI Queries
- **Primary Use Case**: Exploratory data analysis of cafe distribution and demographics
- **EDA Workflow** (see `./analysis/eda-1/`):
  1. Load this table as `ds0` (main dataset)
  2. Create derived datasets (e.g., neighborhood summaries, density categories)
  3. Visualize: cafe counts by density, population distributions, spatial maps
  4. Statistical analysis: correlations, t-tests, regression models
- **Missing Values**: 
  - Check for NA in `neighborhood` (cafes outside boundaries)
  - NA in `population`/`area`/`density` may occur if neighborhood name mismatch
- **Visualization**: 
  - Scatter plots: density vs. cafe count
  - Maps: Requires joining back to `ellis_4` for geometries
  - Bar charts: Cafe counts by neighborhood (top 20)
- **Statistical Modeling**: 
  - Dependent variable: cafe count per neighborhood
  - Independent variables: population, density, area
  - Control variables: Join with property values, transit access
- **Time Considerations**: Data is cross-sectional (single point in time); no temporal dimension

### Data Quality Notes
- **Spatial Join Accuracy**: Some cafes may be assigned to incorrect neighborhood if coordinates imprecise
- **Name Matching**: Neighborhood names normalized (uppercase, trimmed) but may have inconsistencies
- **Completeness**: 1,864 cafes suggests ellis-0 data exists but may not be from current run
- **Density Calculation**: Assumes uniform population distribution within neighborhood (not true for large neighborhoods)

---

# Cross-Table Relationships and Integration

## Primary Data Flow
```
Ellis-0 (cafes) ─────┐
  • place_id         │
  • name, address    ├──> Ellis-6 (cafes + demographics) [PRIMARY ANALYSIS TABLE]
  • lat, lng         │       • Simplified: name, address, neighborhood
  • rating, reviews  │       • Enhanced: population, density
                     │
Ellis-4 (geometries) ─┤     ← Join back to Ellis-0 for ratings/reviews
  • Neighborhood     │
    polygons         │
                     │
Ellis-5 (population) ─┘
  • Population counts

Ellis-1 (properties) ──> Neighborhood context (via neighborhood name)
Ellis-2 (transit) ──────> Spatial proximity analysis (via coordinates)
Ellis-3 (traffic) ──────> Spatial proximity analysis (via coordinates)
```

## Linking Strategy by Analysis Type

### Cafe Demographics Analysis (Primary)
- **Start with**: `ellis_6_cafes_with_demographics`
- **Enrich with**: 
  - `ellis_0_cafes` (ratings, reviews, contact info) via `name` (text match)
  - `ellis_1` (property values by neighborhood) via `neighborhood`
- **Key**: Composite join on `name` and spatial context

### Cafe Accessibility Analysis
- **Start with**: `ellis_6_cafes_with_demographics`
- **Spatial join**: `ellis_2` (transit stops)
- **Method**: Distance calculation using lat/lng or `sf::st_distance()`
- **Threshold**: 500m walking distance

### Cafe Visibility Analysis
- **Start with**: `ellis_6_cafes_with_demographics`
- **Spatial join**: `ellis_3` (traffic volume)
- **Method**: Nearest-neighbor join or spatial buffer
- **Metric**: Average daily volume at nearest site

### Cartography / Mapping
- **Start with**: `ellis_4_open_data` (neighborhood geometries)
- **Join**: `ellis_6` aggregated by neighborhood
- **Output**: Choropleth maps of cafe density, demographic context

## Data Quality Considerations
- **Spatial Join Precision**: Ellis-6 transformation uses `sf::st_within()` which requires precise coordinates
- **Name Normalization**: Neighborhood names must be standardized (uppercase, trimmed) for text joins
- **Temporal Alignment**: All data sources from different time periods; check source metadata for years
- **Completeness**: Development samples (1,000 records) used in current output; production should use full datasets

---

# Research Applications

## Primary Use Cases

### 1. Cafe Market Saturation Analysis
**Question**: Which neighborhoods are over/under-served by cafes?
**Approach**: 
- Calculate cafes per capita by neighborhood using `ellis_6`
- Compare to population density and property values (`ellis_1`)
- Identify neighborhoods with high population but low cafe count
**Metrics**: 
- People per cafe (target: <3,000)
- Cafes per sq km in dense areas

### 2. Square One Coffee Competitive Context
**Question**: How is SOC positioned relative to competitors?
**Approach**:
- Join `ellis_6` with `ellis_0` to add ratings and review counts
- Filter for SOC locations and competitors in same neighborhoods
- Compare SOC ratings vs. competitors in similar demographic contexts
- Analyze review sentiment and volume trends
**Tables**: `ellis_0_cafes` (ratings), `ellis_6` (demographics)
**Key Metrics**: 
- SOC avg rating vs. neighborhood avg rating
- SOC review count vs. competitor review counts
- Price positioning (from `ellis_0.price_level`)

### 3. Expansion Site Selection
**Question**: Where should new cafes open?
**Approach**:
- Identify high-density neighborhoods with low cafe coverage (`ellis_6`)
- Filter for neighborhoods with transit access (`ellis_2` proximity)
- Check property values and commercial real estate availability (`ellis_1`)
- Prioritize high-traffic corridors (`ellis_3`)

### 4. Demographic-Success Correlation
**Question**: Do cafes in denser neighborhoods have better ratings/reviews?
**Approach**:
- Join `ellis_6` with `ellis_0_cafes` on cafe name
- Correlate `density_of_population` with `rating` and `user_ratings_total`
- Control for other factors (transit access via `ellis_2`, property values via `ellis_1`)
- Test hypothesis: Higher density → more reviews but not necessarily higher ratings
**Statistical Method**: Multiple regression or multilevel modeling
**Example Query**:
```r
cafe_analysis <- ellis_6_data %>%
  inner_join(ellis_0_data, by = "name") %>%
  filter(!is.na(rating), user_ratings_total >= 20) %>%
  select(name, neighborhood, density_of_population, rating, user_ratings_total)

# Correlation test
cor.test(cafe_analysis$density_of_population, cafe_analysis$rating)
```

## Analytical Workflows

### Exploratory Data Analysis (EDA)
**Reference**: `./analysis/eda-1/eda-1.R` and `./analysis/eda-1/eda-1.qmd`

**Step 1**: Load primary table
```r
library(DBI)
library(RSQLite)
con <- dbConnect(SQLite(), "data-private/derived/global-data.sqlite")
ds0 <- dbReadTable(con, "ellis_6_cafes_with_demographics")
dbDisconnect(con)
```

**Step 2**: Create derived datasets
```r
# Neighborhood-level aggregation
ds_neighborhood <- ds0 %>%
  group_by(neighborhood) %>%
  summarize(
    cafe_count = n(),
    population = first(population),
    density = first(density_of_population),
    people_per_cafe = population / cafe_count
  )

# Density categories
ds0 <- ds0 %>%
  mutate(
    density_category = case_when(
      density_of_population < 2000 ~ "Low",
      density_of_population < 5000 ~ "Moderate",
      density_of_population < 10000 ~ "High",
      TRUE ~ "Very High"
    )
  )
```

**Step 3**: Visualizations
- Histogram: Distribution of cafes by population density
- Bar chart: Top 20 neighborhoods by cafe count
- Scatter plot: Population vs. cafe count by neighborhood
- Map: Choropleth of cafe density (requires joining `ellis_4`)

**Step 4**: Statistical summaries
- Correlation matrix: population, density, cafe count
- ANOVA: Cafe count differences by density category
- Summary tables: Descriptive statistics by neighborhood type

### Geospatial Analysis
**Reference**: `manipulation/ellis-6-transform.R` for spatial join patterns

**Step 1**: Load spatial data
```r
library(sf)
con <- dbConnect(SQLite(), "data-private/derived/global-data.sqlite")

# Load geometries
neighborhoods_sf <- dbReadTable(con, "ellis_4_open_data") %>%
  st_as_sf(wkt = "the_geom", crs = 4326)

# Load cafes with demographics
cafes_df <- dbReadTable(con, "ellis_6_cafes_with_demographics")
dbDisconnect(con)
```

**Step 2**: Spatial join for mapping
```r
# Join cafe counts back to neighborhood geometries
neighborhood_summary <- cafes_df %>%
  group_by(neighborhood) %>%
  summarize(cafe_count = n(), avg_density = mean(density_of_population, na.rm=TRUE))

neighborhoods_with_cafes <- neighborhoods_sf %>%
  left_join(neighborhood_summary, by = c("name" = "neighborhood"))
```

**Step 3**: Create maps
```r
library(ggplot2)

ggplot(neighborhoods_with_cafes) +
  geom_sf(aes(fill = cafe_count)) +
  scale_fill_viridis_c() +
  labs(title = "Cafe Density by Neighborhood", fill = "Number of Cafes") +
  theme_minimal()
```

## Integration with Other Data Sources

### Future Enhancements
- **Social Media Data**: Join cafe names with review sentiment from Google/Yelp
- **Walk Scores**: Integrate walkability metrics with transit proximity (`ellis_2`)
- **Income Data**: Add median household income by neighborhood for purchasing power analysis
- **Temporal Analysis**: Re-run ellis-0 periodically to track cafe openings/closures over time

### Cross-Project Integration
- **SOC Internal Data**: Link with POS transaction data, customer counts by location
- **Anecdote Roasters**: Connect wholesale accounts to cafe locations
- **Market Research**: Combine with external reports on coffee consumption trends

---

## AI Copilot Usage Guidelines

### When Querying This Data

**Always**:
1. Start with `ellis_6_cafes_with_demographics` for cafe demographic analysis
2. Check for NA values in `neighborhood` field (cafes outside boundaries)
3. Normalize neighborhood names before text joins (uppercase, trim)
4. Use spatial functions (`sf` package) for proximity analysis
5. Document assumptions about data completeness and time periods

**Consider**:
1. Development data limits (1,000 records in ellis 1-3; 1,864 cafes in ellis-6)
2. Temporal alignment: Data sources may be from different years
3. Spatial precision: Coordinates may have ~10m accuracy
4. Neighborhood definitions: Administrative boundaries vs. perceived neighborhoods

**Avoid**:
1. Assuming completeness: Ellis-0 cafe data may not be current
2. Ignoring spatial context: Always consider geographic relationships
3. Over-interpreting small samples: Current dataset is development-sized
4. Neglecting null values: Check completeness before analysis

### Common Query Patterns

**Pattern 1**: Neighborhood-level aggregation
```r
neighborhood_stats <- dbGetQuery(con, "
  SELECT 
    neighborhood,
    COUNT(*) as cafe_count,
    AVG(population) as avg_population,
    AVG(density_of_population) as avg_density
  FROM ellis_6_cafes_with_demographics
  WHERE neighborhood IS NOT NULL
  GROUP BY neighborhood
  ORDER BY cafe_count DESC
")
```

**Pattern 2**: Density-based filtering
```r
high_density_cafes <- dbGetQuery(con, "
  SELECT name, address, neighborhood, density_of_population
  FROM ellis_6_cafes_with_demographics
  WHERE density_of_population > 8000
  ORDER BY density_of_population DESC
")
```

**Pattern 3**: Cross-table spatial join (requires R)
```r
# Find transit stops near cafes
cafe_transit_distance <- st_distance(cafes_sf, transit_sf)
cafes_with_transit <- cafes_df %>%
  mutate(nearest_transit_m = apply(cafe_transit_distance, 1, min))
```

### Troubleshooting

**Issue**: Neighborhood is NA for some cafes
- **Cause**: Cafe coordinates outside defined neighborhood boundaries
- **Solution**: Check coordinates; may be in parks, river valley, or new developments

**Issue**: Population/density is NA despite neighborhood assigned
- **Cause**: Neighborhood name mismatch between ellis-4 and ellis-5
- **Solution**: Inspect neighborhood names; normalize text (uppercase, trim, remove special characters)

**Issue**: Table not found in database
- **Cause**: Ellis pipeline not run completely, or ellis-last not executed
- **Solution**: Run ellis-last.R to consolidate all tables into SQLite database

**Issue**: Unexpected record counts
- **Cause**: Development mode limits (RECORD_LIMIT = 1000 in ellis 1-5)
- **Solution**: For production analysis, remove RECORD_LIMIT in source scripts and re-run pipeline

---

## Version History

| **Date**       | **Version** | **Changes**                                                  |
|----------------|-------------|--------------------------------------------------------------|
| Dec 19, 2025   | 1.0         | Initial CACHE manifest created based on Ellis 1-6 + Last output |

---

**Manifest Maintainer**: AI Copilot (Project Manager Persona)  
**Last Verified**: December 19, 2025  
**Database Location**: `data-private/derived/global-data.sqlite`  
**Supporting Files**: `data-private/derived/ellis-N/` (CSV and RDS formats)
