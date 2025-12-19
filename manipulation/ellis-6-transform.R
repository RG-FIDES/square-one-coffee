#' ---
#' title: "Ellis-6: Data Transformation and Neighborhood Assignment"
#' subtitle: "Combine cafe locations with neighborhood demographics"
#' author: "RG-FIDES Research Team"
#' date: "last Updated: `r Sys.Date()`"
#' ---

#+ echo=FALSE
# Rscript manipulation/ellis-6-transform.R  # run from project root

# ---- environment-setup ------
library(tidyverse)
library(sf)
library(DBI)
library(RSQLite)

# ---- declare-globals -------
# Input files
ELLIS_0_CSV <- "data-private/derived/ellis-0/ellis-0-scan.csv"
ELLIS_4_CSV <- "data-private/derived/ellis-4-open-data/ellis-4-open-data.csv"
ELLIS_5_CSV <- "data-private/derived/ellis-5-open-data/ellis-5-open-data.csv"

# Output directory
OUTPUT_DIR <- "data-private/derived/ellis-6-transform"
OUTPUT_CSV <- file.path(OUTPUT_DIR, "ellis-6-transform.csv")
OUTPUT_RDS <- file.path(OUTPUT_DIR, "ellis-6-transform.rds")

# ---- declare-functions ------

calculate_population_density <- function(population, area_sqkm) {
  #' Calculate population density (vectorized)
  #'
  #' @param population Total population (vector)
  #' @param area_sqkm Area in square kilometers (vector)
  #' @return Population density (people per sq km)
  
  # Vectorized calculation
  density <- ifelse(is.na(area_sqkm) | area_sqkm == 0, NA, population / area_sqkm)
  return(density)
}

extract_neighborhood_from_geometry <- function(cafes_df, neighborhoods_sf) {
  #' Assign neighborhoods to cafes using spatial join
  #'
  #' @param cafes_df DataFrame with cafe locations (must have lat, lng)
  #' @param neighborhoods_sf SF object with neighborhood geometries
  #' @return DataFrame with neighborhood assignments
  
  message("Performing spatial join to assign neighborhoods...")
  
  # Convert cafes to sf object
  cafes_sf <- st_as_sf(
    cafes_df, 
    coords = c("lng", "lat"), 
    crs = 4326,
    remove = FALSE
  )
  
  # Ensure neighborhoods are in same CRS
  neighborhoods_sf <- st_transform(neighborhoods_sf, 4326)
  
  # Rename the neighborhood name column to avoid conflict with cafe name
  neighborhoods_sf <- neighborhoods_sf %>%
    select(neighborhood_name = name)
  
  # Spatial join
  cafes_with_neighborhood <- st_join(
    cafes_sf, 
    neighborhoods_sf,
    join = st_within,
    left = TRUE
  )
  
  # Convert back to regular dataframe
  result <- cafes_with_neighborhood %>%
    st_drop_geometry() %>%
    rename(neighborhood = neighborhood_name)
  
  return(result)
}

# ---- load-data ------
message("=== Starting Ellis-6: Data Transformation ===")

# Create output directory
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Load cafe data (ellis-0)
message("Loading cafe data from ellis-0...")
cafes_data <- tryCatch({
  read_csv(ELLIS_0_CSV, show_col_types = FALSE)
}, error = function(e) {
  message("Error loading ellis-0 data: ", e$message)
  NULL
})

# Load neighborhood geometry data (ellis-4)
message("Loading neighborhood geometry data from ellis-4...")
neighborhoods_geo <- tryCatch({
  df <- read_csv(ELLIS_4_CSV, show_col_types = FALSE)
  # Convert to sf object - suppress warnings about CRS
  suppressWarnings(st_as_sf(df, wkt = "the_geom", crs = 4326))
}, error = function(e) {
  message("Error loading ellis-4 data: ", e$message)
  NULL
})

# Load population data (ellis-5)
message("Loading population data from ellis-5...")
population_data <- tryCatch({
  read_csv(ELLIS_5_CSV, show_col_types = FALSE)
}, error = function(e) {
  message("Error loading ellis-5 data: ", e$message)
  NULL
})

# Check if all data loaded successfully
if (is.null(cafes_data) || is.null(neighborhoods_geo) || is.null(population_data)) {
  message("❌ Failed to load required data files")
  quit(status = 1)
}

