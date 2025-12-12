#' ---
#' title: "RAP-0 Market Overview Analysis (R/ggplot2 Version)"
#' author: "Research Team"
#' date: "Last Updated: `r Sys.Date()`"
#' ---

#' RAP-0 Market Overview Analysis
#' 
#' Analyzes the Edmonton coffee market competitive landscape with focus on:
#' - Geographic distribution (g2 family)
#' - Pricing landscape (g3 family)
#' - Market segmentation (g4 family)
#' 
#' All graphs follow the EDA style guide: 8.5 × 5.5 inches, 300 DPI, unique identifiers
#' This version uses tidyverse/ggplot2 for full R workflow

# ---- load-packages -----------------------------------------------------------
library(DBI)
library(RSQLite)
library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)
library(forcats)
library(scales)

# ---- load-sources ------------------------------------------------------------
# Load graph presets if available
if (file.exists("./scripts/graphing/graph-presets.R")) {
  source("./scripts/graphing/graph-presets.R")
}

# ---- declare-globals ---------------------------------------------------------
DB_PATH <- "./data-private/derived/rap-0-competition-intel.sqlite"
PRINTS_FOLDER <- "./analysis/rap-0-R/prints/"
FIG_WIDTH <- 8.5
FIG_HEIGHT <- 5.5
FIG_DPI <- 300

# Create prints folder
if (!dir.exists(PRINTS_FOLDER)) {
  dir.create(PRINTS_FOLDER, recursive = TRUE)
}

cat("======================================================================\n")
cat("RAP-0 MARKET OVERVIEW ANALYSIS (R/ggplot2)\n")
cat("======================================================================\n")
cat("Edmonton Coffee Market Competitive Intelligence\n\n")

cat(sprintf("✓ Prints folder: %s\n", PRINTS_FOLDER))

# Define color palette for consistency
soc_color <- "#E63946"
competitor_color <- "#457B9D"
neutral_colors <- c("#2E86AB", "#A23B72", "#F1A208", "#2A9D8F")

# ---- load-data ---------------------------------------------------------------
cat("\n## Loading Data\n")

conn <- dbConnect(RSQLite::SQLite(), DB_PATH)

cafes <- dbReadTable(conn, "cafes_complete") %>% as_tibble()
soc <- dbReadTable(conn, "soc_locations") %>% as_tibble()
competitors <- dbReadTable(conn, "competitors") %>% as_tibble()

dbDisconnect(conn)

cat(sprintf("✓ Loaded %d cafes (%d SOC + %d competitors)\n\n", 
            nrow(cafes), nrow(soc), nrow(competitors)))

# ===== G2 FAMILY: GEOGRAPHIC DISTRIBUTION =====
cat("## G2 Family: Geographic Distribution Analysis\n")
cat("   Question: Where are cafes concentrated in Edmonton?\n\n")

# ---- g2-data-prep ------------------------------------------------------------
cat("### g2-data-prep: Preparing geographic summary\n")

g2_data <- cafes %>%
  mutate(
    is_soc = str_detect(name, regex("Square One", ignore_case = TRUE)),
    business_type = if_else(is_soc, "SOC", "Competitor")
  )

geo_summary <- g2_data %>%
  group_by(neighborhood, business_type) %>%
  summarise(
    count = n(),
    avg_price = mean(avg_beverage_price, na.rm = TRUE),
    avg_rating = mean(google_rating, na.rm = TRUE),
    total_reviews = sum(review_count, na.rm = TRUE),
    .groups = "drop"
  )

cat(sprintf("✓ Geographic summary prepared: %d neighborhood-type combinations\n", nrow(geo_summary)))

# ---- g21 ---------------------------------------------------------------------
cat("\n### g21: Cafe concentration by neighborhood\n")

# Prepare data for plotting
neighborhood_counts <- g2_data %>%
  count(neighborhood, name = "count") %>%
  arrange(count) %>%
  mutate(
    neighborhood = fct_reorder(neighborhood, count),
    has_soc = neighborhood %in% (soc %>% pull(neighborhood))
  )

