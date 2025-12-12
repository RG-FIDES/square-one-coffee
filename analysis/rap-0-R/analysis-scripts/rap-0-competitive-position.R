#' ---
#' title: "RAP-0 Competitive Positioning Analysis (R/ggplot2 Version)"
#' author: "Research Team"
#' date: "Last Updated: `r Sys.Date()`"
#' ---

#' RAP-0 Competitive Positioning Analysis
#' 
#' Analyzes Square One Coffee's positioning relative to competitors across key dimensions:
#' - Market positioning comparison (g5 family)
#' - Quality and reputation analysis (g6 family)
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
cat("RAP-0 COMPETITIVE POSITIONING ANALYSIS (R/ggplot2)\n")
cat("======================================================================\n")
cat("Square One Coffee vs Edmonton Market\n\n")

# Define color palette
soc_color <- "#E63946"
competitor_color <- "#457B9D"

# ---- load-data ---------------------------------------------------------------
cat("\n## Loading Data\n")

conn <- dbConnect(RSQLite::SQLite(), DB_PATH)

cafes <- dbReadTable(conn, "cafes_complete") %>% as_tibble()
soc <- dbReadTable(conn, "soc_locations") %>% as_tibble()
competitors <- dbReadTable(conn, "competitors") %>% as_tibble()

dbDisconnect(conn)

cat(sprintf("✓ Loaded %d cafes (%d SOC + %d competitors)\n\n", 
            nrow(cafes), nrow(soc), nrow(competitors)))

# ===== G5 FAMILY: MARKET POSITIONING COMPARISON =====
cat("## G5 Family: Market Positioning Comparison\n")
cat("   Question: How does SOC position relative to competitors?\n\n")

# ---- g5-data-prep ------------------------------------------------------------
cat("### g5-data-prep: Preparing positioning metrics\n")

g5_data <- cafes %>%
  mutate(
    business_type = if_else(
      str_detect(name, regex("Square One", ignore_case = TRUE)),
      "Square One Coffee",
      "Competitors"
    )
  )

