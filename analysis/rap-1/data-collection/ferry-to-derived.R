#' ---
#' title: "RAP-1 Ferry: Raw to Derived Transformation"
#' author: "Research Team"
#' date: "Last Updated: `r Sys.Date()`"
#' ---
#+ echo=F
# AI agents: This follows the Ellis-pattern for data transformation
# See: ./manipulation/ellis-lane.R and ./data-documentation/ferry-process.md

#+ echo=F ----------------------------------------------------------------------
# Clear environment for clean run
if(exists("clear_memory")){
  if(clear_memory){
    rm(list = ls(all.names = TRUE))
  }
}

#+ results="hide",echo=F -------------------------------------------------------
cat("\014") # Clear the console

#+ echo=FALSE, results="asis" --------------------------------------------------
cat("Ferry working directory: `", getwd(),"`")

#+ echo=F, results="asis" ------------------------------------------------------
cat("\n# 1. Environment Setup")

#+ load-packages ---------------------------------------------------------------
# Core packages for data transformation
library(DBI)       # Database interface
library(RSQLite)   # SQLite connector
library(dplyr)     # Data wrangling
library(tidyr)     # Data tidying
library(stringr)   # String manipulation
library(magrittr)  # Pipe operator

#+ declare-globals -------------------------------------------------------------
cat("\n## Ferry Configuration\n")

# Input/Output paths
input_db_path <- "./data-private/raw/edmonton_cafes.sqlite"
output_db_path <- "./data-private/derived/rap-1-competition-intel.sqlite"

# Ensure output directory exists
output_dir <- dirname(output_db_path)
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat("✓ Created output directory:", output_dir, "\n")
}

# Edmonton geographic boundaries (for validation)
edmonton_bounds <- list(
  lat_min = 53.40,
  lat_max = 53.70,
  lng_min = -113.70,
  lng_max = -113.30
)

# Downtown reference point (for distance calculations)
downtown_ref <- list(
  lat = 53.5444,
  lng = -113.4909
)

# Price range validation
price_range <- list(
  min = 2.00,
  max = 10.00
)

cat("✓ Configuration loaded\n")
cat("  Input:", input_db_path, "\n")
cat("  Output:", output_db_path, "\n")

#+ echo=F, results="asis" ------------------------------------------------------
cat("\n# 2. Data Import")

#+ load-data -------------------------------------------------------------------
cat("\n## Reading raw data\n")

# Connect to raw database
con_raw <- DBI::dbConnect(RSQLite::SQLite(), input_db_path)

# List available tables
tables <- DBI::dbListTables(con_raw)
cat("Available tables:", paste(tables, collapse = ", "), "\n")

# Read cafes table
ds_raw <- DBI::dbReadTable(con_raw, "cafes")

# Close raw connection (we've loaded what we need)
DBI::dbDisconnect(con_raw)

cat("✓ Raw data loaded:", nrow(ds_raw), "records\n")

#+ inspect-data ----------------------------------------------------------------
cat("\n## Raw data structure\n")
cat("Dimensions:", nrow(ds_raw), "rows ×", ncol(ds_raw), "columns\n")
cat("Columns:", paste(colnames(ds_raw), collapse = ", "), "\n")

#+ echo=F, results="asis" ------------------------------------------------------
cat("\n# 3. Data Validation")

#+ validation-required-fields --------------------------------------------------
cat("\n## Validating required fields\n")

required_fields <- c("cafe_id", "name", "neighborhood", "cafe_type")

# Check for missing required fields
validation_errors <- ds_raw %>%
  filter(if_any(all_of(required_fields), is.na)) %>%
  select(cafe_id, name, all_of(required_fields))

if(nrow(validation_errors) > 0) {
  cat("❌ ERROR: Required fields contain NULL values\n")
  print(validation_errors)
  stop("VALIDATION FAILED: Required fields must not be NULL")
} else {
  cat("✓ All required fields present\n")
}

#+ validation-uniqueness ------------------------------------------------------
cat("\n## Validating uniqueness\n")

# Check for duplicate cafe_ids
duplicates <- ds_raw %>%
  group_by(cafe_id) %>%
  filter(n() > 1) %>%
  ungroup()

if(nrow(duplicates) > 0) {
  cat("❌ ERROR: Duplicate cafe_ids detected\n")
  print(duplicates)
  stop("VALIDATION FAILED: cafe_id must be unique")
} else {
  cat("✓ No duplicate cafe_ids\n")
}

