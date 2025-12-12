# RAP-0 Ferry Process Documentation

**Project**: Square One Coffee Competition Intelligence  
**Version**: 1.0.0  
**Last Updated**: 2025-12-12  

---

## Overview

This document explains the "ferry" transformation process that converts raw competitive intelligence data into analysis-ready datasets. The ferry follows the **Ellis-pattern** established in `./manipulation/ellis-lane.R`.

**Purpose**: Create clean, validated, analysis-ready data with proper structure, quality checks, and documentation.

---

## Ellis-Pattern Philosophy

The Ellis-pattern is a standardized data transformation approach emphasizing:

1. **Clear Data Flow**: Raw → Validate → Transform → Write Derived
2. **Quality Assurance**: Explicit validation rules and quality metrics
3. **Reproducibility**: Session info, timestamps, version tracking
4. **Transparency**: Document all transformations and decisions
5. **Modularity**: Separate concerns (validation, transformation, export)

---

## Ferry Script: `ferry-to-derived.R`

**Location**: `./analysis/rap-0/data-collection/ferry-to-derived.R`

**Execution Context**:
- Called by `flow.R` orchestration script
- Runs in clean R session
- Logs session info for reproducibility

**Inputs**:
- `./data-private/raw/edmonton_cafes.sqlite` (raw cafe directory)

**Outputs**:
- `./data-private/derived/rap-0-competition-intel.sqlite` (analysis-ready database)
- Console logs (validation results, quality metrics)
- Session info (for reproducibility tracking)

---

## Transformation Steps

### 1. Data Import & Inspection

**Process**:
- Connect to raw SQLite database
- Read `cafes` table into R data frame
- Inspect structure, dimensions, data types
- Check for obvious corruption or missing critical tables

**Validation**:
- Confirm expected tables exist
- Verify minimum row count (expect 20+ cafes)
- Check required columns present

**Quality Metrics**:
- Record count
- Column completeness rates
- Data types match expectations

### 2. Data Validation

**Validation Rules** (see `validation-rules.md` for complete list):

**Geographic Bounds**:
```r
# Edmonton area approximate boundaries
latitude: 53.4 ≤ lat ≤ 53.7
longitude: -113.7 ≤ lng ≤ -113.4
```

**Price Validation**:
```r
avg_beverage_price: 2.00 ≤ price ≤ 10.00 (CAD)
```

**Rating Validation**:
```r
google_rating: 1.0 ≤ rating ≤ 5.0 (or NULL)
review_count: ≥ 0 (integer)
```

**Required Fields**:
- `cafe_id`, `name`, `neighborhood`, `cafe_type` must be non-NULL

**Actions on Validation Failure**:
- **Error** (stop processing): Missing required fields, corrupt data
- **Warning** (log and continue): Out-of-bounds coordinates, unusual prices
- **Note** (informational): High missing data rates for optional fields

### 3. Data Transformation

**3a. Standardization**

Ensure consistent formats and categories:

```r
# Standardize neighborhood names
neighborhood <- str_to_title(neighborhood) %>%
  str_trim() %>%
  # Fix common variants
  case_when(
    . %in% c("downtown", "Downtown Core") ~ "Downtown",
    . %in% c("whyte", "Whyte Ave") ~ "Whyte Avenue",
    TRUE ~ .
  )

# Standardize cafe types
cafe_type <- tolower(cafe_type) %>%
  case_when(
    . %in% c("specialty", "specialty_coffee") ~ "specialty_coffee",
    . %in% c("espresso", "espresso_bar") ~ "espresso_bar",
    TRUE ~ .
  )
```

**3b. Enrichment**

Add derived fields useful for analysis:

```r
# SOC identification flag
is_soc <- str_detect(name, regex("square one", ignore_case = TRUE))

# Price category
price_category <- case_when(
  avg_beverage_price < 3.50 ~ "budget",
  avg_beverage_price < 5.00 ~ "moderate",
  avg_beverage_price < 6.50 ~ "premium",
  TRUE ~ "luxury"
)

# Popularity score (normalized review count)
popularity_percentile <- percent_rank(review_count)

# Quality score (rating × log(review_count + 1))
quality_score <- google_rating * log(review_count + 1)
```

**3c. Geographic Processing**

Prepare spatial analysis features:

```r
# Calculate distance from downtown reference point
# Edmonton downtown reference: (53.5444, -113.4909)
downtown_lat <- 53.5444
downtown_lng <- -113.4909

distance_from_downtown <- sqrt(
  (latitude - downtown_lat)^2 + 
  (longitude - downtown_lng)^2
) * 111  # Convert to approximate km

# Location zone
location_zone <- case_when(
  distance_from_downtown < 2 ~ "core",
  distance_from_downtown < 5 ~ "inner",
  distance_from_downtown < 10 ~ "outer",
  TRUE ~ "peripheral"
)
```

### 4. Quality Metrics Calculation

**Completeness Metrics**:
```r
completeness <- data.frame(
  field = colnames(ds),
  complete_rate = colSums(!is.na(ds)) / nrow(ds),
  missing_count = colSums(is.na(ds))
)
```

