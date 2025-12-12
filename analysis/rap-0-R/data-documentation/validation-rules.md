# RAP-0 Data Validation Rules

**Project**: Square One Coffee Competition Intelligence  
**Version**: 1.0.0  
**Last Updated**: 2025-12-12  

---

## Overview

This document defines the validation rules applied during the ferry process to ensure data quality and consistency. Rules are categorized by severity: ERROR (stops processing), WARNING (flags but continues), INFO (logs only).

---

## Validation Levels

| Level | Symbol | Meaning | Action |
|-------|--------|---------|--------|
| **ERROR** | ❌ | Critical failure | Stop processing, fix issue |
| **WARNING** | ⚠️ | Quality concern | Flag record, log, continue |
| **INFO** | ℹ️ | Informational | Log only, no action |

---

## Core Validation Rules

### 1. Required Fields (ERROR Level)

**Rule**: Critical fields must not be NULL/NA

| Field | Severity | Reason |
|-------|----------|--------|
| `cafe_id` | ❌ ERROR | Primary key, must be unique and present |
| `name` | ❌ ERROR | Business identification impossible without name |
| `neighborhood` | ❌ ERROR | Geographic analysis requires location |
| `cafe_type` | ❌ ERROR | Market segmentation requires classification |

**Implementation**:
```r
# Check for NULL/NA in required fields
required_fields <- c("cafe_id", "name", "neighborhood", "cafe_type")
validation_errors <- ds %>%
  filter(if_any(all_of(required_fields), is.na)) %>%
  mutate(error_type = "missing_required_field")

if(nrow(validation_errors) > 0) {
  stop("VALIDATION ERROR: Required fields contain NULL values. See logs for details.")
}
```

---

### 2. Geographic Validation (WARNING Level)

**Rule**: Coordinates must be within reasonable Edmonton bounds

**Edmonton Approximate Boundaries**:
- **Latitude**: 53.40 ≤ lat ≤ 53.70 (±0.3 degrees = ~33 km)
- **Longitude**: -113.70 ≤ lng ≤ -113.30 (±0.4 degrees = ~33 km)

**Rationale**: Coordinates outside these bounds are likely:
- Data entry errors
- Geocoding failures
- Locations outside our market scope

**Severity**: ⚠️ WARNING (not ERROR because some suburban locations may be slightly outside)

**Implementation**:
```r
# Flag out-of-bounds coordinates
ds <- ds %>%
  mutate(
    flag_lat_out_of_bounds = !is.na(latitude) & (latitude < 53.40 | latitude > 53.70),
    flag_lng_out_of_bounds = !is.na(longitude) & (longitude < -113.70 | longitude > -113.30),
    flag_location_issue = flag_lat_out_of_bounds | flag_lng_out_of_bounds
  )

# Log warnings
location_warnings <- ds %>% filter(flag_location_issue)
if(nrow(location_warnings) > 0) {
  message("WARNING: ", nrow(location_warnings), " cafes have coordinates outside expected bounds")
}
```

---

### 3. Price Validation (WARNING Level)

**Rule**: Average beverage prices should be within reasonable range for Canadian coffee market

**Expected Range**:
- **Minimum**: $2.00 CAD (budget drip coffee)
- **Maximum**: $10.00 CAD (premium specialty drinks)

**Typical Range**: $3.50 - $6.50 (80% of market)

**Exceptions**:
- Prices < $2.00: May be promotions, food-truck discounts, or data errors
- Prices > $10.00: May be specialty drinks (pour-over single origins), alcohol-infused drinks, or errors

**Severity**: ⚠️ WARNING

**Implementation**:
```r
ds <- ds %>%
  mutate(
    flag_price_too_low = !is.na(avg_beverage_price) & avg_beverage_price < 2.00,
    flag_price_too_high = !is.na(avg_beverage_price) & avg_beverage_price > 10.00,
    flag_price_suspicious = flag_price_too_low | flag_price_too_high
  )

price_warnings <- ds %>% filter(flag_price_suspicious)
if(nrow(price_warnings) > 0) {
  message("WARNING: ", nrow(price_warnings), " cafes have prices outside typical range ($2-$10)")
}
```

---

### 4. Rating Validation (WARNING Level)

**Rule**: Google ratings must be on 1-5 scale

**Expected Values**:
- **Range**: 1.0 ≤ rating ≤ 5.0
- **NULL/NA**: Acceptable (new cafes may have no ratings yet)
- **Precision**: Typically one decimal place (e.g., 4.3)

**Invalid Values**: <1.0, >5.0, or non-numeric

**Severity**: ⚠️ WARNING

**Action on Invalid**: Set to NA, flag for review

**Implementation**:
```r
ds <- ds %>%
  mutate(
    flag_invalid_rating = !is.na(google_rating) & (google_rating < 1.0 | google_rating > 5.0),
    google_rating = ifelse(flag_invalid_rating, NA, google_rating)
  )

rating_warnings <- ds %>% filter(flag_invalid_rating)
if(nrow(rating_warnings) > 0) {
  message("WARNING: ", nrow(rating_warnings), " cafes had invalid ratings (set to NA)")
}
```

---

### 5. Review Count Validation (WARNING Level)

**Rule**: Review counts must be non-negative integers

**Expected Values**:
- **Range**: 0 ≤ review_count < 10,000 (realistically)
- **NULL/NA**: Acceptable (no reviews yet)
- **Typical Range**: 20-500 for established cafes

**Suspicious Values**: >1000 (possible for chains or very popular spots, but rare)

**Severity**: ⚠️ WARNING

