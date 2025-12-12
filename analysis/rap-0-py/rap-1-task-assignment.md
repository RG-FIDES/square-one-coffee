# RAP-1: Edmonton Coffee Competition Intelligence System

**Assigned to**: @oleksandkov  
**Project**: Square One Coffee Research Partnership  
**Created**: 2025-12-12  
**Status**: In Planning

---

## Mission

Create a **Reproducible Analytical Pipeline (RAP-1)** that systematically monitors Edmonton's coffee and cafe market, collects competitive intelligence data, and generates comprehensive analytical reports to support Square One Coffee's operational and strategic development decisions.

### Context

Square One Coffee (SOC) operates 6+ cafe locations in Edmonton with ambitions to expand thoughtfully. To make informed decisions about operations, market positioning, and growth opportunities, SOC needs systematic, up-to-date intelligence about:

- **Competition landscape**: Who are the players, where are they, what do they offer?
- **Market dynamics**: Pricing strategies, customer preferences, emerging trends
- **Expansion opportunities**: Geographic gaps, underserved segments, adjacent markets
- **Strategic positioning**: How SOC compares across key dimensions (quality, pricing, experience, values)

This intelligence must be **reproducible** (methods documented, results verifiable), **current** (regularly updated), and **actionable** (directly supports business decisions).

**Reference**: UK Government's Reproducible Analytical Pipelines framework emphasizes automation, transparency, and quality assurance in analytical workflows.

---

## Objectives

### 1. Extend Existing Foundation

You've made an excellent start with `./data-private/raw/edmonton_cafes.sqlite`. We need to:

- **Expand scope**: Beyond basic cafe directory to comprehensive market intelligence
- **Systematize collection**: Document data sources and create reproducible ferry scripts
- **Structure for analysis**: Transform raw data into analysis-ready datasets
- **Enable insights**: Support strategic questions SOC leadership will ask

### 2. Build Self-Contained Analysis Environment

Create a complete analytical system within `./analysis/rap-1/` that:

- **Imports and validates** competitive data from multiple sources
- **Transforms data** following the Ellis-pattern ferry approach (see `./manipulation/ellis-lane.R`)
- **Generates insights** through exploratory data analysis
- **Produces reports** with beautiful graphical illustrations following project standards
- **Documents everything** so methods are transparent and reproducible

### 3. Establish Data Collection Infrastructure

Build systematic "data lanes" that monitor:

- **Cafe directory**: Locations, hours, menu offerings, pricing, ownership
- **Online presence**: Websites, social media activity, engagement metrics
- **Customer voice**: Reviews (Google, Yelp, Facebook), sentiment, themes
- **Market context**: Demographics, foot traffic, neighborhood characteristics
- **Competitive dynamics**: New openings, closures, expansions, positioning changes

### 4. Follow Project Standards

All deliverables must comply with established project conventions:

- **EDA style guide** (`./analysis/eda-1/eda-style-guide.md`): Graph families, naming conventions, dimension standards
- **FIDES framework** (`./ai/project/method.md`): Transparency, reproducibility, human-centered design
- **Repository architecture**: Respect boundaries, use proper directories, integrate with `flow.R`

---

## Technical Architecture

### Directory Structure

```
./analysis/rap-1/
├── rap-1-task-assignment.md          # This document
├── data-collection/                   # Data acquisition scripts
│   ├── scrape-cafes.R                # Collect cafe directory data
│   ├── scrape-reviews.R              # Aggregate review data
│   ├── scrape-social.R               # Monitor social media
│   └── ferry-to-derived.R            # Ellis-pattern transformation
├── data-documentation/                # Metadata and lineage
│   ├── data-sources.md               # Where data comes from
│   ├── ferry-process.md              # How data is transformed
│   └── validation-rules.md           # Quality checks applied
├── analysis-scripts/                  # R + Quarto pairs
│   ├── rap-1-market-overview.R       # Core market analysis
│   ├── rap-1-market-overview.qmd     # Report document
│   ├── rap-1-competitive-position.R  # SOC positioning analysis
│   ├── rap-1-competitive-position.qmd
│   ├── rap-1-expansion-opportunities.R
│   ├── rap-1-expansion-opportunities.qmd
│   └── local-functions.R             # Shared utilities
└── prints/                            # Saved visualizations
```

