# RAP-1 Data Sources Documentation

**Project**: Square One Coffee Competition Intelligence  
**Version**: 1.0.0  
**Last Updated**: 2025-12-12  
**Maintained by**: Research Team

---

## Overview

This document catalogs all data sources used in the RAP-1 Competition Intelligence pipeline. Each source is documented with access methods, update frequency, data quality notes, and known limitations.

---

## Primary Data Sources

### 1. Edmonton Cafes Database (Raw)

**Location**: `./data-private/raw/edmonton_cafes.sqlite`

**Description**: Comprehensive directory of coffee shops and cafes in the Edmonton metropolitan area, including Square One Coffee locations and competitors.

**Data Collection Method**:
- **Current Status**: Synthetic test data generated programmatically
- **Production Plan**: 
  - Web scraping from Google Maps API
  - Manual verification of cafe websites
  - Social media monitoring (Instagram, Facebook)
  - Community coffee directories
  - Manual field verification for critical data points

**Update Frequency**: 
- **Target**: Monthly full refresh
- **Current**: Initial snapshot (2025-12-12)

**Coverage**:
- **Square One Coffee**: 6 locations (complete coverage)
- **Competitors**: 24 Edmonton-area cafes
- **Geographic Scope**: Edmonton city limits and immediate suburbs
- **Neighborhoods**: 15 major areas

**Data Fields**:

| Field | Type | Description | Completeness | Notes |
|-------|------|-------------|--------------|-------|
| `cafe_id` | INTEGER | Unique identifier | 100% | Auto-generated primary key |
| `name` | TEXT | Business name | 100% | Official business name |
| `address` | TEXT | Street address | 95% | Some locations address-less (food trucks) |
| `neighborhood` | TEXT | Edmonton neighborhood | 100% | Standardized neighborhood names |
| `latitude` | REAL | Geographic coordinate | 95% | Required for mapping |
| `longitude` | REAL | Geographic coordinate | 95% | Required for mapping |
| `phone` | TEXT | Contact phone | 80% | Not all cafes have public phone |
| `website` | TEXT | Official website URL | 70% | Many small cafes lack websites |
| `cafe_type` | TEXT | Business category | 100% | specialty_coffee, espresso_bar, etc. |
| `ownership` | TEXT | Ownership structure | 90% | independent, small_chain, etc. |
| `avg_beverage_price` | REAL | Average drink price ($CAD) | 85% | Estimated from menu data |
| `has_food` | TEXT | Food offerings | 100% | pastries_only, full_menu, etc. |
| `has_wifi` | TEXT | WiFi availability | 80% | yes, no, limited |
| `seating_capacity` | INTEGER | Approximate seats | 70% | Estimated via photos/visits |
| `ambiance` | TEXT | Atmosphere category | 85% | modern_minimalist, cozy, etc. |
| `parking_availability` | TEXT | Parking options | 75% | street_only, dedicated, etc. |
| `hours_weekday` | TEXT | Operating hours M-F | 90% | Human-readable format |
| `hours_weekend` | TEXT | Operating hours Sat-Sun | 90% | Human-readable format |
| `date_opened` | TEXT | Opening date | 60% | Year-month precision when available |
| `instagram_handle` | TEXT | Instagram username | 75% | Primary social media |
| `google_rating` | REAL | Average Google rating | 95% | 1-5 scale |
| `review_count` | INTEGER | Number of Google reviews | 95% | Popularity indicator |
| `created_at` | TEXT | Record creation timestamp | 100% | Data lineage |
| `updated_at` | TEXT | Last update timestamp | 100% | Data freshness tracking |

**Data Quality**:
- ✅ **Complete**: cafe_id, name, neighborhood, cafe_type, has_food
- ⚠️ **Partial**: seating_capacity, date_opened, parking
- ❌ **Missing**: Customer demographic data, actual transaction volumes

