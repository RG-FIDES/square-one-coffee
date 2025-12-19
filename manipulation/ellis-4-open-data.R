#' ---
#' title: "Ellis-4: Edmonton Open Data"
#' subtitle: "Fetch data from Edmonton Open Data API"
#' author: "RG-FIDES Research Team"
#' date: "last Updated: `r Sys.Date()`"
#' ---

#+ echo=FALSE
# Rscript manipulation/ellis-4-open-data.R  # run from project root

# ---- environment-setup ------
library(tidyverse)
library(httr)
library(jsonlite)
library(DBI)
library(RSQLite)

# ---- declare-globals -------
# Edmonton Open Data SODA2 endpoint
API_BASE_URL <- "https://data.edmonton.ca/resource/5bk4-5txu.csv"
OUTPUT_DIR <- "data-private/derived/ellis-4-open-data"
OUTPUT_CSV <- file.path(OUTPUT_DIR, "ellis-4-open-data.csv")
OUTPUT_RDS <- file.path(OUTPUT_DIR, "ellis-4-open-data.rds")

# Limit records for development (remove for production)
RECORD_LIMIT <- 1000

# ---- declare-functions ------

fetch_open_data <- function(limit = RECORD_LIMIT) {
  #' Fetch data from Edmonton Open Data API
  #'
  #' @param limit Maximum number of records to fetch
  #' @return DataFrame with open data

  message("Fetching Edmonton open data...")

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

    message("Successfully fetched ", nrow(data), " records")

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
open_data <- fetch_open_data()

if (is.null(open_data)) {
  message("Failed to fetch open data")
  quit(status = 1)
}

# ---- verify-values ------
message("Data summary:")
message("- Records: ", nrow(open_data))
message("- Columns: ", ncol(open_data))

# ---- save-to-disk ------
message("Saving data to: ", OUTPUT_DIR)

# Save as CSV
write_csv(open_data, OUTPUT_CSV)
message("Saved CSV: ", OUTPUT_CSV)

# Save as RDS for R users
saveRDS(open_data, OUTPUT_RDS)
message("Saved RDS: ", OUTPUT_RDS)

# Save to global SQLite database
DB_PATH <- "data-private/derived/global-data.sqlite"
DB_DIR <- dirname(DB_PATH)
dir.create(DB_DIR, recursive = TRUE, showWarnings = FALSE)

tryCatch({
  conn <- dbConnect(RSQLite::SQLite(), DB_PATH)
  dbWriteTable(conn, "ellis_4_open_data", open_data, overwrite = TRUE)
  dbDisconnect(conn)
  
  message("Saved to SQLite: ", DB_PATH)
  message("  Table: ellis_4_open_data")
  message("  Records: ", nrow(open_data))
}, error = function(e) {
  message("Warning: Could not save to SQLite: ", e$message)
})

# ---- verify-save ------
if (file.exists(OUTPUT_CSV) && file.exists(OUTPUT_RDS)) {
  message("✅ Ellis-4 completed successfully!")
  message("- CSV: ", OUTPUT_CSV)
  message("- RDS: ", OUTPUT_RDS)
  message("- Records: ", nrow(open_data))
} else {
  message("❌ Error: Files were not saved correctly")
  quit(status = 1)
}