### Data Flow

```
Web Sources (external)
    ↓
[Data Collection Scripts] (./analysis/rap-1/data-collection/)
    ↓
Raw SQLite (./data-private/raw/edmonton_cafes.sqlite)
    ↓
[Ferry Script] (Ellis-pattern transformation)
    ↓
Derived SQLite (./data-private/derived/rap-1-competition-intel.sqlite)
    ↓
[Analysis Scripts] (./analysis/rap-1/analysis-scripts/*.R)
    ↓
[Quarto Reports] (./analysis/rap-1/analysis-scripts/*.qmd)
    ↓
Insights + Visualizations (./analysis/rap-1/prints/)
```

### Integration with flow.R

The `./flow.R` orchestration script will execute RAP-1 analyses. You'll add entries like:

```r
ds_rail <- tibble::tribble(
  ~fx         , ~path,
  # ... existing entries ...
  
  # RAP-1: Competition Intelligence
  "run_r"     , "analysis/rap-1/data-collection/ferry-to-derived.R",
  "run_r"     , "analysis/rap-1/analysis-scripts/rap-1-market-overview.R",
  "run_qmd"   , "analysis/rap-1/analysis-scripts/rap-1-market-overview.qmd",
  "run_r"     , "analysis/rap-1/analysis-scripts/rap-1-competitive-position.R",
  "run_qmd"   , "analysis/rap-1/analysis-scripts/rap-1-competitive-position.qmd",
  # ... additional RAP-1 pairs ...
)
```

---

## Deliverables

### Phase 1: Foundation (Priority)

**Goal**: Get the fundamentals working - scripts run, reports render, graphs display beautifully.

#### 1.1 Data Collection & Ferry Scripts

- [ ] **Cafe directory scraper** (`scrape-cafes.R`)
  - Extend `edmonton_cafes.sqlite` with comprehensive cafe data
  - Fields: name, location, coordinates, hours, offerings, pricing, contact, ownership
  - Handle multiple data sources (Google Maps, cafe websites, directories)

- [ ] **Ferry script** (`ferry-to-derived.R`)
  - Follow Ellis-pattern: read raw → validate → transform → write derived
  - Input: `./data-private/raw/edmonton_cafes.sqlite`
  - Output: `./data-private/derived/rap-1-competition-intel.sqlite`
  - Include validation checks, quality metrics, session info logging

- [ ] **Data documentation** (`data-sources.md`, `ferry-process.md`)
  - Document each data source: URL, access method, update frequency, limitations
  - Explain ferry transformations: what changes, why, validation rules
  - Include data dictionary for all tables and fields

#### 1.2 Core Analysis: Market Overview

- [ ] **Analysis script** (`rap-1-market-overview.R`)
  - Load data from `rap-1-competition-intel.sqlite`
  - Create graph families following `eda-style-guide.md`:
    - **g2 family**: Geographic distribution (g2-data-prep → g21, g22, g23...)
    - **g3 family**: Pricing landscape (g3-data-prep → g31, g32, g33...)
    - **g4 family**: Market segmentation (g4-data-prep → g41, g42, g43...)
  - Each graph: unique name, 8.5×5.5 inch dimensions, saved with `ggsave()`
  - No `print()` in .R script - focus on physical output quality

- [ ] **Report document** (`rap-1-market-overview.qmd`)
  - Load chunks from .R script using `read_chunk()`
  - Narrative sections explaining Edmonton coffee market structure
  - Display visualizations using `print(graph_object)` in chunks
  - Include figure captions, interpretation, business implications
  - Render to self-contained HTML

#### 1.3 Secondary Analysis: Competitive Positioning

- [ ] **Analysis script** (`rap-1-competitive-position.R`)
  - Position SOC relative to competitors across dimensions:
    - Price positioning (value vs. premium)
    - Product breadth (coffee-only vs. full cafe)
    - Experience focus (grab-and-go vs. destination)
    - Geographic coverage
  - Graph families comparing SOC to market
  - Follow style guide conventions

- [ ] **Report document** (`rap-1-competitive-position.qmd`)
  - How does SOC compare to the market?
  - Where are competitive advantages?
  - Where are vulnerabilities or gaps?
  - Strategic recommendations for positioning

---

### Phase 2: Enrichment (After Phase 1 Complete)

