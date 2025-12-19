#' ---
#' title: "Ellis-1: Edmonton Property Assessment Data"
#' subtitle: "Fetch property assessment data from Edmonton Open Data"
#' author: "RG-FIDES Research Team"
#' date: "last Updated: `r Sys.Date()`"
#' ---

#+ echo=FALSE
# Rscript manipulation/ellis-1-open-data.R  # run from project root

# ---- environment-setup ------
library(tidyverse)
library(httr)
library(jsonlite)
library(DBI)
library(RSQLite)

# ---- declare-globals -------
# Edmonton Open Data SODA2 endpoint for Property Assessment
API_BASE_URL <- "https://data.edmonton.ca/resource/q7d6-ambg.csv"
OUTPUT_DIR <- "data-private/derived/ellis-1-open-data"
OUTPUT_CSV <- file.path(OUTPUT_DIR, "ellis-1-open-data.csv")
OUTPUT_RDS <- file.path(OUTPUT_DIR, "ellis-1-open-data.rds")

# Limit records for development (remove for production)
RECORD_LIMIT <- 1000

# ---- declare-functions ------

fetch_property_assessment_data <- function(limit = RECORD_LIMIT) {
  #' Fetch property assessment data from Edmonton Open Data
  #'
  #' @param limit Maximum number of records to fetch
  #' @return DataFrame with property assessment data

  message("Fetching Edmonton property assessment data...")

  # Build API URL with limit
  api_url <- paste0(API_BASE_URL, "?$limit=", limit)

  message("API URL: ", api_url)

  tryCatch({
    # Fetch data
    response <- GET(api_url)

    if (status_code(response) != 200) {
      stop("API request failed with status: ", status_code(response))
    }

    # Read CSV data
    data <- read_csv(content(response, "text"), show_col_types = FALSE)

    message("Successfully fetched ", nrow(data), " property records")

    return(data)

  }, error = function(e) {
    message("Error fetching data: ", e$message)
    return(NULL)
  })
}

# ---- load-data ------
# Create output directory if it doesn't exist
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Fetch the data
property_data <- fetch_property_assessment_data()

if (is.null(property_data)) {
  message("Failed to fetch property assessment data")
  quit(status = 1)
}

# ---- verify-values ------
message("Data summary:")
message("- Records: ", nrow(property_data))
message("- Columns: ", ncol(property_data))

# ---- save-to-disk ------
message("Saving data to: ", OUTPUT_DIR)

# Save as CSV
write_csv(property_data, OUTPUT_CSV)
message("Saved CSV: ", OUTPUT_CSV)

# Save as RDS for R users
saveRDS(property_data, OUTPUT_RDS)
message("Saved RDS: ", OUTPUT_RDS)

# Save to global SQLite database
DB_PATH <- "data-private/derived/global-data.sqlite"
DB_DIR <- dirname(DB_PATH)
dir.create(DB_DIR, recursive = TRUE, showWarnings = FALSE)

tryCatch({
  conn <- dbConnect(RSQLite::SQLite(), DB_PATH)
  dbWriteTable(conn, "ellis_1_property_assessment", property_data, overwrite = TRUE)
  dbDisconnect(conn)
  
  message("Saved to SQLite: ", DB_PATH)
  message("  Table: ellis_1_property_assessment")
  message("  Records: ", nrow(property_data))
}, error = function(e) {
  message("Warning: Could not save to SQLite: ", e$message)
})

# ---- verify-save ------
if (file.exists(OUTPUT_CSV) && file.exists(OUTPUT_RDS)) {
  message("✅ Ellis-1 completed successfully!")
  message("- CSV: ", OUTPUT_CSV)
  message("- RDS: ", OUTPUT_RDS)
  message("- Records: ", nrow(property_data))
} else {
  message("❌ Error: Files were not saved correctly")
  quit(status = 1)
}