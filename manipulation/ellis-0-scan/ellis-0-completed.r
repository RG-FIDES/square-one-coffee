#' ---
#' title: "Ellis-0: Completed Cafe List (Google Sheets Import)"
#' subtitle: "Load manually completed cafe data from Google Sheets"
#' author: "RG-FIDES Research Team"
#' date: "last Updated: `r Sys.Date()`"
#' ---

#+ echo=FALSE
# Rscript manipulation/ellis-0-scan/ellis-0-completed.R  # run from project root

# ---- environment-setup ------
library(tidyverse)
library(googlesheets4)
library(DBI)
library(RSQLite)

# Google Sheets Authentication Setup
# OAuth token will be cached in .secrets/google_oauth/ after first interactive run
# Email is read from manipulation/ellis-0-scan/.Renv (GSHEET_AUTH_EMAIL)

# Read email from .Renv
renv_path <- file.path("manipulation", "ellis-0-scan", ".Renv")
gsheet_auth_email <- NULL
if (file.exists(renv_path)) {
  renv_lines <- readLines(renv_path, warn = FALSE)
  auth_line <- grep("^\\s*GSHEET_AUTH_EMAIL\\s*=", renv_lines, value = TRUE)
  if (length(auth_line) > 0) {
    gsheet_auth_email <- sub("^.*=", "", auth_line[1]) %>% trimws()
    if (identical(gsheet_auth_email, "")) gsheet_auth_email <- NULL
  }
}

# Set cache directory for OAuth tokens
gargle_cache_dir <- file.path(".secrets", "google_oauth")
dir.create(gargle_cache_dir, recursive = TRUE, showWarnings = FALSE)
options(gargle_oauth_cache = gargle_cache_dir)

# Authenticate with Google Sheets
# First run: will open browser for OAuth consent, then cache token
# Subsequent runs: will use cached token automatically
message("Authenticating with Google Sheets...")
message("Cache directory: ", gargle_cache_dir)
if (!is.null(gsheet_auth_email)) {
  message("Using email from .Renv: ", gsheet_auth_email)
  gs4_auth(cache = gargle_cache_dir, email = gsheet_auth_email)
} else {
  message("No email in .Renv - will prompt for account selection")
  gs4_auth(cache = gargle_cache_dir)
}

# ---- declare-globals -------
# Google Sheets URL and sheet name
SHEET_URL <- "https://docs.google.com/spreadsheets/d/10ejoGa10yeWCeEH_sjFASYGujDrS1XKyNYSMGoqKloE/edit?gid=852659656#gid=852659656"
SHEET_NAME <- "ellis-0-completed"

# Output directory (same as ellis-0-scan.py)
OUTPUT_DIR <- "data-private/derived/ellis-0"
OUTPUT_CSV <- file.path(OUTPUT_DIR, "ellis-0-scan.csv")
OUTPUT_RDS <- file.path(OUTPUT_DIR, "ellis-0-scan.rds")

# SQLite database configuration
DB_PATH <- "data-private/derived/global-data.sqlite"
DB_TABLE <- "ellis_0_cafes"

# ---- declare-functions ------

load_completed_cafe_data <- function(sheet_url, sheet_name) {
  #' Load manually completed cafe data from Google Sheets
  #'
  #' @param sheet_url URL of the Google Sheets document
  #' @param sheet_name Name of the sheet within the document
  #' @return DataFrame with cafe data

  message("Loading cafe data from Google Sheets...")
  message("Sheet URL: ", sheet_url)
  message("Sheet name: ", sheet_name)

  tryCatch({
    # Read data from Google Sheets
    data <- read_sheet(
      ss = sheet_url,
      sheet = sheet_name,
      col_types = "c"  # Read all columns as character initially
    )

    message("Successfully loaded ", nrow(data), " cafe records")

    # Convert data types as needed
    data <- data %>%
      mutate(
        # Convert numeric columns
        lat = as.numeric(lat),
        lng = as.numeric(lng),
        rating = as.numeric(rating),
        user_ratings_total = as.integer(user_ratings_total),
        price_level = as.integer(price_level),
        # Ensure character columns
        place_id = as.character(place_id),
        name = as.character(name),
        address = as.character(address),
        formatted_address = as.character(formatted_address),
        types = as.character(types),
        business_status = as.character(business_status),
        phone = as.character(phone),
        website = as.character(website),
        hours = as.character(hours)
      )

    return(data)

  }, error = function(e) {
    message("Error loading data from Google Sheets: ", e$message)
    message("\nTroubleshooting:")
    message("1. Check that you have access to the Google Sheet")
    message("2. Ensure the sheet name '", sheet_name, "' is correct")
    message("3. Run gs4_auth() manually if authentication fails")
    return(NULL)
  })
}