**Goal**: Add depth with additional data sources and more sophisticated analyses.

#### 2.1 Customer Voice Analysis

- [ ] **Review scraper** (`scrape-reviews.R`)
  - Aggregate reviews from Google, Yelp, Facebook
  - For SOC and major competitors
  - Store in `rap-1-competition-intel.sqlite`

- [ ] **Sentiment analysis** (in analysis scripts)
  - Compare SOC sentiment to competitors
  - Identify themes in positive/negative feedback
  - Track sentiment trends over time

#### 2.2 Market Dynamics

- [ ] **Social media monitoring** (`scrape-social.R`)
  - Track Instagram/Facebook presence and engagement
  - Identify marketing strategies and customer response

- [ ] **Expansion opportunity analysis** (`rap-1-expansion-opportunities.R/qmd`)
  - Geographic gaps (areas underserved by quality cafes)
  - Demographic opportunity (neighborhoods with cafe-friendly profiles)
  - Competitive vulnerability (areas where SOC could differentiate)

---

### Phase 3: Automation (Future)

**Goal**: Agentic workflow that maintains intelligence system with minimal human intervention.

- [ ] **Agent definition** (Logic Studio / Agent Builder Console JSON)
  - Automate data collection on schedule (weekly/monthly cycles)
  - Detect when new competitors enter market
  - Flag significant changes requiring human review
  - Update scripts when new metrics needed
  - Log decisions to `./ai/memory/memory-ai.md`

- [ ] **Cycle awareness system**
  - Track what data was collected each cycle
  - Compare current vs. previous cycles
  - Identify trends and changes automatically
  - Maintain institutional memory

**Note**: Agent collects data and adjusts scripts, but `flow.R` executes the analyses. Repo operation does not depend on agent platforms.

---

## Standards & Constraints

### Graph Families Concept

From `eda-style-guide.md`: A **graph family** shares a common **data ancestor** defined in a `*-data-prep` chunk. This ancestor represents a particular analytical perspective or question.

**Example**:
```r
# ---- g2-data-prep -------------------------------------------
# Data ancestor: "Where are cafes concentrated in Edmonton?"
geo_summary <- competition_data %>%
  group_by(neighborhood, cafe_type) %>%
  summarise(
    count = n(),
    avg_price = mean(avg_beverage_price),
    .groups = "drop"
  )

# ---- g21 ----------------------------------------------------
# Family member: Overall geographic distribution
g21_cafe_map <- geo_summary %>%
  ggplot(aes(x = lng, y = lat, size = count, color = cafe_type)) +
  geom_point(alpha = 0.7) +
  labs(title = "Cafe Concentration Across Edmonton")

ggsave("prints/g21_cafe_map.png", g21, width = 8.5, height = 5.5, dpi = 300)

# ---- g22 ----------------------------------------------------
# Family member: Zoom on downtown core
g22_downtown_detail <- geo_summary %>%
  filter(neighborhood %in% c("Downtown", "Oliver", "Garneau")) %>%
  # ... further analysis
```

Each graph gets a **unique identifier** (g21, g22, g23...). This makes it easy to reference specific visualizations and understand their lineage.

### Boundary Rules

**Permitted modifications**:
- ✅ Anything within `./analysis/rap-1/`
- ✅ Data products in `./data-private/derived/`
- ✅ Entries in `./flow.R` ds_rail for RAP-1 scripts
- ✅ Updates to `./ai/memory/memory-ai.md` for logging

**Prohibited modifications** (by RAP-1 scripts):
- ❌ Files outside `./analysis/rap-1/` (except data-private/derived)
- ❌ Shared scripts in `./scripts/`
- ❌ Other analysis directories (`./analysis/eda-1/`, etc.)
- ❌ Configuration files (`config.yml`, `environment.yml`)
- ❌ AI system files (except memory logging)

### Quality Standards

**All R scripts must**:
- Run without errors
- Include session info at end
- Document data sources and transformations
- Follow Ellis-pattern for data processing
- Use meaningful chunk names
- Save graphs to `./analysis/rap-1/prints/`

**All Quarto documents must**:
- Render to HTML without errors
- Include narrative context for findings
- Use `print()` for graph display
- Provide figure captions
- Interpret results for business audience
- Self-contained output (embed resources)

