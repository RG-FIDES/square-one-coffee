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

# ---- load-sources ------------------------------------------------------------
source("./scripts/common-functions.R")
source("./scripts/operational-functions.R")
source("./scripts/graphing/graph-presets.R")

# ---- declare-globals ---------------------------------------------------------
local_root <- "./analysis/eda-2/"
local_data <- paste0(local_root, "data-local/")
prints_folder <- paste0(local_root, "prints/")
data_private_derived <- "./data-private/derived/eda-2/"

# Idempotent directory creation
if (!fs::dir_exists(local_data)) {fs::dir_create(local_data)}
if (!fs::dir_exists(prints_folder)) {fs::dir_create(prints_folder)}
if (!fs::dir_exists(data_private_derived)) {fs::dir_create(data_private_derived)}

# ---- declare-functions -------------------------------------------------------
# Analysis-specific functions (if needed)

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
# Connect to SQLite database
con <- dbConnect(SQLite(), "./data-private/derived/global-data.sqlite")

# Load primary analysis table
ds0 <- dbReadTable(con, "ellis_6_cafes_with_demographics")

# Disconnect
dbDisconnect(con)

message("📊 Data loaded:")
message("  - ds0 (original): ", nrow(ds0), " observations")

# ---- inspect-data-0 ----------------------------------------------------------
# Initial data inspection
ds0 %>% glimpse()
ds0 %>% head(10) %>% print_all()
ds0 %>% summary()

# Check for missing neighborhoods
missing_neighborhoods <- ds0 %>% 
  filter(is.na(neighborhood)) %>%
  nrow()
message("Cafes with missing neighborhoods: ", missing_neighborhoods)

# ---- tweak-data-0 ------------------------------------------------------------
# Filter out cafes with missing neighborhoods for clean analysis
ds0_clean <- ds0 %>%
  filter(!is.na(neighborhood))

message("  - ds0_clean (filtered): ", nrow(ds0_clean), " observations")

# ---- g1-data-prep ------------------------------------------------------------
# Neighborhood-level aggregation for undersaturation analysis
ds_neighborhood <- ds0_clean %>%
  group_by(neighborhood) %>%
  summarize(
    cafe_count = n(),
    population = first(population),
    area = first(area),
    density = first(density_of_population),
    .groups = "drop"
  ) %>%
  mutate(
    # Calculate service metrics
    cafes_per_1000 = (cafe_count / population) * 1000,
    people_per_cafe = population / cafe_count,
    area_per_cafe = area / cafe_count
  ) %>%
  arrange(desc(people_per_cafe))

message("  - ds_neighborhood: ", nrow(ds_neighborhood), " neighborhoods")

# Save intermediate dataset
saveRDS(ds_neighborhood, paste0(local_data, "ds_neighborhood.rds"))

# ---- inspect-data-1 ----------------------------------------------------------
# Examine neighborhood aggregation
ds_neighborhood %>% glimpse()
ds_neighborhood %>% head(20) %>% print_all()

# Summary statistics for service metrics
ds_neighborhood %>%
  summarize(
    mean_people_per_cafe = mean(people_per_cafe, na.rm = TRUE),
    median_people_per_cafe = median(people_per_cafe, na.rm = TRUE),
    sd_people_per_cafe = sd(people_per_cafe, na.rm = TRUE),
    min_people_per_cafe = min(people_per_cafe, na.rm = TRUE),
    max_people_per_cafe = max(people_per_cafe, na.rm = TRUE)
  ) %>%
  print()

# ---- g2-data-prep ------------------------------------------------------------
# Add density categories for comparative analysis
ds_neighborhood_categorized <- ds_neighborhood %>%
  mutate(
    density_category = case_when(
      density < 2000 ~ "Low",
      density < 5000 ~ "Moderate",
      density < 10000 ~ "High",
      TRUE ~ "Very High"
    ),
    density_category = factor(density_category, 
                              levels = c("Low", "Moderate", "High", "Very High"))
  )

# Save categorized dataset
saveRDS(ds_neighborhood_categorized, paste0(local_data, "ds_neighborhood_categorized.rds"))