message("Data loaded successfully:")
message("- Cafes: ", nrow(cafes_data), " records")
message("- Neighborhoods (geometry): ", nrow(neighborhoods_geo), " records")
message("- Neighborhoods (population): ", nrow(population_data), " records")

# ---- transform-data ------
message("\n=== Transforming data ===")

# Assign neighborhoods to cafes using spatial join
cafes_with_neighborhoods <- extract_neighborhood_from_geometry(
  cafes_data, 
  neighborhoods_geo
)

# Calculate neighborhood areas (suppress units warnings)
neighborhoods_geo <- neighborhoods_geo %>%
  mutate(
    area_sqm = suppressMessages(as.numeric(st_area(get(attr(., "sf_column"))))),
    area_sqkm = area_sqm / 1000000
  )

# Prepare neighborhood lookup table with area
neighborhood_areas <- neighborhoods_geo %>%
  st_drop_geometry() %>%
  select(
    neighborhood_name = name,
    area_sqkm
  )

# Join population data
# Normalize neighborhood names for matching
population_data_clean <- population_data %>%
  mutate(neighbourhood_upper = toupper(trimws(neighbourhood)))

neighborhood_areas_clean <- neighborhood_areas %>%
  mutate(neighbourhood_upper = toupper(trimws(neighborhood_name)))

# Create final transformed dataset
transformed_data <- cafes_with_neighborhoods %>%
  select(name, address, lat, lng, neighborhood) %>%
  # Standardize neighborhood name for matching
  mutate(neighbourhood_upper = toupper(trimws(neighborhood))) %>%
  # Join with population data
  left_join(
    population_data_clean %>% select(neighbourhood_upper, total_population),
    by = "neighbourhood_upper"
  ) %>%
  # Join with area data
  left_join(
    neighborhood_areas_clean %>% select(neighbourhood_upper, area_sqkm),
    by = "neighbourhood_upper"
  ) %>%
  # Calculate population density (now vectorized)
  mutate(
    population_density = calculate_population_density(total_population, area_sqkm)
  ) %>%
  # Select and rename final columns
  select(
    name,
    address,
    neighborhood,
    population = total_population,
    area = area_sqkm,
    density_of_population = population_density
  )

# ---- verify-values ------
message("\nTransformed data summary:")
message("- Total records: ", nrow(transformed_data))
message("- Cafes with neighborhood assigned: ", sum(!is.na(transformed_data$neighborhood)))
message("- Cafes with population data: ", sum(!is.na(transformed_data$population)))
message("- Cafes with density calculated: ", sum(!is.na(transformed_data$density_of_population)))

# Show sample of data
message("\nSample of transformed data:")
print(head(transformed_data, 10))

# ---- save-to-disk ------
message("\nSaving data to: ", OUTPUT_DIR)

# Save as CSV
write_csv(transformed_data, OUTPUT_CSV)
message("Saved CSV: ", OUTPUT_CSV)

# Save as RDS for R users
saveRDS(transformed_data, OUTPUT_RDS)
message("Saved RDS: ", OUTPUT_RDS)

# Save to global SQLite database
DB_PATH <- "data-private/derived/global-data.sqlite"
DB_DIR <- dirname(DB_PATH)
dir.create(DB_DIR, recursive = TRUE, showWarnings = FALSE)

tryCatch({
  conn <- dbConnect(RSQLite::SQLite(), DB_PATH)
  dbWriteTable(conn, "ellis_6_cafes_with_demographics", transformed_data, overwrite = TRUE)
  dbDisconnect(conn)
  
  message("Saved to SQLite: ", DB_PATH)
  message("  Table: ellis_6_cafes_with_demographics")
  message("  Records: ", nrow(transformed_data))
}, error = function(e) {
  message("Warning: Could not save to SQLite: ", e$message)
})

# ---- verify-save ------
if (file.exists(OUTPUT_CSV) && file.exists(OUTPUT_RDS)) {
  message("\n✅ Ellis-6 completed successfully!")
  message("- CSV: ", OUTPUT_CSV)
  message("- RDS: ", OUTPUT_RDS)
  message("- Records: ", nrow(transformed_data))
  message("- Columns: ", paste(names(transformed_data), collapse = ", "))
} else {
  message("❌ Error: Files were not saved correctly")
  quit(status = 1)
}