#+ validation-geography -------------------------------------------------------
cat("\n## Validating geographic coordinates\n")

geo_validation <- ds_raw %>%
  filter(!is.na(latitude) & !is.na(longitude)) %>%
  mutate(
    lat_out_of_bounds = latitude < edmonton_bounds$lat_min | latitude > edmonton_bounds$lat_max,
    lng_out_of_bounds = longitude < edmonton_bounds$lng_min | longitude > edmonton_bounds$lng_max,
    location_issue = lat_out_of_bounds | lng_out_of_bounds
  )

location_warnings <- geo_validation %>% filter(location_issue)

if(nrow(location_warnings) > 0) {
  cat("⚠️  WARNING:", nrow(location_warnings), "cafes have coordinates outside expected Edmonton bounds\n")
  cat("   This may indicate data errors or suburban locations\n")
} else {
  cat("✓ All coordinates within expected bounds\n")
}

#+ validation-pricing ---------------------------------------------------------
cat("\n## Validating pricing data\n")

price_validation <- ds_raw %>%
  filter(!is.na(avg_beverage_price)) %>%
  mutate(
    price_too_low = avg_beverage_price < price_range$min,
    price_too_high = avg_beverage_price > price_range$max,
    price_suspicious = price_too_low | price_too_high
  )

price_warnings <- price_validation %>% filter(price_suspicious)

if(nrow(price_warnings) > 0) {
  cat("⚠️  WARNING:", nrow(price_warnings), "cafes have prices outside typical range ($", 
      price_range$min, "-$", price_range$max, ")\n", sep = "")
} else {
  cat("✓ All prices within expected range\n")
}

#+ validation-ratings ---------------------------------------------------------
cat("\n## Validating ratings data\n")

rating_validation <- ds_raw %>%
  filter(!is.na(google_rating)) %>%
  mutate(
    invalid_rating = google_rating < 1.0 | google_rating > 5.0
  )

rating_warnings <- rating_validation %>% filter(invalid_rating)

if(nrow(rating_warnings) > 0) {
  cat("⚠️  WARNING:", nrow(rating_warnings), "cafes have invalid ratings (will be set to NA)\n")
} else {
  cat("✓ All ratings valid (1-5 scale)\n")
}

#+ echo=F, results="asis" ------------------------------------------------------
cat("\n# 4. Data Transformation")

#+ tweak-data-standardization -------------------------------------------------
cat("\n## Standardizing categorical fields\n")

ds <- ds_raw %>%
  mutate(
    # Standardize neighborhood names
    neighborhood = str_to_title(str_trim(neighborhood)),
    
    # Standardize cafe types to lowercase
    cafe_type = tolower(str_trim(cafe_type)),
    
    # Standardize ownership categories
    ownership = tolower(str_trim(ownership)),
    
    # Fix invalid ratings
    google_rating = ifelse(google_rating < 1.0 | google_rating > 5.0, NA, google_rating),
    
    # Ensure review_count is non-negative
    review_count = ifelse(review_count < 0, NA, review_count)
  )

cat("✓ Categorical fields standardized\n")

#+ tweak-data-enrichment ------------------------------------------------------
cat("\n## Adding derived fields\n")

ds <- ds %>%
  mutate(
    # SOC identification flag
    is_soc = str_detect(name, regex("square one", ignore_case = TRUE)),
    
    # Price category
    price_category = case_when(
      is.na(avg_beverage_price) ~ NA_character_,
      avg_beverage_price < 3.50 ~ "budget",
      avg_beverage_price < 5.00 ~ "moderate",
      avg_beverage_price < 6.50 ~ "premium",
      TRUE ~ "luxury"
    ),
    
    # Popularity percentile (based on review count)
    popularity_percentile = ifelse(!is.na(review_count), 
                                   percent_rank(review_count), 
                                   NA_real_),
    
    # Quality score (rating × log(review_count + 1))
    quality_score = ifelse(!is.na(google_rating) & !is.na(review_count),
                          google_rating * log(review_count + 1),
                          NA_real_),
    
    # Distance from downtown
    distance_from_downtown = ifelse(!is.na(latitude) & !is.na(longitude),
                                   sqrt((latitude - downtown_ref$lat)^2 + 
                                        (longitude - downtown_ref$lng)^2) * 111,  # Convert to km
                                   NA_real_),
    
    # Location zone
    location_zone = case_when(
      is.na(distance_from_downtown) ~ NA_character_,
      distance_from_downtown < 2 ~ "core",
      distance_from_downtown < 5 ~ "inner",
      distance_from_downtown < 10 ~ "outer",
      TRUE ~ "peripheral"
    )
  )