g21 <- ggplot(neighborhood_counts, aes(x = neighborhood, y = count, fill = has_soc)) +
  geom_col() +
  scale_fill_manual(
    values = c("FALSE" = competitor_color, "TRUE" = soc_color),
    labels = c("No SOC presence", "Has SOC location"),
    name = NULL
  ) +
  coord_flip() +
  labs(
    title = "Cafe Concentration Across Edmonton Neighborhoods",
    x = "Neighborhood",
    y = "Number of Cafes"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave(paste0(PRINTS_FOLDER, "g21_cafe_concentration.png"), 
       g21, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g21_cafe_concentration.png\n")

# ---- g22 ---------------------------------------------------------------------
cat("\n### g22: Geographic distribution map\n")

g22 <- ggplot(g2_data, aes(x = longitude, y = latitude)) +
  geom_point(
    data = g2_data %>% filter(!is_soc),
    aes(color = "Competitors"),
    size = 3, alpha = 0.7, shape = 16
  ) +
  geom_point(
    data = g2_data %>% filter(is_soc),
    aes(color = "Square One Coffee"),
    size = 5, alpha = 0.9, shape = 18
  ) +
  # Downtown reference point
  geom_point(
    aes(x = -113.4909, y = 53.5444, color = "Downtown Core"),
    size = 8, shape = 8, stroke = 2
  ) +
  scale_color_manual(
    values = c(
      "Competitors" = competitor_color,
      "Square One Coffee" = soc_color,
      "Downtown Core" = "gold"
    ),
    name = NULL
  ) +
  labs(
    title = "Edmonton Cafe Geographic Distribution",
    x = "Longitude",
    y = "Latitude"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    panel.grid = element_line(alpha = 0.3)
  )

ggsave(paste0(PRINTS_FOLDER, "g22_geographic_map.png"), 
       g22, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g22_geographic_map.png\n")

# ---- g23 ---------------------------------------------------------------------
cat("\n### g23: Location zones distribution\n")

zone_data <- g2_data %>%
  filter(!is.na(location_zone)) %>%
  mutate(
    location_zone = factor(location_zone, levels = c("core", "inner", "outer", "peripheral"))
  ) %>%
  count(location_zone, business_type)

g23 <- ggplot(zone_data, aes(x = location_zone, y = n, fill = business_type)) +
  geom_col(position = "stack", width = 0.6) +
  scale_fill_manual(
    values = c("Competitor" = competitor_color, "SOC" = soc_color),
    labels = c("Competitors", "Square One Coffee")
  ) +
  scale_x_discrete(
    labels = c(
      "core" = "Core\n(<2 km)",
      "inner" = "Inner\n(2-5 km)",
      "outer" = "Outer\n(5-10 km)",
      "peripheral" = "Peripheral\n(>10 km)"
    )
  ) +
  labs(
    title = "Cafe Distribution by Distance from Downtown",
    x = "Location Zone",
    y = "Number of Cafes",
    fill = NULL
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave(paste0(PRINTS_FOLDER, "g23_location_zones.png"), 
       g23, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g23_location_zones.png\n\n")

# ===== G3 FAMILY: PRICING LANDSCAPE =====
cat("## G3 Family: Pricing Landscape Analysis\n")
cat("   Question: How does pricing position competitors in the market?\n\n")

# ---- g3-data-prep ------------------------------------------------------------
cat("### g3-data-prep: Preparing pricing analysis\n")

g3_data <- cafes %>%
  filter(!is.na(avg_beverage_price)) %>%
  mutate(
    is_soc = str_detect(name, regex("Square One", ignore_case = TRUE)),
    business_type = if_else(is_soc, "SOC", "Competitor")
  )

cat(sprintf("✓ Pricing data prepared: %d cafes with price information\n", nrow(g3_data)))

# ---- g31 ---------------------------------------------------------------------
cat("\n### g31: Price distribution histogram\n")

# Calculate means for reference lines
soc_mean_price <- g3_data %>% filter(is_soc) %>% pull(avg_beverage_price) %>% mean()
comp_mean_price <- g3_data %>% filter(!is_soc) %>% pull(avg_beverage_price) %>% mean()

g31 <- ggplot(g3_data, aes(x = avg_beverage_price, fill = business_type)) +
  geom_histogram(
    data = g3_data %>% filter(!is_soc),
    bins = 15, alpha = 0.6, color = "black"
  ) +
  geom_histogram(
    data = g3_data %>% filter(is_soc),
    bins = 10, alpha = 0.8, color = "black"
  ) +
  geom_vline(
    xintercept = comp_mean_price,
    color = "#1D3557", linetype = "dashed", linewidth = 1
  ) +
  geom_vline(
    xintercept = soc_mean_price,
    color = "#A01A1A", linetype = "dashed", linewidth = 1
  ) +
  scale_fill_manual(
    values = c("Competitor" = competitor_color, "SOC" = soc_color),
    labels = c("Competitors", "Square One Coffee")
  ) +
  annotate(
    "text", x = comp_mean_price, y = Inf, 
    label = sprintf("Competitor Mean: $%.2f", comp_mean_price),
    vjust = 2, hjust = -0.1, size = 3
  ) +
  annotate(
    "text", x = soc_mean_price, y = Inf,
    label = sprintf("SOC Mean: $%.2f", soc_mean_price),
    vjust = 4, hjust = -0.1, size = 3
  ) +
  labs(
    title = "Edmonton Coffee Market Price Distribution",
    x = "Average Beverage Price (CAD)",
    y = "Number of Cafes",
    fill = NULL
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

ggsave(paste0(PRINTS_FOLDER, "g31_price_distribution.png"), 
       g31, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g31_price_distribution.png\n")

# ---- g32 ---------------------------------------------------------------------
cat("\n### g32: Price categories by location type\n")

price_cat_data <- g3_data %>%
  filter(!is.na(price_category)) %>%
  mutate(
    price_category = factor(price_category, 
                           levels = c("budget", "moderate", "premium", "luxury"))
  ) %>%
  count(price_category, business_type)

g32 <- ggplot(price_cat_data, aes(x = price_category, y = n, fill = business_type)) +
  geom_col(position = "dodge", width = 0.7) +
  scale_fill_manual(
    values = c("Competitor" = competitor_color, "SOC" = soc_color),
    labels = c("Competitors", "Square One Coffee")
  ) +
  scale_x_discrete(
    labels = c(
      "budget" = "Budget\n(<$3.50)",
      "moderate" = "Moderate\n($3.50-$5.00)",
      "premium" = "Premium\n($5.00-$6.50)",
      "luxury" = "Luxury\n(>$6.50)"
    )
  ) +
  labs(
    title = "Market Segmentation by Price Point",
    x = "Price Category",
    y = "Number of Cafes",
    fill = NULL
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave(paste0(PRINTS_FOLDER, "g32_price_categories.png"), 
       g32, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g32_price_categories.png\n")

# ---- g33 ---------------------------------------------------------------------
cat("\n### g33: Price vs Quality positioning\n")

g33 <- ggplot(g3_data, aes(x = avg_beverage_price, y = google_rating, 
                          color = business_type, shape = business_type, size = business_type)) +
  geom_point(alpha = 0.7) +
  scale_color_manual(
    values = c("Competitor" = competitor_color, "SOC" = soc_color),
    labels = c("Competitors", "Square One Coffee")
  ) +
  scale_shape_manual(
    values = c("Competitor" = 16, "SOC" = 18),
    labels = c("Competitors", "Square One Coffee")
  ) +
  scale_size_manual(
    values = c("Competitor" = 3, "SOC" = 5),
    labels = c("Competitors", "Square One Coffee")
  ) +
  labs(
    title = "Price-Quality Positioning Map",
    x = "Average Beverage Price (CAD)",
    y = "Google Rating (1-5)",
    color = NULL,
    shape = NULL,
    size = NULL
  ) +
  coord_cartesian(ylim = c(3.3, 5.1)) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    panel.grid = element_line(alpha = 0.3)
  )

ggsave(paste0(PRINTS_FOLDER, "g33_price_quality_map.png"), 
       g33, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g33_price_quality_map.png\n\n")

# ===== G4 FAMILY: MARKET SEGMENTATION =====
cat("## G4 Family: Market Segmentation Analysis\n")
cat("   Question: How do cafe types and characteristics segment the market?\n\n")

# ---- g4-data-prep ------------------------------------------------------------
cat("### g4-data-prep: Preparing market segmentation\n")

g4_data <- cafes %>%
  mutate(
    is_soc = str_detect(name, regex("Square One", ignore_case = TRUE)),
    business_type = if_else(is_soc, "SOC", "Competitor")
  )

cat(sprintf("✓ Segmentation data prepared: %d cafes\n", nrow(g4_data)))

# ---- g41 ---------------------------------------------------------------------
cat("\n### g41: Cafe type distribution\n")

type_data <- g4_data %>%
  count(cafe_type, business_type) %>%
  mutate(cafe_type = fct_reorder(cafe_type, n, .fun = sum))

g41 <- ggplot(type_data, aes(x = cafe_type, y = n, fill = business_type)) +
  geom_col(position = "stack") +
  scale_fill_manual(
    values = c("Competitor" = competitor_color, "SOC" = soc_color),
    labels = c("Competitors", "Square One Coffee")
  ) +
  coord_flip() +
  labs(
    title = "Edmonton Market Segmentation by Cafe Type",
    x = "Cafe Type",
    y = "Number of Cafes",
    fill = NULL
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave(paste0(PRINTS_FOLDER, "g41_cafe_type_distribution.png"), 
       g41, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g41_cafe_type_distribution.png\n")

# ---- g42 ---------------------------------------------------------------------
cat("\n### g42: Ownership structure\n")

ownership_counts <- g4_data %>%
  count(ownership, name = "count") %>%
  mutate(
    percentage = count / sum(count) * 100,
    ownership = fct_reorder(ownership, count)
  )

g42 <- ggplot(ownership_counts, aes(x = "", y = count, fill = ownership)) +
  geom_col(width = 1, color = "white") +
  coord_polar("y", start = 0) +
  scale_fill_manual(values = neutral_colors) +
  geom_text(
    aes(label = sprintf("%s\n%.1f%%", ownership, percentage)),
    position = position_stack(vjust = 0.5),
    color = "white",
    fontface = "bold",
    size = 3
  ) +
  labs(title = "Edmonton Coffee Market Ownership Structure") +
  theme_void() +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    legend.position = "none"
  )

ggsave(paste0(PRINTS_FOLDER, "g42_ownership_structure.png"), 
       g42, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g42_ownership_structure.png\n")

# ---- g43 ---------------------------------------------------------------------
cat("\n### g43: Food offerings comparison\n")

food_data <- g4_data %>%
  filter(!is.na(has_food)) %>%
  mutate(
    has_food = factor(has_food, 
                     levels = c("none", "pastries_only", "sandwiches_pastries", "full_menu"))
  ) %>%
  count(has_food, business_type)

g43 <- ggplot(food_data, aes(x = has_food, y = n, fill = business_type)) +
  geom_col(position = "dodge", width = 0.7) +
  scale_fill_manual(
    values = c("Competitor" = competitor_color, "SOC" = soc_color),
    labels = c("Competitors", "Square One Coffee")
  ) +
  scale_x_discrete(
    labels = c(
      "none" = "None",
      "pastries_only" = "Pastries\nOnly",
      "sandwiches_pastries" = "Sandwiches &\nPastries",
      "full_menu" = "Full\nMenu"
    )
  ) +
  labs(
    title = "Food Service Offerings Across Market",
    x = "Food Offerings",
    y = "Number of Cafes",
    fill = NULL
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave(paste0(PRINTS_FOLDER, "g43_food_offerings.png"), 
       g43, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g43_food_offerings.png\n\n")

# ===== SUMMARY =====
cat("======================================================================\n")
cat("ANALYSIS COMPLETE\n")
cat("======================================================================\n\n")
cat("Generated Visualizations:\n")
cat("  G2 Family (Geographic): 3 graphs\n")
cat("  G3 Family (Pricing): 3 graphs\n")
cat("  G4 Family (Segmentation): 3 graphs\n")
cat(sprintf("  Total: 9 visualizations in %s\n\n", PRINTS_FOLDER))

cat("Key Insights:\n")
cat(sprintf("  - %d total cafes analyzed\n", nrow(cafes)))
cat(sprintf("  - %d Square One Coffee locations\n", nrow(soc)))
cat(sprintf("  - %d competitor cafes\n", nrow(competitors)))

soc_price_mean <- soc %>% pull(avg_beverage_price) %>% mean(na.rm = TRUE)
comp_price_mean <- competitors %>% pull(avg_beverage_price) %>% mean(na.rm = TRUE)
soc_rating_mean <- soc %>% pull(google_rating) %>% mean(na.rm = TRUE)
comp_rating_mean <- competitors %>% pull(google_rating) %>% mean(na.rm = TRUE)

cat(sprintf("  - SOC avg price: $%.2f vs Competitors: $%.2f\n", soc_price_mean, comp_price_mean))
cat(sprintf("  - SOC avg rating: %.2f vs Competitors: %.2f\n", soc_rating_mean, comp_rating_mean))
cat("\n✅ Market overview analysis complete!\n")
cat("======================================================================\n")

# ---- session-info ------------------------------------------------------------
cat("\n## Session Information\n\n")
if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::session_info()
} else {
  sessionInfo()
}
