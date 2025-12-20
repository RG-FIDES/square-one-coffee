# Data Provisioning Script for Neighborhood Metrics
# This script prepares all metrics available for choropleth mapping
# Add new metrics here as they become available

library(DBI)
library(RSQLite)
library(dplyr)
library(sf)

provision_neighborhood_metrics <- function(db_path) {
  #' Load and prepare neighborhood metrics for choropleth visualization
  #' 
  #' @param db_path Path to SQLite database
  #' @return sf object with neighborhood geometries and all available metrics
  
  con <- dbConnect(SQLite(), db_path)
  
  # Load neighborhood boundaries (geometries)
  neighborhoods_raw <- dbReadTable(con, "ellis_4_open_data")
  
  # Load population data
  population_data <- dbReadTable(con, "ellis_5_open_data") %>%
    select(neighbourhood, total_population, ward)
  
  # Could add more metrics here in future, e.g.:
  # cafe_counts <- dbGetQuery(con, "SELECT neighborhood, COUNT(*) as cafe_count ...")
  # restaurant_counts <- ...
  
  dbDisconnect(con)
  
  # Convert to sf object
  neighborhoods_sf <- st_as_sf(
    neighborhoods_raw, 
    wkt = "the_geom", 
    crs = 4326
  )
  
  # Normalize names for joining (case-insensitive)
  neighborhoods_sf <- neighborhoods_sf %>%
    mutate(name_normalized = toupper(name))
  
  population_data <- population_data %>%
    mutate(name_normalized = toupper(neighbourhood))
  
  # Join population data to neighborhoods using normalized names
  neighborhoods_sf <- neighborhoods_sf %>%
    left_join(population_data, by = "name_normalized") %>%
    select(-name_normalized)  # Remove the temporary join column
  
  # Calculate area in square kilometers
  neighborhoods_sf <- neighborhoods_sf %>%
    mutate(
      area_km2 = as.numeric(st_area(.)) / 1e6,  # Convert m² to km²
      population_density = ifelse(
        area_km2 > 0 & !is.na(total_population),
        total_population / area_km2,
        NA
      )
    )
  
  return(neighborhoods_sf)
}

provision_cafe_data <- function(db_path) {
  #' Load and categorize all cafes from ellis_0_cafes
  #' 
  #' @param db_path Path to SQLite database
  #' @return Data frame with cafes and their primary category
  
  con <- dbConnect(SQLite(), db_path)
  cafes <- dbReadTable(con, "ellis_0_cafes")
  dbDisconnect(con)
  
  # Parse types field and assign primary category
  cafes <- cafes %>%
    mutate(
      types_list = strsplit(types, ","),
      primary_category = sapply(types_list, function(type_vec) {
        types <- trimws(type_vec)
        if ("cafe" %in% types) return("Specialty Coffee")
        if ("bakery" %in% types) return("Bakery")
        if ("restaurant" %in% types) return("Restaurant")
        if ("bar" %in% types) return("Bar")
        if ("convenience_store" %in% types || "gas_station" %in% types) return("Convenience")
        if ("grocery_or_supermarket" %in% types || "supermarket" %in% types) return("Grocery")
        return("Other Food")
      })
    ) %>%
    select(-types_list)  # Remove temporary column
  
  return(cafes)
}

get_cafe_categories <- function() {
  #' Get available cafe category filters
  #' 
  #' @return Character vector of cafe categories
  
  c("None",
    "All Cafes",
    "Specialty Coffee",
    "Bakery",
    "Restaurant",
    "Bar",
    "Convenience",
    "Grocery",
    "Other Food")
}

get_metric_definitions <- function() {
  #' Define available metrics for choropleth visualization
  #' Add new metrics here as they become available
  #' 
  #' @return List of metric definitions with labels, columns, and color schemes
  
  metrics <- list(
    list(
      id = "none",
      label = "None (Gray)",
      column = NULL,
      palette = "Greys",
      reverse = FALSE
    ),
    list(
      id = "population",
      label = "Total Population",
      column = "total_population",
      palette = "YlOrRd",
      reverse = FALSE
    ),
    list(
      id = "density",
      label = "Population Density (per km²)",
      column = "population_density",
      palette = "YlGnBu",
      reverse = FALSE
    )
    # Future metrics to add:
    # list(
    #   id = "cafe_count",
    #   label = "Number of Cafes",
    #   column = "cafe_count",
    #   palette = "PuRd",
    #   reverse = FALSE
    # ),
    # list(
    #   id = "restaurant_count",
    #   label = "Number of Restaurants",
    #   column = "restaurant_count",
    #   palette = "BuPu",
    #   reverse = FALSE
    # )
  )
  
  return(metrics)
}

get_color_palette <- function(values, palette_name = "YlOrRd", reverse = FALSE) {
  #' Generate color palette for choropleth mapping
  #' 
  #' @param values Numeric vector of values to map
  #' @param palette_name RColorBrewer palette name
  #' @param reverse Whether to reverse the palette
  #' @return colorNumeric function for leaflet
  
  library(leaflet)
  
  # Remove NAs for palette generation
  valid_values <- values[!is.na(values)]
  
  if (length(valid_values) == 0) {
    return(colorNumeric("Greys", domain = 0:1))
  }
  
  pal <- colorNumeric(
    palette = palette_name,
    domain = valid_values,
    reverse = reverse,
    na.color = "#cccccc"
  )
  
  return(pal)
}