**All visualizations must**:
- Follow dimensions: 8.5×5.5 inches (letter half-page portrait)
- Use unique identifiers (g21, g31, g42...)
- Belong to named graph families with data ancestors
- Be print-ready quality (300 dpi)
- Include clear titles, labels, legends
- Use consistent color schemes and typography

---

## Key Questions for You to Answer

As you design and implement RAP-1, you'll need to make decisions about:

### Data Collection Strategy

1. **Which competitors to track?**
   - All cafes in Edmonton metro? Only specialty coffee shops?
   - Independent vs. chains - both or focus on independents?
   - Geographic boundaries - city limits or wider metro area?

2. **What data points are essential?**
   - What information do we NEED vs. NICE-TO-HAVE?
   - What can realistically be scraped vs. requires manual collection?
   - How frequently should each data source be updated?

3. **Data source prioritization**
   - Start with cafe directory, add reviews later? Or collect both from start?
   - Which review platforms matter most?
   - Is social media monitoring Phase 1 or Phase 2?

### Analysis Focus

4. **What questions should analyses answer?**
   - What would be most valuable to SOC leadership RIGHT NOW?
   - What insights would guide operational decisions?
   - What intelligence supports strategic planning?

5. **How to structure graph families?**
   - What analytical perspectives define each family?
   - How many families for Phase 1 (3-5 suggested)?
   - What level of detail in each family (2-4 graphs per family)?

### Technical Implementation

6. **Data validation approach**
   - What quality checks are essential?
   - How to handle missing or inconsistent data?
   - When to flag issues vs. auto-correct?

7. **Ferry script design**
   - Single transformation script or modular pipeline?
   - How to handle incremental updates vs. full refresh?
   - What derived tables/views in output database?

### Future Automation

8. **Agent architecture** (Phase 3)
   - Logic Studio vs. Agent Builder Console - which fits better?
   - What triggers data collection cycles?
   - How should agent decide when script updates needed?
   - What constitutes "significant change" requiring human review?

**Guidance**: Make pragmatic decisions based on your understanding of the data and tools. Document your reasoning. We can iterate as the system evolves.

---

## Resources & References

### Project Documentation

- **Mission & Methodology**: `./ai/project/mission.md`, `./ai/project/method.md`
- **EDA Style Guide**: `./analysis/eda-1/eda-style-guide.md` (essential reading!)
- **Ellis-Lane Example**: `./manipulation/ellis-lane.R` (ferry pattern reference)
- **Flow Integration**: `./guides/flow-usage.md`
- **Repository Architecture**: `./guides/getting-started.md`

### SOC Business Context

- **Business Profile**: `./data-public/derived/soc-business-profile.md`
- **Glossary**: `./ai/project/glossary.md` (coffee industry terminology)
- **Philosophy**: `./philosophy/threats-to-validity.md` (reproducibility standards)

### External References

