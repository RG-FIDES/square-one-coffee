# ---- load-packages -----------------------------------------------------------
library(magrittr)   # pipes
library(ggplot2)    # graphs
library(forcats)    # factors
library(stringr)    # strings
library(lubridate)  # dates
library(labelled)   # labels
library(dplyr)      # data wrangling
library(tidyr)      # data reshaping
library(scales)     # formatting
library(broom)      # model tidying
library(emmeans)    # model interpretation
library(janitor)    # data cleaning
library(testit)     # assertions
library(fs)         # file system operations
library(DBI)        # database interface
library(RSQLite)    # SQLite backend
library(readr)      # CSV reading

# ---- load-sources ------------------------------------------------------------
source("./scripts/common-functions.R")
source("./scripts/operational-functions.R")
source("./scripts/graphing/graph-presets.R")

# ---- declare-globals ---------------------------------------------------------
local_root <- "./analysis/eda-3/"
local_data <- paste0(local_root, "data-local/")
prints_folder <- paste0(local_root, "prints/")
data_private_derived <- "./data-private/derived/eda-3/"

# Idempotent directory creation
if (!fs::dir_exists(local_data)) {fs::dir_create(local_data)}
if (!fs::dir_exists(prints_folder)) {fs::dir_create(prints_folder)}
if (!fs::dir_exists(data_private_derived)) {fs::dir_create(data_private_derived)}

# ---- declare-functions -------------------------------------------------------
# Function to extract street name from address/stop name (vectorized)
extract_street <- function(text) {
  # Remove direction indicators (NW, SW, NE, SE, EB, WB, SB, NB)
  text <- str_replace_all(text, "(\\s+(NW|SW|NE|SE|EB|WB|SB|NB))", "")
  
  # Extract main street name (before '&' or 'and')
  # For addresses like "8715 109 St NW" or stops like "109 Street & 110 Avenue"
  street <- str_extract(text, "\\d+\\s+Street|\\d+\\s+Avenue|\\d+[A-Z]?\\s+St|\\d+[A-Z]?\\s+Ave")
  
  # Standardize to "Street" format (vectorized with ifelse)
  street <- ifelse(!is.na(street), str_replace(street, "\\s+St\\b", " Street"), street)
  street <- ifelse(!is.na(street), str_replace(street, "\\s+Ave\\b", " Avenue"), street)
  
  return(street)
}

# ---- httpgd ------------------------------------------------------------------
# VS Code interactive plotting
if (requireNamespace("httpgd", quietly = TRUE)) {
  library(httpgd)
  hgd()
  hgd_browse()
} else {
  message("httpgd not available - using default graphics device")
}

# ---- load-data ---------------------------------------------------------------
# Load bus stops from CSV
ds_bus_stops <- read_csv(
  "./data-private/derived/ellis-2-open-data/ellis-2-open-data.csv",
  show_col_types = FALSE
)

# Load cafes from SQLite database
con <- dbConnect(SQLite(), "./data-private/derived/global-data.sqlite")
ds_cafes <- dbReadTable(con, "ellis_6_cafes_with_demographics")
dbDisconnect(con)

message("📊 Data loaded:")
message("  - Bus stops: ", nrow(ds_bus_stops), " observations")
message("  - Cafes: ", nrow(ds_cafes), " observations")

# ---- inspect-data-0 ----------------------------------------------------------
# Initial data inspection
ds_bus_stops %>% glimpse()
ds_bus_stops %>% head(10) %>% print()

ds_cafes %>% glimpse()
ds_cafes %>% head(10) %>% print()

# ---- tweak-data-0 ------------------------------------------------------------
# Extract street names from both datasets
ds_bus_stops_clean <- ds_bus_stops %>%
  mutate(
    street = extract_street(stop_name),
    source = "bus_stop"
  ) %>%
  filter(!is.na(street))

ds_cafes_clean <- ds_cafes %>%
  filter(!is.na(address)) %>%
  mutate(
    street = extract_street(address),
    source = "cafe"
  ) %>%
  filter(!is.na(street))