# ---- g1 ----------------------------------------------------------------------
# Scatter plot: Population vs Cafe Count by neighborhood
g1_population_vs_cafes <- ds_neighborhood %>%
  ggplot(aes(x = population, y = cafe_count)) +
  geom_point(alpha = 0.6, size = 3, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick", linewidth = 1) +
  labs(
    title = "Cafe Count vs. Population by Neighborhood",
    subtitle = "Linear relationship suggests population drives cafe presence",
    x = "Neighborhood Population",
    y = "Number of Cafes",
    caption = "Source: Ellis-6 (cafes with demographics)"
  ) +
  scale_x_continuous(labels = comma) +
  theme_minimal()

ggsave(paste0(prints_folder, "g1_population_vs_cafes.png"), 
       g1_population_vs_cafes, width = 8.5, height = 5.5, dpi = 300)

print(g1_population_vs_cafes)
# ---- g11 ---------------------------------------------------------------------
# Same scatter, colored by density category
g11_population_vs_cafes_density <- ds_neighborhood_categorized %>%
  ggplot(aes(x = population, y = cafe_count, color = density_category)) +
  geom_point(alpha = 0.7, size = 3) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.8) +
  scale_color_manual(values = c("Low" = "forestgreen", 
                                "Moderate" = "steelblue",
                                "High" = "darkorange",
                                "Very High" = "firebrick")) +
  labs(
    title = "Cafe Count vs. Population by Neighborhood",
    subtitle = "Colored by population density category",
    x = "Neighborhood Population",
    y = "Number of Cafes",
    color = "Density",
    caption = "Source: Ellis-6 (cafes with demographics)"
  ) +
  scale_x_continuous(labels = comma) +
  theme_minimal()

ggsave(paste0(prints_folder, "g11_population_vs_cafes_density.png"), 
       g11_population_vs_cafes_density, width = 8.5, height = 5.5, dpi = 300)

print(g11_population_vs_cafes_density)

# ---- g2 ----------------------------------------------------------------------
# Bar chart: Average cafes per 1000 people by density category
g2_data <- ds_neighborhood_categorized %>%
  group_by(density_category) %>%
  summarize(
    mean_cafes_per_1000 = mean(cafes_per_1000, na.rm = TRUE),
    n_neighborhoods = n(),
    .groups = "drop"
  )

g2_cafes_by_density <- g2_data %>%
  ggplot(aes(x = density_category, y = mean_cafes_per_1000, fill = density_category)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = round(mean_cafes_per_1000, 2)), 
            vjust = -0.3, size = 3.5) +
  scale_fill_manual(values = c("Low" = "forestgreen", 
                               "Moderate" = "steelblue",
                               "High" = "darkorange",
                               "Very High" = "firebrick")) +
  labs(
    title = "Average Cafe Coverage by Population Density",
    subtitle = "Cafes per 1,000 residents across density categories",
    x = "Population Density Category",
    y = "Cafes per 1,000 People",
    caption = "Source: Ellis-6 (cafes with demographics)"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(paste0(prints_folder, "g2_cafes_by_density.png"), 
       g2_cafes_by_density, width = 8.5, height = 5.5, dpi = 300)

print(g2_cafes_by_density)

# ---- g21 ---------------------------------------------------------------------
# Horizontal bar chart: Top 20 most underserved neighborhoods
g21_underserved_top20 <- ds_neighborhood %>%
  arrange(desc(people_per_cafe)) %>%
  head(20) %>%
  mutate(neighborhood = fct_reorder(neighborhood, people_per_cafe)) %>%
  ggplot(aes(x = people_per_cafe, y = neighborhood)) +
  geom_col(fill = "firebrick", alpha = 0.8) +
  geom_text(aes(label = comma(round(people_per_cafe, 0))), 
            hjust = -0.1, size = 3) +
  labs(
    title = "Top 20 Most Underserved Neighborhoods",
    subtitle = "Ranked by people per cafe (higher = more underserved)",
    x = "People per Cafe",
    y = NULL,
    caption = "Source: Ellis-6 (cafes with demographics)"
  ) +
  scale_x_continuous(labels = comma, expand = expansion(mult = c(0, 0.15))) +
  theme_minimal()

ggsave(paste0(prints_folder, "g21_underserved_top20.png"), 
       g21_underserved_top20, width = 8.5, height = 5.5, dpi = 300)

print(g21_underserved_top20)

# ---- g22 ---------------------------------------------------------------------
# Top 20 best served neighborhoods (lowest people per cafe)
g22_wellserved_top20 <- ds_neighborhood %>%
  arrange(people_per_cafe) %>%
  head(20) %>%
  mutate(neighborhood = fct_reorder(neighborhood, -people_per_cafe)) %>%
  ggplot(aes(x = people_per_cafe, y = neighborhood)) +
  geom_col(fill = "forestgreen", alpha = 0.8) +
  geom_text(aes(label = comma(round(people_per_cafe, 0))), 
            hjust = -0.1, size = 3) +
  labs(
    title = "Top 20 Best Served Neighborhoods",
    subtitle = "Ranked by people per cafe (lower = better served)",
    x = "People per Cafe",
    y = NULL,
    caption = "Source: Ellis-6 (cafes with demographics)"
  ) +
  scale_x_continuous(labels = comma, expand = expansion(mult = c(0, 0.15))) +
  theme_minimal()

ggsave(paste0(prints_folder, "g22_wellserved_top20.png"), 
       g22_wellserved_top20, width = 8.5, height = 5.5, dpi = 300)

print(g22_wellserved_top20)

# ---- g3 ----------------------------------------------------------------------
# Histogram: Distribution of people per cafe across all neighborhoods
g3_distribution <- ds_neighborhood %>%
  ggplot(aes(x = people_per_cafe)) +
  geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7, color = "white") +
  geom_vline(aes(xintercept = mean(people_per_cafe, na.rm = TRUE)),
             color = "firebrick", linetype = "dashed", linewidth = 1) +
  geom_vline(aes(xintercept = median(people_per_cafe, na.rm = TRUE)),
             color = "darkorange", linetype = "dashed", linewidth = 1) +
  labs(
    title = "Distribution of Cafe Service Coverage",
    subtitle = "People per cafe across Edmonton neighborhoods (red=mean, orange=median)",
    x = "People per Cafe",
    y = "Number of Neighborhoods",
    caption = "Source: Ellis-6 (cafes with demographics)"
  ) +
  scale_x_continuous(labels = comma) +
  theme_minimal()