cat("✓ Derived fields added:\n")
cat("  - is_soc: SOC location identifier\n")
cat("  - price_category: budget/moderate/premium/luxury\n")
cat("  - popularity_percentile: review count ranking\n")
cat("  - quality_score: rating × log(reviews + 1)\n")
cat("  - distance_from_downtown: km from downtown core\n")
cat("  - location_zone: core/inner/outer/peripheral\n")

#+ tweak-data-quality-flags ---------------------------------------------------
cat("\n## Adding quality flags\n")

ds <- ds %>%
  mutate(
    flag_missing_location = is.na(latitude) | is.na(longitude),
    flag_no_rating = is.na(google_rating),
    flag_no_price = is.na(avg_beverage_price),
    flag_location_out_of_bounds = !is.na(latitude) & !is.na(longitude) &
      (latitude < edmonton_bounds$lat_min | latitude > edmonton_bounds$lat_max |
       longitude < edmonton_bounds$lng_min | longitude > edmonton_bounds$lng_max),
    flag_suspicious_price = !is.na(avg_beverage_price) &
      (avg_beverage_price < price_range$min | avg_beverage_price > price_range$max)
  ) %>%
  mutate(
    # Count quality issues per record
    quality_flag_count = flag_missing_location + flag_no_rating + flag_no_price +
      flag_location_out_of_bounds + flag_suspicious_price,
    
    # Overall quality tier
    quality_tier = case_when(
      quality_flag_count == 0 ~ "excellent",
      quality_flag_count <= 1 ~ "good",
      quality_flag_count <= 2 ~ "acceptable",
      TRUE ~ "poor"
    )
  )

cat("✓ Quality flags added\n")

#+ echo=F, results="asis" ------------------------------------------------------
cat("\n# 5. Create Analysis Tables")

#+ create-tables ---------------------------------------------------------------
cat("\n## Creating derived tables\n")

# Main table: All cafes with complete enrichment
cafes_complete <- ds

# SOC locations only
soc_locations <- ds %>%
  filter(is_soc == TRUE) %>%
  select(-is_soc)  # Remove flag since it's implicit

# Competitors only
competitors <- ds %>%
  filter(is_soc == FALSE) %>%
  select(-is_soc)

cat("✓ Tables created:\n")
cat("  - cafes_complete:", nrow(cafes_complete), "records\n")
cat("  - soc_locations:", nrow(soc_locations), "records\n")
cat("  - competitors:", nrow(competitors), "records\n")

#+ create-quality-metrics -----------------------------------------------------
cat("\n## Calculating quality metrics\n")

# Completeness by field
completeness_metrics <- data.frame(
  field = colnames(ds_raw),
  total_records = nrow(ds_raw),
  complete_count = sapply(ds_raw, function(x) sum(!is.na(x))),
  missing_count = sapply(ds_raw, function(x) sum(is.na(x))),
  complete_rate = sapply(ds_raw, function(x) sum(!is.na(x)) / length(x))
) %>%
  arrange(complete_rate)

# Quality tier distribution
quality_distribution <- ds %>%
  count(quality_tier) %>%
  mutate(percentage = round(n / sum(n) * 100, 1))

# Overall summary
quality_summary <- data.frame(
  metric = c(
    "total_records",
    "records_with_location",
    "records_with_rating",
    "records_with_price",
    "avg_completeness",
    "excellent_quality",
    "good_quality",
    "acceptable_quality",
    "poor_quality"
  ),
  value = c(
    nrow(ds),
    sum(!ds$flag_missing_location),
    sum(!ds$flag_no_rating),
    sum(!ds$flag_no_price),
    round(mean(completeness_metrics$complete_rate) * 100, 1),
    sum(ds$quality_tier == "excellent"),
    sum(ds$quality_tier == "good"),
    sum(ds$quality_tier == "acceptable"),
    sum(ds$quality_tier == "poor")
  )
)

cat("✓ Quality metrics calculated\n")

#+ create-metadata ------------------------------------------------------------
cat("\n## Creating metadata record\n")