# ---- load-data ------
# Create output directory if it doesn't exist
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Load the data from Google Sheets
cafe_data <- load_completed_cafe_data(SHEET_URL, SHEET_NAME)

if (is.null(cafe_data)) {
  message("Failed to load cafe data from Google Sheets")
  quit(status = 1)
}

# ---- verify-values ------
message("\n" , paste(rep("=", 80), collapse = ""))
message("DATA SUMMARY")
message(paste(rep("=", 80), collapse = ""))
message("Records: ", nrow(cafe_data))
message("Columns: ", ncol(cafe_data))

if (nrow(cafe_data) > 0) {
  message("\nColumn names:")
  message(paste("  -", colnames(cafe_data), collapse = "\n"))
  
  message("\nData quality checks:")
  message("  - Records with place_id: ", sum(!is.na(cafe_data$place_id)))
  message("  - Records with name: ", sum(!is.na(cafe_data$name)))
  message("  - Records with coordinates: ", sum(!is.na(cafe_data$lat) & !is.na(cafe_data$lng)))
  message("  - Records with rating: ", sum(!is.na(cafe_data$rating)))
  message("  - Records with phone: ", sum(!is.na(cafe_data$phone)))
  message("  - Records with website: ", sum(!is.na(cafe_data$website)))
  
  if ("business_status" %in% colnames(cafe_data)) {
    message("\nBusiness status distribution:")
    status_counts <- table(cafe_data$business_status, useNA = "ifany")
    for (status in names(status_counts)) {
      message("  - ", status, ": ", status_counts[status])
    }
  }
}

# ---- save-to-disk ------
message("\n", paste(rep("=", 80), collapse = ""))
message("SAVING DATA")
message(paste(rep("=", 80), collapse = ""))

# Save as CSV
write_csv(cafe_data, OUTPUT_CSV)
message("✅ Saved CSV: ", OUTPUT_CSV)

# Save as RDS for R users
saveRDS(cafe_data, OUTPUT_RDS)
message("✅ Saved RDS: ", OUTPUT_RDS)

# Save to global SQLite database
DB_DIR <- dirname(DB_PATH)
dir.create(DB_DIR, recursive = TRUE, showWarnings = FALSE)

tryCatch({
  conn <- dbConnect(RSQLite::SQLite(), DB_PATH)
  dbWriteTable(conn, DB_TABLE, cafe_data, overwrite = TRUE)
  dbDisconnect(conn)
  
  message("✅ Saved to SQLite: ", DB_PATH)
  message("   Table: ", DB_TABLE)
  message("   Records: ", nrow(cafe_data))
}, error = function(e) {
  message("⚠️  Warning: Could not save to SQLite: ", e$message)
})

# ---- verify-save ------
message("\n", paste(rep("=", 80), collapse = ""))
message("VERIFICATION")
message(paste(rep("=", 80), collapse = ""))

if (file.exists(OUTPUT_CSV) && file.exists(OUTPUT_RDS)) {
  message("✅ Ellis-0-completed processing finished successfully!")
  message("\nOutput files:")
  message("  - CSV: ", OUTPUT_CSV)
  message("  - RDS: ", OUTPUT_RDS)
  message("  - SQLite: ", DB_PATH, " (table: ", DB_TABLE, ")")
  message("\nRecords: ", nrow(cafe_data))
  
  if (nrow(cafe_data) > 0 && "name" %in% colnames(cafe_data)) {
    message("\nSample of cafes loaded:")
    sample_size <- min(5, nrow(cafe_data))
    sample_cafes <- cafe_data %>%
      select(any_of(c("name", "address", "rating", "user_ratings_total"))) %>%
      head(sample_size)
    print(sample_cafes)
  }
  
} else {
  message("❌ Error: Files were not saved correctly")
  quit(status = 1)
}

message("\n", paste(rep("=", 80), collapse = ""))
message("ALTERNATIVE DATA SOURCE ACTIVE")
message(paste(rep("=", 80), collapse = ""))
message("This script provides an alternative to ellis-0-scan.py by loading")
message("manually completed and verified cafe data from Google Sheets.")
message("Use this when you want to work with curated data instead of API results.")
message(paste(rep("=", 80), collapse = ""))
