ggsave(paste0(prints_folder, "g3_distribution.png"), 
       g3_distribution, width = 8.5, height = 5.5, dpi = 300)

print(g3_distribution)

# ---- g31 ---------------------------------------------------------------------
# Boxplot: People per cafe by density category
g31_boxplot_density <- ds_neighborhood_categorized %>%
  ggplot(aes(x = density_category, y = people_per_cafe, fill = density_category)) +
  geom_boxplot(alpha = 0.7, outlier.shape = 16, outlier.size = 2) +
  scale_fill_manual(values = c("Low" = "forestgreen", 
                               "Moderate" = "steelblue",
                               "High" = "darkorange",
                               "Very High" = "firebrick")) +
  labs(
    title = "Cafe Service Coverage by Population Density",
    subtitle = "Distribution of people per cafe across density categories",
    x = "Population Density Category",
    y = "People per Cafe",
    caption = "Source: Ellis-6 (cafes with demographics)"
  ) +
  scale_y_continuous(labels = comma) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(paste0(prints_folder, "g31_boxplot_density.png"), 
       g31_boxplot_density, width = 8.5, height = 5.5, dpi = 300)

print(g31_boxplot_density)

# ---- t1-correlation ----------------------------------------------------------
# Correlation analysis: Population density vs cafes per capita
correlation_result <- ds_neighborhood %>%
  summarize(
    correlation = cor(density, cafes_per_1000, use = "complete.obs"),
    n = n()
  )

message("\n📊 Correlation Analysis:")
message("  Population Density vs Cafes per 1,000: ", 
        round(correlation_result$correlation, 3))

# ---- t2-anova ----------------------------------------------------------------
# ANOVA: Test if cafe coverage differs across density categories
anova_model <- aov(cafes_per_1000 ~ density_category, 
                   data = ds_neighborhood_categorized)
anova_summary <- summary(anova_model)

message("\n📊 ANOVA Results:")
print(anova_summary)

# Post-hoc pairwise comparisons
tukey_result <- TukeyHSD(anova_model)
message("\n📊 Tukey HSD Post-Hoc:")
print(tukey_result)

# ---- t3-outliers -------------------------------------------------------------
# Identify statistically underserved neighborhoods (>2 SD above mean)
undersaturation_threshold <- ds_neighborhood %>%
  summarize(
    mean_ppc = mean(people_per_cafe, na.rm = TRUE),
    sd_ppc = sd(people_per_cafe, na.rm = TRUE),
    threshold = mean_ppc + (2 * sd_ppc)
  )

statistically_underserved <- ds_neighborhood %>%
  filter(people_per_cafe > undersaturation_threshold$threshold) %>%
  arrange(desc(people_per_cafe))

message("\n🚨 Statistically Underserved Neighborhoods (>2 SD):")
message("  Threshold: ", round(undersaturation_threshold$threshold, 0), " people per cafe")
message("  Count: ", nrow(statistically_underserved), " neighborhoods")

statistically_underserved %>%
  select(neighborhood, population, cafe_count, people_per_cafe) %>%
  print_all()

# Save results
saveRDS(statistically_underserved, paste0(data_private_derived, "underserved_neighborhoods.rds"))
write.csv(statistically_underserved, 
          paste0(data_private_derived, "underserved_neighborhoods.csv"), 
          row.names = FALSE)