ferry_metadata <- data.frame(
  ferry_date = as.character(Sys.time()),
  r_version = paste(R.version$major, R.version$minor, sep = "."),
  platform = R.version$platform,
  input_file = input_db_path,
  input_records = nrow(ds_raw),
  output_file = output_db_path,
  output_records = nrow(ds),
  validation_errors = 0,  # Would have stopped if errors
  validation_warnings = nrow(location_warnings) + nrow(price_warnings) + nrow(rating_warnings),
  avg_completeness = round(mean(completeness_metrics$complete_rate) * 100, 1)
)

cat("✓ Metadata created\n")

#+ echo=F, results="asis" ------------------------------------------------------
cat("\n# 6. Write to Derived Database")

#+ save-to-disk ---------------------------------------------------------------
cat("\n## Writing tables to derived database\n")

# Connect to derived database (will create if doesn't exist)
con_derived <- DBI::dbConnect(RSQLite::SQLite(), output_db_path)

# Write all tables
DBI::dbWriteTable(con_derived, "cafes_complete", cafes_complete, overwrite = TRUE)
DBI::dbWriteTable(con_derived, "soc_locations", soc_locations, overwrite = TRUE)
DBI::dbWriteTable(con_derived, "competitors", competitors, overwrite = TRUE)
DBI::dbWriteTable(con_derived, "completeness_metrics", completeness_metrics, overwrite = TRUE)
DBI::dbWriteTable(con_derived, "quality_summary", quality_summary, overwrite = TRUE)
DBI::dbWriteTable(con_derived, "metadata", ferry_metadata, overwrite = TRUE)

# Close connection
DBI::dbDisconnect(con_derived)

cat("✓ All tables written to:", output_db_path, "\n")
cat("  Tables: cafes_complete, soc_locations, competitors, completeness_metrics, quality_summary, metadata\n")

#+ echo=F, results="asis" ------------------------------------------------------
cat("\n# 7. Ferry Summary Report")

#+ summary-report -------------------------------------------------------------
cat("\n## Validation & Transformation Summary\n")
cat("\n")
cat("===== FERRY VALIDATION REPORT =====\n")
cat("Input records:", nrow(ds_raw), "\n")
cat("Output records:", nrow(ds), "\n")
cat("Records dropped:", nrow(ds_raw) - nrow(ds), "\n")
cat("\n")
cat("ERROR-level issues: 0\n")
cat("  (Ferry would have stopped if errors occurred)\n")
cat("\n")
cat("WARNING-level issues:", nrow(location_warnings) + nrow(price_warnings) + nrow(rating_warnings), "\n")
if(nrow(location_warnings) > 0) cat("  - Out-of-bounds coordinates:", nrow(location_warnings), "records\n")
if(nrow(price_warnings) > 0) cat("  - Suspicious pricing:", nrow(price_warnings), "records\n")
if(nrow(rating_warnings) > 0) cat("  - Invalid ratings:", nrow(rating_warnings), "records\n")
cat("\n")
cat("INFO messages:\n")
cat("  - Average completeness:", round(mean(completeness_metrics$complete_rate) * 100, 1), "%\n")
low_complete <- completeness_metrics %>% filter(complete_rate < 0.75)
if(nrow(low_complete) > 0) {
  cat("  - Low completeness fields:", paste(low_complete$field, collapse = ", "), "\n")
}
cat("\n")
cat("Quality tier distribution:\n")
for(i in 1:nrow(quality_distribution)) {
  cat("  -", quality_distribution$quality_tier[i], ":", quality_distribution$n[i], 
      "(", quality_distribution$percentage[i], "%)\n", sep = "")
}
cat("\n")
cat("Square One Coffee:\n")
cat("  - Locations:", nrow(soc_locations), "\n")
cat("  - Avg quality score:", round(mean(soc_locations$quality_score, na.rm = TRUE), 2), "\n")
cat("\n")
cat("Competitors:\n")
cat("  - Count:", nrow(competitors), "\n")
cat("  - Avg quality score:", round(mean(competitors$quality_score, na.rm = TRUE), 2), "\n")
cat("\n")
cat("===================================\n")

#+ echo=F, results="asis" ------------------------------------------------------
cat("\n# A. Session Information")

#+ results="show", echo=F ------------------------------------------------------
cat("\n## Reproducibility Information\n")
cat("For documentation and reproducibility, this ferry was executed in the following environment:\n\n")

if(requireNamespace("devtools", quietly = TRUE)) {
  devtools::session_info()
} else {
  sessionInfo()
}

cat("\n✅ Ferry completed successfully at", as.character(Sys.time()), "\n")