message("  - Bus stops with street names: ", nrow(ds_bus_stops_clean))
message("  - Cafes with street names: ", nrow(ds_cafes_clean))

# Save cleaned datasets
saveRDS(ds_bus_stops_clean, paste0(local_data, "ds_bus_stops_clean.rds"))
saveRDS(ds_cafes_clean, paste0(local_data, "ds_cafes_clean.rds"))

# ---- inspect-data-1 ----------------------------------------------------------
# Check street extraction results
ds_bus_stops_clean %>%
  select(stop_name, street) %>%
  head(20) %>%
  print()

ds_cafes_clean %>%
  select(name, address, street) %>%
  head(20) %>%
  print()

# ---- g1-data-prep ------------------------------------------------------------
# Count bus stops per street
bus_stops_by_street <- ds_bus_stops_clean %>%
  group_by(street) %>%
  summarize(
    bus_stop_count = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(bus_stop_count))

# Count cafes per street
cafes_by_street <- ds_cafes_clean %>%
  group_by(street) %>%
  summarize(
    cafe_count = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(cafe_count))

# Join to find streets with both
streets_combined <- bus_stops_by_street %>%
  full_join(cafes_by_street, by = "street") %>%
  mutate(
    bus_stop_count = replace_na(bus_stop_count, 0),
    cafe_count = replace_na(cafe_count, 0),
    has_both = (bus_stop_count > 0 & cafe_count > 0),
    category = case_when(
      bus_stop_count > 0 & cafe_count > 0 ~ "Both",
      bus_stop_count > 0 ~ "Bus stops only",
      cafe_count > 0 ~ "Cafes only",
      TRUE ~ "Neither"
    )
  ) %>%
  arrange(desc(bus_stop_count + cafe_count))

# Save combined dataset
saveRDS(streets_combined, paste0(local_data, "streets_combined.rds"))

message("  - Streets with bus stops: ", sum(bus_stops_by_street$bus_stop_count > 0))
message("  - Streets with cafes: ", sum(cafes_by_street$cafe_count > 0))
message("  - Streets with both: ", sum(streets_combined$has_both))

# ---- inspect-data-2 ----------------------------------------------------------
# Summary statistics
streets_combined %>%
  filter(has_both) %>%
  summarize(
    n_streets = n(),
    total_bus_stops = sum(bus_stop_count),
    total_cafes = sum(cafe_count),
    mean_bus_stops = mean(bus_stop_count),
    mean_cafes = mean(cafe_count),
    median_bus_stops = median(bus_stop_count),
    median_cafes = median(cafe_count)
  ) %>%
  print()

# Top streets by combined activity
streets_combined %>%
  filter(has_both) %>%
  mutate(total_activity = bus_stop_count + cafe_count) %>%
  arrange(desc(total_activity)) %>%
  head(20) %>%
  print()

# ---- g1 ----------------------------------------------------------------------
# Bar chart: Top 20 streets with both bus stops and cafes
g1_data <- streets_combined %>%
  filter(has_both) %>%
  mutate(total_activity = bus_stop_count + cafe_count) %>%
  arrange(desc(total_activity)) %>%
  head(20) %>%
  mutate(street = fct_reorder(street, total_activity))

g1_top_streets <- g1_data %>%
  ggplot(aes(x = street, y = total_activity)) +
  geom_col(fill = "steelblue", alpha = 0.8) +
  coord_flip() +
  labs(
    title = "Top 20 Streets by Combined Bus Stops and Cafes",
    subtitle = "Streets with highest total transit and cafe activity",
    x = "Street",
    y = "Total Count (Bus Stops + Cafes)",
    caption = "Source: Ellis-2 (bus stops) + Ellis-6 (cafes)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.text.y = element_text(size = 10)
  )

ggsave(paste0(prints_folder, "g1_top_streets.png"), 
       g1_top_streets, width = 10, height = 8, dpi = 300)

print(g1_top_streets)

