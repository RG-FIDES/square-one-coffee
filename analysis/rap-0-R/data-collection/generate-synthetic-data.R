#' ---
#' title: "Generate Synthetic Edmonton Cafe Data (R Version)"
#' author: "Research Team"
#' date: "Last Updated: `r Sys.Date()`"
#' ---

#' Generate synthetic Edmonton cafe data for RAP-0-R testing
#' 
#' This script creates a realistic SQLite database with synthetic cafe data
#' for Square One Coffee's competition analysis pipeline.
#' 
#' Data includes:
#' - Cafe names, locations, and contact info
#' - Operating hours and menu offerings
#' - Pricing data and cafe characteristics
#' - Geographic coordinates (Edmonton area)

# ---- load-packages -----------------------------------------------------------
library(DBI)
library(RSQLite)
library(dplyr)
library(tidyr)
library(stringr)

# ---- declare-globals ---------------------------------------------------------
# Ensure data-private/raw directory exists
output_dir <- "../../../data-private/raw"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Database path
db_path <- file.path(output_dir, "edmonton_cafes.sqlite")

# Remove existing database if it exists
if (file.exists(db_path)) {
  file.remove(db_path)
  message("Removed existing database")
}

# Edmonton neighborhoods
neighborhoods <- c(
  "Downtown", "Oliver", "Garneau", "Whyte Avenue", "Bonnie Doon",
  "Westmount", "Old Strathcona", "Ritchie", "Highlands", "Jasper Avenue",
  "Alberta Avenue", "124 Street", "Capilano", "Belgravia", "Riverdale"
)

# Edmonton lat/long boundaries (approximate)
lat_bounds <- c(min = 53.45, max = 53.62)
lng_bounds <- c(min = -113.65, max = -113.40)

# ---- generate-data -----------------------------------------------------------
cat("\n## Generating Synthetic Data\n\n")

# Square One Coffee locations
soc_locations <- paste0("Square One Coffee - ", 
                       c("Oliver", "Downtown", "Whyte Avenue", 
                         "Westmount", "124 Street", "Ritchie"))

# Generate competitor names
set.seed(42)  # For reproducibility
prefixes <- c("The", "Cafe", "Coffee", "Brew", "Bean", "Roast", "Morning", "Daily")
middles <- c("Central", "House", "Bar", "Shop", "Co", "Collective", "Studio", "Lab")
suffixes <- c("Cafe", "Coffee", "Roasters", "Co.", "House", "Bar", "Kitchen")

competitor_cafes <- character(24)
for (i in 1:24) {
  if (runif(1) < 0.3) {
    competitor_cafes[i] <- paste(sample(prefixes, 1), sample(middles, 1))
  } else {
    competitor_cafes[i] <- paste(sample(prefixes, 1), sample(middles, 1), sample(suffixes, 1))
  }
}

all_cafes <- c(soc_locations, competitor_cafes)

# Cafe characteristics
cafe_types <- c("specialty_coffee", "espresso_bar", "full_service_cafe", "coffee_shop", "roastery_cafe")
ownerships <- c("independent", "small_chain", "regional_chain", "national_chain")
ambiances <- c("modern_minimalist", "cozy_traditional", "industrial_chic", "community_hub", "grab_and_go")
parking_options <- c("street_only", "nearby_lot", "dedicated_parking", "no_parking")
food_offerings <- c("pastries_only", "sandwiches_pastries", "full_menu", "none")

# ---- create-cafe-data --------------------------------------------------------
cat("Creating cafe records...\n")

