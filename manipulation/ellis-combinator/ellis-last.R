#' ---
#' title: "Ellis-Last: Data Consolidation into SQLite Database"
#' subtitle: "Consolidate all Ellis pipeline data into unified database"
#' author: "RG-FIDES Research Team"
#' date: "last Updated: `r Sys.Date()`"
#' ---

#+ echo=FALSE
# Rscript manipulation/ellis-last.R  # run from project root

# ---- environment-setup ------
library(tidyverse)
library(DBI)
library(RSQLite)

# ---- declare-globals -------
# Database configuration
DB_PATH <- "data-private/derived/global-data.sqlite"

# Input directories
ELLIS_0_DIR <- "data-private/derived/ellis-0"
ELLIS_1_DIR <- "data-private/derived/ellis-1-open-data"
ELLIS_2_DIR <- "data-private/derived/ellis-2-open-data"
ELLIS_3_DIR <- "data-private/derived/ellis-3-open-data"
ELLIS_4_DIR <- "data-private/derived/ellis-4-open-data"
ELLIS_5_DIR <- "data-private/derived/ellis-5-open-data"
ELLIS_6_DIR <- "data-private/derived/ellis-6-transform"

# ---- declare-functions ------

load_csv_or_rds <- function(directory, pattern = "*.csv") {
  #' Load data from CSV or RDS files in a directory
  #'
  #' @param directory Directory to search for files
  #' @param pattern File pattern to match (default: *.csv)
  #' @return DataFrame or NULL if no files found

  if (!dir.exists(directory)) {
    message("Directory does not exist: ", directory)
    return(NULL)
  }

  # Look for CSV files first
  csv_files <- list.files(directory, pattern = "*.csv", full.names = TRUE)
  if (length(csv_files) > 0) {
    message("Loading CSV: ", csv_files[1])
    return(read_csv(csv_files[1], show_col_types = FALSE))
  }

  # Look for RDS files as fallback
  rds_files <- list.files(directory, pattern = "*.rds", full.names = TRUE)
  if (length(rds_files) > 0) {
    message("Loading RDS: ", rds_files[1])
    return(readRDS(rds_files[1]))
  }

  message("No CSV or RDS files found in: ", directory)
  return(NULL)
}

create_database_tables <- function(db_path) {
  #' Create SQLite database
  #'
  #' @param db_path Path to SQLite database file

  message("Creating SQLite database: ", db_path)

  # Create database directory if it doesn't exist
  dir.create(dirname(db_path), recursive = TRUE, showWarnings = FALSE)

  # Connect to database (creates it if it doesn't exist)
  con <- dbConnect(RSQLite::SQLite(), db_path)
  dbDisconnect(con)
  
  message("Database created successfully")
}

save_table_to_db <- function(data, table_name, db_path) {
  #' Save a data frame to SQLite database
  #'
  #' @param data DataFrame to save
  #' @param table_name Name of the table
  #' @param db_path Database path

  if (is.null(data) || nrow(data) == 0) {
    message("No data to save for table: ", table_name)
    return()
  }

  message("Saving ", nrow(data), " records to table: ", table_name)

  con <- dbConnect(RSQLite::SQLite(), db_path)

  # Save data to table (overwrite if exists)
  dbWriteTable(con, table_name, data, overwrite = TRUE)

  dbDisconnect(con)
  message("✅ Table ", table_name, " saved successfully")
}

# ---- load-data ------
message("=== Starting Ellis-Last: Data Consolidation ===")

# Load data from each Ellis script
ellis_0_data <- load_csv_or_rds(ELLIS_0_DIR)
ellis_1_data <- load_csv_or_rds(ELLIS_1_DIR)
ellis_2_data <- load_csv_or_rds(ELLIS_2_DIR)
ellis_3_data <- load_csv_or_rds(ELLIS_3_DIR)
ellis_4_data <- load_csv_or_rds(ELLIS_4_DIR)
ellis_5_data <- load_csv_or_rds(ELLIS_5_DIR)
ellis_6_data <- load_csv_or_rds(ELLIS_6_DIR)

# ---- verify-data ------
data_sources <- list(
  "ellis_0_cafes" = ellis_0_data,
  "ellis_1_property_assessment" = ellis_1_data,
  "ellis_2_business_licenses" = ellis_2_data,
  "ellis_3_community_services" = ellis_3_data,
  "ellis_4_open_data" = ellis_4_data,
  "ellis_5_open_data" = ellis_5_data,
  "ellis_6_cafes_with_demographics" = ellis_6_data
)

message("\nData loading summary:")
for (name in names(data_sources)) {
  data <- data_sources[[name]]
  if (!is.null(data)) {
    message("- ", name, ": ", nrow(data), " records")
  } else {
    message("- ", name, ": No data found")
  }
}

# ---- create-database ------
create_database_tables(DB_PATH)

# ---- save-tables ------
message("\n=== Saving tables to database ===")

save_table_to_db(ellis_0_data, "ellis_0_cafes", DB_PATH)
save_table_to_db(ellis_1_data, "ellis_1_property_assessment", DB_PATH)
save_table_to_db(ellis_2_data, "ellis_2_business_licenses", DB_PATH)
save_table_to_db(ellis_3_data, "ellis_3_community_services", DB_PATH)
save_table_to_db(ellis_4_data, "ellis_4_open_data", DB_PATH)
save_table_to_db(ellis_5_data, "ellis_5_open_data", DB_PATH)
save_table_to_db(ellis_6_data, "ellis_6_cafes_with_demographics", DB_PATH)

# ---- verify-database ------
message("\n=== Database verification ===")

con <- dbConnect(RSQLite::SQLite(), DB_PATH)

# List all tables
tables <- dbListTables(con)
message("Tables in database:")
for (table in tables) {
  count <- dbGetQuery(con, paste0("SELECT COUNT(*) as count FROM ", table))$count
  message("- ", table, ": ", count, " records")
}

dbDisconnect(con)

# ---- final-verification ------
if (file.exists(DB_PATH)) {
  db_size <- file.info(DB_PATH)$size
  message("\n✅ Ellis-Last completed successfully!")
  message("- Database: ", DB_PATH)
  message("- Size: ", round(db_size / 1024 / 1024, 2), " MB")
  message("- Tables: ", length(tables))
  message("- Total records: ", sum(sapply(data_sources, function(x) if(!is.null(x)) nrow(x) else 0)))
} else {
  message("❌ Error: Database file was not created")
  quit(status = 1)
}