# ---- g2 ----------------------------------------------------------------------
# Scatter plot: Bus stops vs cafes by street
g2_scatter <- streets_combined %>%
  filter(has_both) %>%
  ggplot(aes(x = bus_stop_count, y = cafe_count)) +
  geom_point(alpha = 0.6, size = 3, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick", linewidth = 1) +
  labs(
    title = "Relationship Between Bus Stops and Cafes",
    subtitle = "Do streets with more bus stops also have more cafes?",
    x = "Number of Bus Stops",
    y = "Number of Cafes",
    caption = "Source: Ellis-2 (bus stops) + Ellis-6 (cafes)"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14))

ggsave(paste0(prints_folder, "g2_scatter.png"), 
       g2_scatter, width = 8.5, height = 6, dpi = 300)

print(g2_scatter)

# ---- g3 ----------------------------------------------------------------------
# Stacked bar: Count of streets by category
g3_data <- streets_combined %>%
  filter(category != "Neither") %>%
  count(category) %>%
  mutate(
    category = fct_relevel(category, "Both", "Bus stops only", "Cafes only")
  )

g3_categories <- g3_data %>%
  ggplot(aes(x = category, y = n, fill = category)) +
  geom_col(alpha = 0.8, width = 0.7) +
  geom_text(aes(label = n), vjust = -0.5, size = 5) +
  scale_fill_manual(
    values = c(
      "Both" = "#2ecc71",
      "Bus stops only" = "#3498db",
      "Cafes only" = "#e74c3c"
    )
  ) +
  labs(
    title = "Distribution of Streets by Transit and Cafe Presence",
    subtitle = "How many streets have bus stops, cafes, or both?",
    x = "Street Category",
    y = "Number of Streets",
    caption = "Source: Ellis-2 (bus stops) + Ellis-6 (cafes)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "none"
  )

ggsave(paste0(prints_folder, "g3_categories.png"), 
       g3_categories, width = 8.5, height = 6, dpi = 300)

print(g3_categories)

# ---- g4 ----------------------------------------------------------------------
# Detailed view: Top 15 streets with both, showing composition
g4_data <- streets_combined %>%
  filter(has_both) %>%
  mutate(total = bus_stop_count + cafe_count) %>%
  arrange(desc(total)) %>%
  head(15) %>%
  pivot_longer(
    cols = c(bus_stop_count, cafe_count),
    names_to = "type",
    values_to = "count"
  ) %>%
  mutate(
    type = recode(type,
                  "bus_stop_count" = "Bus Stops",
                  "cafe_count" = "Cafes"),
    street = fct_reorder(street, total)
  )

g4_composition <- g4_data %>%
  ggplot(aes(x = street, y = count, fill = type)) +
  geom_col(position = "stack", alpha = 0.8) +
  coord_flip() +
  scale_fill_manual(values = c("Bus Stops" = "#3498db", "Cafes" = "#e74c3c")) +
  labs(
    title = "Top 15 Streets: Composition of Bus Stops vs Cafes",
    subtitle = "Stacked view showing relative presence",
    x = "Street",
    y = "Count",
    fill = "Type",
    caption = "Source: Ellis-2 (bus stops) + Ellis-6 (cafes)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "bottom"
  )

ggsave(paste0(prints_folder, "g4_composition.png"), 
       g4_composition, width = 10, height = 8, dpi = 300)

print(g4_composition)

# ---- summary-stats -----------------------------------------------------------
# Generate comprehensive summary
summary_stats <- list(
  total_bus_stops = nrow(ds_bus_stops_clean),
  total_cafes = nrow(ds_cafes_clean),
  unique_streets_with_bus_stops = nrow(bus_stops_by_street),
  unique_streets_with_cafes = nrow(cafes_by_street),
  streets_with_both = sum(streets_combined$has_both),
  pct_bus_stop_streets_with_cafes = round(
    sum(streets_combined$has_both) / nrow(bus_stops_by_street) * 100, 2
  ),
  pct_cafe_streets_with_bus_stops = round(
    sum(streets_combined$has_both) / nrow(cafes_by_street) * 100, 2
  )
)

print("Summary Statistics:")
print(summary_stats)

# Save summary
saveRDS(summary_stats, paste0(local_data, "summary_stats.rds"))