cafes_data <- tibble(
  name = all_cafes
) %>%
  mutate(
    is_soc = str_detect(name, regex("square one", ignore_case = TRUE)),
    
    # SOC cafes have consistent characteristics
    cafe_type = if_else(is_soc, "specialty_coffee", sample(cafe_types, n(), replace = TRUE)),
    ownership = if_else(is_soc, "independent", sample(ownerships, n(), replace = TRUE)),
    avg_beverage_price = if_else(is_soc, 
                                  runif(n(), 4.50, 6.00),
                                  runif(n(), 3.00, 7.50)),
    has_food = if_else(is_soc, 
                      "sandwiches_pastries",
                      sample(food_offerings, n(), replace = TRUE)),
    has_wifi = if_else(is_soc, "yes", sample(c("yes", "no", "limited"), n(), replace = TRUE)),
    seating_capacity = if_else(is_soc, 
                               as.integer(runif(n(), 20, 45)),
                               as.integer(runif(n(), 10, 60))),
    ambiance = if_else(is_soc, "modern_minimalist", sample(ambiances, n(), replace = TRUE)),
    google_rating = if_else(is_soc, 
                           runif(n(), 4.3, 4.8),
                           runif(n(), 3.5, 4.9)),
    review_count = if_else(is_soc, 
                          as.integer(runif(n(), 150, 500)),
                          as.integer(runif(n(), 20, 400))),
    
    # Assign neighborhood
    neighborhood = neighborhoods[(row_number() - 1) %% length(neighborhoods) + 1],
    
    # Generate coordinates
    latitude = runif(n(), lat_bounds["min"], lat_bounds["max"]),
    longitude = runif(n(), lng_bounds["min"], lng_bounds["max"]),
    
    # Generate address
    street_num = sample(100:9999, n()),
    street_name = sample(c("Jasper Ave", "Whyte Ave", "124 St", "104 St", "82 Ave", 
                          "Gateway Blvd", "Calgary Trail"), n(), replace = TRUE),
    address = paste0(street_num, " ", street_name, ", Edmonton, AB"),
    
    # Contact info
    phone = sprintf("780-%03d-%04d", sample(100:999, n()), sample(1000:9999, n())),
    website = if_else(runif(n()) > 0.3, 
                     paste0("https://", str_replace_all(tolower(substr(name, 1, 20)), " ", ""), ".com"),
                     NA_character_),
    
    # Hours
    hours_weekday = if_else(runif(n()) > 0.3, "7:00 AM - 6:00 PM", "6:30 AM - 7:00 PM"),
    hours_weekend = if_else(runif(n()) > 0.3, "8:00 AM - 5:00 PM", "8:00 AM - 6:00 PM"),
    
    # Opening date
    date_opened = as.character(as.Date(sprintf("%d-%02d-01", 
                                              sample(2010:2024, n(), replace = TRUE),
                                              sample(1:12, n(), replace = TRUE)))),
    
    # Instagram
    instagram_handle = if_else(runif(n()) > 0.2,
                              paste0("@", str_replace_all(tolower(substr(name, 1, 20)), " ", "")),
                              NA_character_),
    
    # Parking
    parking_availability = sample(parking_options, n(), replace = TRUE),
    
    # Timestamps
    created_at = as.character(Sys.time()),
    updated_at = as.character(Sys.time())
  ) %>%
  select(-is_soc, -street_num, -street_name) %>%
  # Round numeric columns
  mutate(
    avg_beverage_price = round(avg_beverage_price, 2),
    google_rating = round(google_rating, 1),
    latitude = round(latitude, 6),
    longitude = round(longitude, 6)
  )

cat(sprintf("✓ Generated %d cafe records\n", nrow(cafes_data)))

# ---- write-to-database -------------------------------------------------------
cat("\n## Writing to Database\n\n")

# Connect to database
conn <- dbConnect(RSQLite::SQLite(), db_path)

# Write table
dbWriteTable(conn, "cafes", cafes_data, overwrite = TRUE)

# Verify
total_cafes <- dbGetQuery(conn, "SELECT COUNT(*) as count FROM cafes")$count
soc_cafes <- dbGetQuery(conn, "SELECT COUNT(*) as count FROM cafes WHERE name LIKE '%Square One%'")$count

cat("\n✅ Synthetic data generated successfully!\n")
cat(sprintf("   Database: %s\n", db_path))
cat(sprintf("   Total cafes: %d\n", total_cafes))
cat(sprintf("   - Square One Coffee locations: %d\n", soc_cafes))
cat(sprintf("   - Competitor cafes: %d\n", total_cafes - soc_cafes))
cat(sprintf("   Neighborhoods covered: %d\n", length(neighborhoods)))

# Close connection
dbDisconnect(conn)

cat("\n✓ Database created and verified\n")