**Known Limitations**:
1. **Current synthetic data**: Not real market intelligence (test/development only)
2. **Completeness**: Some fields estimated or inferred (seating, ambiance)
3. **Currency**: Static snapshot, not reflecting real-time changes
4. **Scope**: Limited to major cafes; excludes home-based coffee services, pop-ups
5. **Pricing**: Average beverage price is estimated, not comprehensive menu data
6. **Validation**: No ground-truth verification yet (requires field visits)

**Validation Rules** (see `validation-rules.md`):
- All cafes must have: name, neighborhood, cafe_type
- Coordinates must be within Edmonton bounds (lat: 53.4-53.7, lng: -113.7 to -113.3)
- Prices must be positive, typically $2-$10 CAD range
- Ratings must be 1.0-5.0 if present
- Review counts must be non-negative integers

---

## Planned Future Sources (Phase 2+)

### 2. Customer Reviews (Multi-Platform)

**Target Sources**:
- Google Reviews (API or scraping)
- Yelp Reviews (API)
- Facebook Reviews (Graph API)

**Data Points**:
- Review text content
- Star ratings
- Review dates
- Reviewer profiles (anonymized)
- Response from business

**Collection Method**: API calls + web scraping
**Update Frequency**: Weekly
**Status**: Not yet implemented

### 3. Social Media Activity

**Target Platforms**:
- Instagram (posts, engagement, follower counts)
- Facebook (posts, events, check-ins)
- Twitter/X (mentions, sentiment)

**Data Points**:
- Post frequency
- Engagement metrics (likes, comments, shares)
- Follower growth
- Content themes

**Collection Method**: Platform APIs
**Update Frequency**: Daily for major competitors, weekly for others
**Status**: Not yet implemented

### 4. Demographic Context

**Target Sources**:
- Statistics Canada Census data
- Edmonton Open Data Portal
- Google Maps foot traffic estimates (if available)

**Data Points**:
- Population density by neighborhood
- Income distribution
- Age demographics
- Commuting patterns

**Collection Method**: Public data downloads
**Update Frequency**: Annually (census cycle)
**Status**: Not yet implemented

---

## Data Lineage

```
External Sources (Web, APIs, Public Records)
    ↓
[Collection Scripts] (./data-collection/*.R, *.py)
    ↓
Raw Database (./data-private/raw/edmonton_cafes.sqlite)
    ↓
[Ferry Script] (./data-collection/ferry-to-derived.R)
    ↓
Derived Database (./data-private/derived/rap-1-competition-intel.sqlite)
    ↓
[Analysis Scripts] (./analysis-scripts/*.R)
    ↓
Reports & Visualizations
```

---

## Data Access & Privacy

**Access Control**:
- Raw data: `./data-private/` (NOT version controlled)
- Derived data: `./data-private/derived/` (NOT version controlled)
- Analysis scripts: Version controlled
- Documentation: Version controlled

**Privacy Considerations**:
- All data is from public sources (websites, social media, reviews)
- No customer PII (personally identifiable information)
- Business information is publicly available
- Review content is publicly posted by users

**Ethical Use**:
- Data used solely for competitive intelligence, not harassment
- No misrepresentation of businesses
- Respect robots.txt and API rate limits
- Cite sources when publishing insights

---

## Maintenance Notes

**Responsible Party**: Research Team (Data Collection Lead)

**Regular Tasks**:
- [ ] Monthly: Refresh cafe directory (new openings, closures)
- [ ] Quarterly: Validate pricing data (menu changes)
- [ ] Annually: Full audit of all fields

**Change Log**:
- 2025-12-12: Initial data sources documentation created
- 2025-12-12: Synthetic test data generated (30 cafes)

---

## Questions or Issues?

Contact: @andkov (Project Lead)  
Issue Tracker: GitHub Issues in square-one-coffee repository  
Documentation: `./analysis/rap-1/rap-1-task-assignment.md`