**Implementation**:
```r
ds <- ds %>%
  mutate(
    flag_negative_reviews = !is.na(review_count) & review_count < 0,
    flag_excessive_reviews = !is.na(review_count) & review_count > 1000,
    review_count = ifelse(flag_negative_reviews, NA, review_count)  # Fix obviously invalid
  )
```

---

### 6. Completeness Validation (INFO Level)

**Rule**: Track completeness rates for optional fields

**Key Optional Fields**:
- `phone`: 70-90% complete expected
- `website`: 60-80% complete expected (many small cafes lack websites)
- `seating_capacity`: 60-80% complete expected (estimated data)
- `date_opened`: 50-70% complete expected (historical data often unavailable)
- `instagram_handle`: 70-85% complete expected (primary social platform for cafes)

**Severity**: ℹ️ INFO

**Action**: Log completeness rates for monitoring

**Implementation**:
```r
completeness_summary <- data.frame(
  field = colnames(ds),
  complete_rate = sapply(ds, function(x) sum(!is.na(x)) / length(x)),
  missing_count = sapply(ds, function(x) sum(is.na(x))),
  complete_count = sapply(ds, function(x) sum(!is.na(x)))
) %>%
  arrange(complete_rate)

message("COMPLETENESS SUMMARY:")
print(completeness_summary)
```

---

### 7. Uniqueness Validation (ERROR Level)

**Rule**: Primary keys must be unique

**Fields**:
- `cafe_id`: Must be unique across all records

**Severity**: ❌ ERROR (data corruption if violated)

**Implementation**:
```r
# Check for duplicate cafe_ids
duplicates <- ds %>%
  group_by(cafe_id) %>%
  filter(n() > 1) %>%
  ungroup()

if(nrow(duplicates) > 0) {
  stop("VALIDATION ERROR: Duplicate cafe_ids detected: ", 
       paste(unique(duplicates$cafe_id), collapse = ", "))
}
```

---

### 8. Referential Integrity (WARNING Level)

**Rule**: Categorical fields should use standardized values

**Standardized Categories**:

**cafe_type**:
- `specialty_coffee`
- `espresso_bar`
- `full_service_cafe`
- `coffee_shop`
- `roastery_cafe`

**ownership**:
- `independent`
- `small_chain` (2-5 locations)
- `regional_chain` (6-20 locations)
- `national_chain` (20+ locations)

**has_food**:
- `none`
- `pastries_only`
- `sandwiches_pastries`
- `full_menu`

**Severity**: ⚠️ WARNING (new categories may emerge)

**Implementation**:
```r
expected_cafe_types <- c("specialty_coffee", "espresso_bar", "full_service_cafe", 
                        "coffee_shop", "roastery_cafe")
unexpected_types <- ds %>%
  filter(!cafe_type %in% expected_cafe_types) %>%
  distinct(cafe_type)

if(nrow(unexpected_types) > 0) {
  message("WARNING: Unexpected cafe_type values: ", 
          paste(unexpected_types$cafe_type, collapse = ", "))
}
```

---

## Data Quality Scoring

**Quality Score Formula**:
```r
quality_score <- ds %>%
  mutate(
    # Count how many quality issues each record has
    quality_flags = (
      flag_location_issue + 
      flag_price_suspicious + 
      flag_invalid_rating +
      (is.na(latitude) | is.na(longitude)) +  # Missing location
      is.na(avg_beverage_price) +  # Missing price
      is.na(google_rating)  # Missing rating
    ),
    # Quality score: 100 - (10 points per flag)
    quality_score = pmax(0, 100 - (quality_flags * 10)),
    # Quality tier
    quality_tier = case_when(
      quality_score >= 90 ~ "excellent",
      quality_score >= 70 ~ "good",
      quality_score >= 50 ~ "acceptable",
      TRUE ~ "poor"
    )
  )
```

**Interpretation**:
- **Excellent (90-100)**: Complete data, no quality flags
- **Good (70-89)**: Minor issues or missing optional fields
- **Acceptable (50-69)**: Multiple missing fields or quality concerns
- **Poor (<50)**: Major quality issues, may need manual review

---

## Validation Reporting

**Console Output Format**:
```
===== FERRY VALIDATION REPORT =====
Input records: 30
Output records: 28
Records dropped: 2 (ERROR-level failures)

ERROR-level issues: 2
  - Missing required fields: 2 records

WARNING-level issues: 4
  - Out-of-bounds coordinates: 1 record
  - Suspicious pricing: 2 records
  - Invalid ratings: 1 record

INFO messages:
  - Average completeness: 82%
  - Low completeness fields: date_opened (45%), seating_capacity (62%)

Quality tier distribution:
  - Excellent: 18 (64%)
  - Good: 8 (29%)
  - Acceptable: 2 (7%)
  - Poor: 0 (0%)

===================================
```

---

## Validation Rule Updates

**When to Update Rules**:
1. **New data patterns emerge**: Real-world data may violate synthetic assumptions
2. **Business context changes**: Market conditions shift (e.g., inflation affects pricing)
3. **Coverage expands**: Geographic boundaries widen
4. **New data sources**: Different platforms may have different formats

**Update Process**:
1. Document reason for rule change
2. Update validation-rules.md
3. Update ferry script
4. Test on historical data
5. Version control commit with explanation

**Change Log**:
- 2025-12-12 v1.0.0: Initial validation rules defined

---

## References

- **Ferry process**: `./ferry-process.md`
- **Data sources**: `./data-sources.md`
- **Ellis-pattern example**: `../../manipulation/ellis-lane.R`