# Calculate key metrics by type
positioning_metrics <- g5_data %>%
  group_by(business_type) %>%
  summarise(
    avg_beverage_price = mean(avg_beverage_price, na.rm = TRUE),
    google_rating = mean(google_rating, na.rm = TRUE),
    review_count = mean(review_count, na.rm = TRUE),
    quality_score = mean(quality_score, na.rm = TRUE),
    seating_capacity = mean(seating_capacity, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

cat("✓ Positioning metrics calculated\n")
print(positioning_metrics)
cat("\n")

# ---- g51 ---------------------------------------------------------------------
cat("\n### g51: Key metrics comparison\n")

# Prepare normalized data for comparison
metrics_long <- positioning_metrics %>%
  select(business_type, avg_beverage_price, google_rating, quality_score, seating_capacity) %>%
  pivot_longer(-business_type, names_to = "metric", values_to = "value") %>%
  group_by(metric) %>%
  mutate(
    normalized = (value - min(value)) / (max(value) - min(value)) * 100
  ) %>%
  ungroup() %>%
  mutate(
    metric_label = case_when(
      metric == "avg_beverage_price" ~ "Avg Price",
      metric == "google_rating" ~ "Rating",
      metric == "quality_score" ~ "Quality Score",
      metric == "seating_capacity" ~ "Seating",
      TRUE ~ metric
    ),
    metric_label = factor(metric_label, 
                         levels = c("Avg Price", "Rating", "Quality Score", "Seating"))
  )

g51 <- ggplot(metrics_long, aes(x = metric_label, y = normalized, fill = business_type)) +
  geom_col(position = "dodge", width = 0.7, color = "black") +
  geom_text(
    aes(label = sprintf("%.0f", normalized)),
    position = position_dodge(width = 0.7),
    vjust = -0.5,
    size = 3
  ) +
  scale_fill_manual(
    values = c("Competitors" = competitor_color, "Square One Coffee" = soc_color)
  ) +
  labs(
    title = "SOC vs Market: Key Performance Metrics",
    x = "Performance Dimension",
    y = "Normalized Score (0-100)",
    fill = NULL
  ) +
  coord_cartesian(ylim = c(0, 105)) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave(paste0(PRINTS_FOLDER, "g51_metrics_comparison.png"), 
       g51, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g51_metrics_comparison.png\n")

# ---- g52 ---------------------------------------------------------------------
cat("\n### g52: Price-Quality positioning matrix\n")

# Calculate market averages for quadrant lines
avg_price <- mean(g5_data$avg_beverage_price, na.rm = TRUE)
avg_rating <- mean(g5_data$google_rating, na.rm = TRUE)

g52 <- ggplot(g5_data, aes(x = avg_beverage_price, y = google_rating, 
                          color = business_type, shape = business_type, size = business_type)) +
  geom_vline(xintercept = avg_price, color = "gray", linetype = "dashed", alpha = 0.5, linewidth = 1) +
  geom_hline(yintercept = avg_rating, color = "gray", linetype = "dashed", alpha = 0.5, linewidth = 1) +
  geom_point(alpha = 0.7) +
  annotate(
    "text", x = avg_price - 1.5, y = avg_rating + 0.35,
    label = "High Quality\nLower Price",
    hjust = 0.5, vjust = 0.5, size = 3, color = "gray30", fontface = "italic"
  ) +
  annotate(
    "text", x = avg_price + 1.5, y = avg_rating + 0.35,
    label = "High Quality\nHigher Price",
    hjust = 0.5, vjust = 0.5, size = 3, color = "gray30", fontface = "italic"
  ) +
  scale_color_manual(
    values = c("Competitors" = competitor_color, "Square One Coffee" = soc_color)
  ) +
  scale_shape_manual(
    values = c("Competitors" = 16, "Square One Coffee" = 18)
  ) +
  scale_size_manual(
    values = c("Competitors" = 3, "Square One Coffee" = 5)
  ) +
  labs(
    title = "Competitive Positioning: Price vs Quality",
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

ggsave(paste0(PRINTS_FOLDER, "g52_positioning_matrix.png"), 
       g52, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g52_positioning_matrix.png\n")

# ---- g53 ---------------------------------------------------------------------
cat("\n### g53: Market share by location zones\n")

zone_share <- g5_data %>%
  filter(!is.na(location_zone)) %>%
  mutate(
    location_zone = factor(location_zone, 
                          levels = c("core", "inner", "outer", "peripheral"))
  ) %>%
  count(location_zone, business_type) %>%
  group_by(location_zone) %>%
  mutate(
    percentage = n / sum(n) * 100
  ) %>%
  ungroup()

g53 <- ggplot(zone_share, aes(x = location_zone, y = percentage, fill = business_type)) +
  geom_col(position = "stack", width = 0.6) +
  scale_fill_manual(
    values = c("Competitors" = competitor_color, "Square One Coffee" = soc_color)
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
    title = "SOC Market Presence by Location Zone",
    x = "Location Zone",
    y = "Market Share (%)",
    fill = NULL
  ) +
  coord_cartesian(ylim = c(0, 100)) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave(paste0(PRINTS_FOLDER, "g53_market_share_zones.png"), 
       g53, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g53_market_share_zones.png\n\n")

# ===== G6 FAMILY: QUALITY & REPUTATION ANALYSIS =====
cat("## G6 Family: Quality & Reputation Analysis\n")
cat("   Question: How does SOC's reputation compare?\n\n")

# ---- g6-data-prep ------------------------------------------------------------
cat("### g6-data-prep: Preparing quality metrics\n")

g6_data <- g5_data

cat(sprintf("✓ Quality data prepared: %d cafes\n", nrow(g6_data)))

# ---- g61 ---------------------------------------------------------------------
cat("\n### g61: Rating distribution comparison\n")

# Prepare summary statistics for boxplot
rating_stats <- g6_data %>%
  filter(!is.na(google_rating)) %>%
  group_by(business_type) %>%
  summarise(
    mean_rating = mean(google_rating, na.rm = TRUE),
    median_rating = median(google_rating, na.rm = TRUE),
    .groups = "drop"
  )

g61 <- ggplot(g6_data %>% filter(!is.na(google_rating)), 
              aes(x = business_type, y = google_rating, fill = business_type)) +
  geom_boxplot(alpha = 0.7, outlier.shape = 16, outlier.size = 2) +
  geom_point(
    data = rating_stats,
    aes(y = mean_rating),
    shape = 18, size = 5, color = "gold",
    stroke = 1.5
  ) +
  scale_fill_manual(
    values = c("Competitors" = competitor_color, "Square One Coffee" = soc_color)
  ) +
  labs(
    title = "Rating Distribution: SOC vs Competitors",
    subtitle = "Diamond markers show mean ratings",
    x = NULL,
    y = "Google Rating (1-5)",
    fill = NULL
  ) +
  coord_cartesian(ylim = c(3.3, 5.1)) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave(paste0(PRINTS_FOLDER, "g61_rating_distribution.png"), 
       g61, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g61_rating_distribution.png\n")

# ---- g62 ---------------------------------------------------------------------
cat("\n### g62: Quality score comparison\n")

g62 <- ggplot(g6_data %>% filter(!is.na(quality_score)), 
              aes(x = google_rating, y = quality_score, 
                  color = business_type, size = review_count)) +
  geom_point(alpha = 0.6) +
  scale_color_manual(
    values = c("Competitors" = competitor_color, "Square One Coffee" = soc_color)
  ) +
  scale_size_continuous(
    range = c(2, 8),
    name = "Review Count"
  ) +
  labs(
    title = "Quality Score Analysis",
    subtitle = "Bubble size represents review volume",
    x = "Google Rating (1-5)",
    y = "Quality Score (rating × log(reviews+1))",
    color = NULL
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    panel.grid = element_line(alpha = 0.3)
  ) +
  guides(
    color = guide_legend(override.aes = list(size = 4)),
    size = guide_legend(nrow = 1)
  )

ggsave(paste0(PRINTS_FOLDER, "g62_quality_score.png"), 
       g62, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g62_quality_score.png\n")

# ---- g63 ---------------------------------------------------------------------
cat("\n### g63: Reputation strength (reviews vs rating)\n")

# Calculate averages
reputation_summary <- g6_data %>%
  filter(!is.na(google_rating) & !is.na(review_count)) %>%
  group_by(business_type) %>%
  summarise(
    avg_reviews = mean(review_count, na.rm = TRUE),
    avg_rating = mean(google_rating, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_longer(-business_type, names_to = "metric", values_to = "value") %>%
  mutate(
    # Normalize review count to similar scale as rating for visualization
    normalized_value = if_else(
      metric == "avg_reviews",
      value / max(value[metric == "avg_reviews"]) * 5,
      value
    ),
    metric_label = if_else(
      metric == "avg_reviews",
      sprintf("Review Volume\n(avg: %.0f)", value),
      sprintf("Customer Rating\n(avg: %.2f)", value)
    )
  )

g63 <- ggplot(reputation_summary, aes(x = metric_label, y = normalized_value, fill = business_type)) +
  geom_col(position = "dodge", width = 0.7, color = "black") +
  geom_text(
    aes(label = if_else(
      str_detect(metric_label, "Volume"),
      sprintf("%.0f", value),
      sprintf("%.2f", value)
    )),
    position = position_dodge(width = 0.7),
    vjust = -0.5,
    fontface = "bold",
    size = 4
  ) +
  scale_fill_manual(
    values = c("Competitors" = competitor_color, "Square One Coffee" = soc_color)
  ) +
  labs(
    title = "Reputation Strength Comparison",
    subtitle = "Values scaled for visual comparison",
    x = NULL,
    y = "Normalized Score",
    fill = NULL
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text.y = element_blank()
  )

ggsave(paste0(PRINTS_FOLDER, "g63_reputation_strength.png"), 
       g63, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = FIG_DPI)
cat("✓ Saved: g63_reputation_strength.png\n\n")

# ===== SUMMARY =====
cat("======================================================================\n")
cat("COMPETITIVE ANALYSIS COMPLETE\n")
cat("======================================================================\n\n")
cat("Generated Visualizations:\n")
cat("  G5 Family (Positioning): 3 graphs\n")
cat("  G6 Family (Quality/Reputation): 3 graphs\n")
cat(sprintf("  Total: 6 visualizations in %s\n\n", PRINTS_FOLDER))

cat("Key Competitive Insights:\n\n")
cat("Square One Coffee:\n")
cat(sprintf("  - Locations: %d\n", nrow(soc)))
cat(sprintf("  - Avg Price: $%.2f\n", mean(soc$avg_beverage_price, na.rm = TRUE)))
cat(sprintf("  - Avg Rating: %.2f\n", mean(soc$google_rating, na.rm = TRUE)))
cat(sprintf("  - Avg Reviews: %.0f\n", mean(soc$review_count, na.rm = TRUE)))
cat(sprintf("  - Quality Score: %.2f\n", mean(soc$quality_score, na.rm = TRUE)))

cat("\nCompetitor Average:\n")
cat(sprintf("  - Count: %d\n", nrow(competitors)))
cat(sprintf("  - Avg Price: $%.2f\n", mean(competitors$avg_beverage_price, na.rm = TRUE)))
cat(sprintf("  - Avg Rating: %.2f\n", mean(competitors$google_rating, na.rm = TRUE)))
cat(sprintf("  - Avg Reviews: %.0f\n", mean(competitors$review_count, na.rm = TRUE)))
cat(sprintf("  - Quality Score: %.2f\n", mean(competitors$quality_score, na.rm = TRUE)))

price_diff <- mean(soc$avg_beverage_price, na.rm = TRUE) - 
              mean(competitors$avg_beverage_price, na.rm = TRUE)
rating_diff <- mean(soc$google_rating, na.rm = TRUE) - 
               mean(competitors$google_rating, na.rm = TRUE)
quality_diff <- mean(soc$quality_score, na.rm = TRUE) - 
                mean(competitors$quality_score, na.rm = TRUE)

cat("\nCompetitive Advantages:\n")
cat(sprintf("  - Price positioning: $%+.2f vs competitors\n", price_diff))
cat(sprintf("  - Rating advantage: %+.2f points\n", rating_diff))
cat(sprintf("  - Quality score advantage: %+.2f\n", quality_diff))

cat("\n✅ Competitive positioning analysis complete!\n")
cat("======================================================================\n")

# ---- session-info ------------------------------------------------------------
cat("\n## Session Information\n\n")
if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::session_info()
} else {
  sessionInfo()
}