- **UK Gov RAP**: [Reproducible Analytical Pipelines](https://analysisfunction.civilservice.gov.uk/support/reproducible-analytical-pipelines/) - philosophy and best practices
- **Agent Platforms**: 
  - https://logicstudio.ai/ (workflow automation)
  - https://agentbuilderconsole.com/ (agent orchestration)

### Technical Tools

- **R Packages**: DBI, RSQLite, dplyr, tidyr, ggplot2, sf (spatial), rvest (scraping)
- **Quarto**: https://quarto.org/docs/guide/ (publishing system)
- **SQLite**: https://www.sqlite.org/docs.html (database)

---

## Success Criteria

### Phase 1 Complete When:

- ✅ `edmonton_cafes.sqlite` extended with comprehensive competitive data
- ✅ Ferry script creates `rap-1-competition-intel.sqlite` in derived directory
- ✅ Data sources fully documented with access methods and limitations
- ✅ At least 2 analysis script pairs (R + Quarto) render successfully
- ✅ Multiple graph families (3+) following style guide conventions
- ✅ Reports provide actionable intelligence for SOC operations/strategy
- ✅ All visualizations are print-ready, appropriately dimensioned, uniquely named
- ✅ Scripts integrated into `flow.R` and execute without errors
- ✅ Documentation enables another analyst to understand and maintain system

### Overall Success Measures:

**Technical Quality**:
- Reproducibility: Another analyst can run pipeline and get same results
- Maintainability: Code is clear, documented, follows conventions
- Reliability: Scripts run without errors, handle edge cases gracefully

**Research Quality**:
- Validity: Data accurately represents Edmonton coffee market
- Rigor: Methods are sound, limitations acknowledged
- Transparency: Decisions and transformations are documented

**Business Value**:
- Actionability: Insights directly support SOC decision-making
- Relevance: Addresses real strategic questions leadership has
- Currency: Intelligence is up-to-date and can be refreshed systematically

---

## Timeline & Priorities

**Immediate Priority**: Phase 1 fundamentals
- Get data flowing from source → derived
- Create at least one complete analysis (R + Quarto pair) that renders
- Establish graph family conventions

**Near-Term**: Complete Phase 1 deliverables
- Comprehensive market overview analysis
- SOC competitive positioning analysis
- Full documentation suite

**Future**: Phases 2-3 (to be scheduled after Phase 1 review)

---

## Communication & Collaboration

### Questions & Clarifications

Post questions as comments on this issue. Tag @andkov for:
- Clarification on Square One Coffee business context
- Decisions requiring strategic input
- Methodological questions about FIDES framework
- Scope boundary questions

### Progress Updates

Provide periodic updates (weekly suggested) with:
- What's been completed
- Current focus area
- Blockers or questions
- Next steps

### Code Reviews

Request review when:
- First complete analysis pair ready (early feedback valuable)
- Data ferry script complete (validate approach)
- Before considering Phase 1 "done"

---

## Notes

### On Agentic Workflow (Phase 3)

The ultimate vision is an autonomous agent that:
- **Monitors** Edmonton cafe market continuously
- **Collects** data on schedule without human intervention
- **Validates** data quality automatically
- **Detects** significant changes (new competitors, major shifts)
- **Updates** analysis scripts when new metrics needed
- **Flags** anomalies or opportunities for human review
- **Maintains** cycle awareness (learns from previous runs)
- **Logs** decisions and changes to project memory

However, **Phase 1 focus is foundational**: Build the analytical infrastructure that an agent would eventually maintain. Get the data flows working, establish quality standards, create the analytical products. Automation comes after we know WHAT to automate.

### On Graph Families

The graph family concept is core to systematic EDA:
- **Data ancestor** (prep chunk) = the analytical perspective
- **Family members** (individual graphs) = specific views of that perspective
- **Unique names** (g21, g22...) = easy reference and intellectual property

Think of each family as exploring ONE big question:
- g2x: "Where is the geographic opportunity?"
- g3x: "How does pricing position us?"
- g4x: "What customer segments exist?"

Each graph in the family shows a different facet of that question.

### On Repository Boundaries

RAP-1 is **self-contained by design**:
- Minimizes dependencies on other parts of repo
- Reduces risk of breaking other analyses
- Makes it clear what RAP-1 owns and maintains
- Simplifies eventual automation

The only touch points outside `./analysis/rap-1/` are:
- Reading from `./data-private/` (input data)
- Writing to `./data-private/derived/` (output data)
- Entries in `./flow.R` (execution orchestration)
- Logging to `./ai/memory/` (institutional memory)

---

## Getting Started

### Recommended Approach

1. **Study examples** (`./analysis/eda-1/`, `./manipulation/ellis-lane.R`)
2. **Explore existing data** (`edmonton_cafes.sqlite` - what's there, what's missing?)
3. **Draft data collection plan** (sources, methods, priorities)
4. **Build ferry script** (raw → derived transformation)
5. **Create first analysis** (market overview - ONE graph family to start)
6. **Iterate and expand** (add families, create second analysis)
7. **Document thoroughly** (future you and others need to understand this)

### First Concrete Steps

1. Clone repo, ensure environment set up (`environment.yml`, R packages)
2. Read `eda-style-guide.md` completely (it's your bible for this work)
3. Inspect `edmonton_cafes.sqlite` structure (what data exists?)
4. Create `./analysis/rap-1/data-documentation/data-sources.md` (document current data)
5. Build minimal ferry script that reads current SQLite, validates, writes to derived
6. Create simplest possible analysis: load data, make one graph, render report
7. Iterate from there

---

**Questions? Concerns? Ideas?** Post them here. Let's build something valuable for Square One Coffee!

@andkov