**Data Quality Flags**:
```r
# Flag records with quality issues
quality_flags <- ds %>%
  mutate(
    flag_missing_location = is.na(latitude) | is.na(longitude),
    flag_no_rating = is.na(google_rating),
    flag_incomplete = rowSums(is.na(.)) > 5,
    flag_suspicious_price = avg_beverage_price < 2 | avg_beverage_price > 8
  )
```

### 5. Write to Derived Database

**Output Structure**:

The derived database contains multiple tables optimized for analysis:

**Table: `cafes_complete`**
- All fields from raw data
- Plus derived fields (is_soc, price_category, quality_score, etc.)
- Only records passing core validation

**Table: `soc_locations`**
- Subset of Square One Coffee locations only
- Quick reference for SOC-specific analyses

**Table: `competitors`**
- Non-SOC cafes only
- Used for competitive benchmarking

**Table: `quality_metrics`**
- Completeness statistics
- Validation results
- Data quality summary

**Table: `metadata`**
- Ferry execution timestamp
- Input data version/hash
- Validation rule versions
- Session info snapshot

**Write Process**:
```r
# Connect to derived database
con_derived <- DBI::dbConnect(RSQLite::SQLite(), 
                              "./data-private/derived/rap-0-competition-intel.sqlite")

# Write tables
DBI::dbWriteTable(con_derived, "cafes_complete", ds_clean, overwrite = TRUE)
DBI::dbWriteTable(con_derived, "soc_locations", ds_soc, overwrite = TRUE)
DBI::dbWriteTable(con_derived, "competitors", ds_competitors, overwrite = TRUE)
DBI::dbWriteTable(con_derived, "quality_metrics", quality_summary, overwrite = TRUE)
DBI::dbWriteTable(con_derived, "metadata", ferry_metadata, overwrite = TRUE)

# Close connection
DBI::dbDisconnect(con_derived)
```

---

## Validation Rules Reference

**Full validation rules documented in**: `./data-documentation/validation-rules.md`

**Quick Reference**:

| Validation | Severity | Action |
|-----------|----------|--------|
| Required fields NULL | ERROR | Stop processing |
| Coordinates out of Edmonton bounds | WARNING | Flag record, continue |
| Price < $2.00 or > $10.00 | WARNING | Flag record, continue |
| Rating not in [1,5] range | WARNING | Flag record, set to NA |
| Missing optional field | INFO | Log completeness rate |

---

## Quality Assurance

**Pre-Ferry Checklist**:
- [ ] Raw database exists and is readable
- [ ] Expected tables present
- [ ] Minimum row count met (≥20 cafes)

**Post-Ferry Checklist**:
- [ ] Derived database created successfully
- [ ] All expected tables present in derived DB
- [ ] Row counts reasonable (not massive data loss)
- [ ] Validation warnings reviewed and acceptable
- [ ] Quality metrics logged

**Success Criteria**:
- ≥90% of records pass core validation
- ≥80% completeness on key fields (name, location, type, pricing)
- No ERROR-level validation failures
- Derived database size reasonable (not empty, not bloated)

---

## Reproducibility Standards

**Session Info**:
Every ferry execution logs:
```r
# At end of ferry script
sessionInfo()  # or devtools::session_info()

# Capture to metadata table
ferry_metadata <- data.frame(
  ferry_date = Sys.time(),
  r_version = paste(R.version$major, R.version$minor, sep = "."),
  platform = R.version$platform,
  input_file = input_db_path,
  input_rows = nrow(ds_raw),
  output_file = output_db_path,
  output_rows = nrow(ds_clean),
  validation_errors = error_count,
  validation_warnings = warning_count
)
```

**Idempotency**:
- Ferry can be re-run multiple times on same input
- Output will be identical (except timestamps)
- Overwrites previous derived database

**Version Control**:
- Ferry script is version controlled
- Raw data is NOT version controlled (privacy)
- Derived data is NOT version controlled (generated artifact)
- Documentation IS version controlled

---

## Maintenance

**Regular Updates**:
- Ferry script rarely needs changes (stable transformation logic)
- Validation rules may be adjusted based on data quality learnings
- New derived fields added as analysis needs evolve

**When to Update Ferry**:
1. New data sources added to raw database
2. New validation rules required
3. New derived fields needed for analysis
4. Bug fixes or performance improvements

**Testing**:
- Test ferry with small synthetic dataset before running on full data
- Verify validation rules catch expected issues
- Check derived database structure matches expectations

---

## Troubleshooting

**Common Issues**:

**Issue**: Ferry fails with database connection error
**Solution**: Ensure `data-private/raw/` and `data-private/derived/` directories exist

**Issue**: Validation errors on synthetic data
**Solution**: Check data generation script matches validation rules

**Issue**: Derived database missing tables
**Solution**: Verify all `dbWriteTable()` calls executed without error

**Issue**: Massive data loss (few records in derived)
**Solution**: Review validation rules - may be too strict

---

## Change Log

**Version 1.0.0** (2025-12-12):
- Initial ferry process documentation
- Defined transformation steps
- Established validation framework
- Created derived database structure

---

## References

- **Ellis-pattern example**: `./manipulation/ellis-lane.R`
- **Validation rules**: `./data-documentation/validation-rules.md`
- **Data sources**: `./data-documentation/data-sources.md`
- **Task assignment**: `./rap-0-task-assignment.md`
