# `manipulation/` Directory

Files in this directory manipulate/groom/munge the project data.

They typically intake raw data from `./data-public/raw` and/or `./data-private/raw` and transform them into tidy objects, which would be convenient to place into literate scripts (e.g. `.Rmd` or `.qmd`) for exploration and annotation. For example, consider a simple project described in [RAnalysisSkeleton](https://github.com/wibeasley/RAnalysisSkeleton), featuring the ubiquitous `cars` data set:

![](images/flow-skeleton-car.png)

The script `./manipulation/car-ellis.R` digests a raw `.csv` file from `./data-public/raw` and creates a clean data object `car.rds`, so-called *analysis-ready rectangle*. This object becomes the starting point for the literate script `./analysis/car-report-1/car-report-1.Rmd` which renders a self-contained document `car-report-1.hmtl` , the deliverable in this simple project. In this case, the [ellis and scribe patterns](https://ouhscbbmc.github.io/data-science-practices-1/patterns.html) are combined in the single script.

Please follow these [instructions](https://github.com/wibeasley/RAnalysisSkeleton#establishing-a-workstation-for-analysis) to execute the entire pipline of the RAnalysisSkeleton repo and examine `./analysis/car-report-1/car-report-1.html` for examples of code syntax for most basic tasks in data analysis. This template is useful for simple, one-off projects, like a straightforward information request with a quick turn-over.

However, a more realistic project involves multiple data sources and may call for separate tidy data sets to accommodate the specific requirement of a given task (e.g. feed into a statistical model vs serve as a data source for a dashboard). Consider the following example in which 20 children who live across three different counties are measured each year for 10 years on some physical and cognitive abilities to study their growth and to estimate how county characteristics (which are also measured each year) influence children's physical and mental growth.

![](images/flow-skeleton-02.png)

We may want to explore county-level characteristics (`te.rds`) separtely from person-level characteristics (`mlm.rds`), hence two different rectangles, optimized for each task.

The resulting "derived" datasets produce less friction when analyzing. By centralizing most (and ideally all) of the manipulation code in one place, it's easier to determine how the data was changed before analyzing. It also reduces duplication of manipulation code, so analyses in different files are more consistent and understandable.

# GOA example 

It might be easier to think in terms of an example more relevant to our substantive focus:

![](images/flow-skeleton.png)

# Ellis Pipeline

The Ellis Pipeline is a multi-stage data collection and consolidation system that fetches data from multiple sources and combines them into a unified SQLite database for analysis. The pipeline consists of 5 stages:

## Pipeline Stages

### Stage 0: Google Places Cafe Scan (`ellis-0-scan.py`)
- **Purpose**: Fetches comprehensive cafe and coffee shop data from Google Places API
- **Input**: Grid-based search coordinates covering Edmonton area
- **Output**: `data-public/derived/cafes/cafes-google-places.csv` (~1,785 records)
- **Requirements**: `PLACES_API_KEY` environment variable
- **Runtime**: ~2-3 minutes (with API rate limiting)

### Stage 1: Edmonton Property Assessment (`ellis-1-open-data.R`)
- **Purpose**: Fetches property assessment data from Edmonton Open Data portal
- **Input**: SODA2 API endpoint for property assessments
- **Output**: `data-public/derived/open-data/property-assessment.csv` (~1,000 records)
- **Requirements**: Internet connection for API access
- **Runtime**: ~30 seconds

### Stage 2: Edmonton Business Licenses (`ellis-2-open-data.R`)
- **Purpose**: Fetches business license data from Edmonton Open Data portal
- **Input**: SODA2 API endpoint for business licenses
- **Output**: `data-public/derived/open-data/business-licenses.csv` (~1,000 records)
- **Requirements**: Internet connection for API access
- **Runtime**: ~30 seconds

### Stage 3: Edmonton Community Services (`ellis-3-open-data.R`)
- **Purpose**: Fetches community services data from Edmonton Open Data portal
- **Input**: SODA2 API endpoint for community services
- **Output**: `data-public/derived/open-data/community-services.csv` (~1,000 records)
- **Requirements**: Internet connection for API access
- **Runtime**: ~30 seconds

### Stage Last: Data Consolidation (`ellis-last.R`)
- **Purpose**: Consolidates all pipeline data into unified SQLite database
- **Input**: All CSV files from previous stages
- **Output**: `data-public/derived/global-data.sqlite` with 5 tables
- **Requirements**: All previous stages completed successfully
- **Runtime**: ~10 seconds- **Skip Logic**: Automatically skips tables that already exist in the database
## Database Schema

The consolidated SQLite database (`global-data.sqlite`) contains these tables:

1. **cafes_google_places** - Google Places cafe data
2. **property_assessment** - Edmonton property assessment data  
3. **business_licenses** - Edmonton business license data
4. **community_services** - Edmonton community services data
5. **pipeline_metadata** - Pipeline execution metadata and timestamps

## Running the Pipeline

### Option 1: Complete Pipeline (All Stages)
Run all stages in sequence:
```bash
python manipulation/ellis-0-scan.py && \
Rscript manipulation/ellis-1-open-data.R && \
Rscript manipulation/ellis-2-open-data.R && \
Rscript manipulation/ellis-3-open-data.R && \
Rscript manipulation/ellis-last.R
```

### Option 2: Open Data Only (Stages 1-Last)
Skip the Google Places API stage and run only open data stages:
```bash
Rscript manipulation/ellis-1-open-data.R && \
Rscript manipulation/ellis-2-open-data.R && \
Rscript manipulation/ellis-3-open-data.R && \
Rscript manipulation/ellis-last.R
```

### Option 3: Individual Scripts
Run any individual stage:
```bash
# Stage 0 only
python manipulation/ellis-0-scan.py

# Stage 1 only  
Rscript manipulation/ellis-1-open-data.R

# Stage 2 only
Rscript manipulation/ellis-2-open-data.R

# Stage 3 only
Rscript manipulation/ellis-3-open-data.R

# Consolidation only
Rscript manipulation/ellis-last.R
```

### Option 4: VS Code Tasks
Use the built-in VS Code tasks for easy execution. There are two modes:

1) Docker-based (runs inside the container)

1. **Ctrl+Shift+P** → **Tasks: Run Task**
2. Select:
   - **"Ellis Pipeline - Complete (All Stages)"** - Runs all 5 stages in Docker container
   - **"Ellis Pipeline - Open Data Only"** - Runs stages 1-4 in Docker container (skips Google Places API)

**Requirements for Docker Tasks:**
- Docker Desktop running
- Container image built (`square-one-coffee:latest`)
- `.env` file with `PLACES_API_KEY` (for complete pipeline)

2) Local Bash (runs on your workstation using bash)

1. **Ctrl+Shift+P** → **Tasks: Run Task**
2. Select one of the local tasks:
   - **"Ellis Pipeline - Complete (Local Bash)"** - Runs the full pipeline locally (Python + R)
   - **"Ellis Pipeline - Open Data Only (Local Bash)"** - Runs stages 1-4 (skips Google Places API)
   - **Individual stages**: **"Ellis - Stage 0 (Local Bash)"**, **"Ellis - Stage 1 (Local Bash)"**, **"Ellis - Stage 2 (Local Bash)"**, **"Ellis - Stage 3 (Local Bash)"**, **"Ellis - Consolidation (Local Bash)"**

**Requirements for Local Bash Tasks:**
- `bash` available (WSL/Git Bash/macOS/Linux)
- Python 3.11+ on PATH (for Stage 0)
- R and `Rscript` on PATH (for R stages)
- `.env` file with `PLACES_API_KEY` if running the full pipeline

**Notes:**
- Local bash tasks execute commands from the project root (`${workspaceFolder}`)
- Use local tasks when you prefer running scripts directly on your workstation
- Use Docker tasks to run the pipeline in a reproducible container environment

## Environment Setup

### Required Environment Variables
Create a `.env` file in the project root with:
```
PLACES_API_KEY=your_api_key_here
```

### Dependencies
- Python 3.11+ with: `requests`, `pandas`, `python-dotenv`
- R 4.x with: `tidyverse`, `DBI`, `RSQLite`, `httr`, `jsonlite`
- Internet connection for API access
- Google Places API key (for Stage 0)

## Troubleshooting

### Common Issues

**Google Places API Errors:**
- Verify `GOOGLE_PLACES_API_KEY` is set correctly
- Check API quota limits
- Ensure billing is enabled on Google Cloud project

**Open Data API Errors:**
- Check internet connection
- Verify Edmonton Open Data portal is accessible
- API endpoints may change; check current SODA2 documentation

**SQLite Database Errors:**
- Ensure previous stages completed successfully
- Check file permissions in `data-public/derived/`
- Verify CSV files exist and are readable
**Skip Behavior:**
- Tables that already exist in the database will be automatically skipped
- To force refresh a specific table, delete it from the database first
- Check console output for "⏭️ Tables skipped" messages
**Python/R Import Errors:**
- Run in container environment with all dependencies installed
- Check that conda/pip packages are available

### Logs and Debugging
- Each script outputs progress to console
- Check `data-public/derived/` for output files
- Pipeline metadata stored in `pipeline_metadata` table
- Use SQLite browser to inspect `global-data.sqlite`

## Output Locations
- **CSV files**: `data-public/derived/cafes/` and `data-public/derived/open-data/`
- **Database**: `data-public/derived/global-data.sqlite`
- **Logs**: Console output during execution
