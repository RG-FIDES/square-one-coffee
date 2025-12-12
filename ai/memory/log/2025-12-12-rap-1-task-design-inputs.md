# RAP-1 Task Design - Human Inputs from Chat Session

**Date**: 2025-12-12  
**Session**: Task assignment design for @oleksandkov  
**Outcome**: Created comprehensive RAP-1 task assignment document

---

## Input 1: Initial Vision

let's design the text of the issue, in which I will assign my informatician a task. First, let's talk to describe this task (so please do a thorough review of all documents in this project). Here's a short starting text for my vision of this task: I want you, @oleksandkov, to create an agent in Agent Builder Console or Logic Studio, that would oversee collection of specific data from the environment and creating the scripts that report on the data and the insight found in a given cycle. It should  be aware of results from the previous cycles of reporting/data update.  The agentic workflow shold oversee ./analysis/rap-1/  in this repository ( it stands for Reproducible Analytical Pipeline, look it up in the UK gov). 

---

## Input 2: Adding Specificity

Great start. Many of these questions I want @oleksandkov to answer (or dismiss). Let me start adding specificity (influnced by your response). 

1. rap-1 is an agentic workflow ( a json file readable by https://logicstudio.ai/ or https://agentbuilderconsole.com/) that monitors the environment and each cycle (week or month) generates a new version of sqlite database containing a set of tables that capture data. In this case (rap-1) is the data about the competition environment of SOC. @oleksandkov had a great start by creating ./data-private/raw/edmonton_cafes.sqlite, but we need to extend it into a full fledgle intelligence report on competition in coffee industry in Edmonton. This should include description of sources where data is obtained and the script ferries it to the ellis island of the repo to be prepared for subsequent analysis.  

2. Agent must oversee the script that runs inside this enviorment (this repo with its ./ai/ system and the larger architecture of he repo (e.g. ./scripts/, ./analysis)). All products must be placed within ./data-private/derived/. No other changes to the files outside of ./analysis/rap-1/ are permited to the scripts inside of it, designed and operated by the agent. 

3. competitor intelligence gathering, we want to establish a lane of data collection/monitoring that would ensure we are awere of the coffee market/industry in Edmonton, everything we need to operate SOC and look for the opportunity to expand business (maybe even beyond cofee, but cafe business is our home, see SOC identity) 

4. In my (@andkov) mind it's a few R scripts that pull and shape up the date (like scripts in ./manipulation/ do, but housed in ./analysis/rap-1/ so it's contained) and a small set of  .R +.qmd pairs that create analytic reports (how ./analysis/eda-1/ exemplifies, please study, especially graph families described in eda-style-guide) 

5. Yes, Comply implicitly 

6. Yes, but not on this run. let's take care of the fundamentals first. The R scripts must run, qmd files must render. All graphs and tables must follow the eda-style-guide philosophy, so each graph/idea has a unquie name (e.g. g23 ).. 

Further Consideration. 

1. Explore https://agentbuilderconsole.com/ and https://logicstudio.ai/ as a free open source solution to conveniently descibe and manage an agent. However, deployment of the repo, should not depend on managing those agents. The rap-1 agent should pull the data from the web and place it into within ./data-private/derived/ , and make sure the the scripts in ./analysis/rap-1/ that rely on these data products are adjust(if needed) after  the latest cycle (e.g. we may want to add a new metric that must be featured in the report). However, the running of the R and qmd scripts will be done via flow.R So, to repeat, rap-1 agent collects data and adjusts scripts in ./analysis/rap-1/, but then a differnt trigger runs ./flow.R which runs the R script that process data and compiles the report. 

---

## Input 3: Final Task Assignment Request

using this plan, create the text of the issue for @oleksandkov to build the scripts (./analysis/rap-1/) that import the data on competitors (using edmonton_cafe.sqlite as a starter) and add documentation about the data, the processes to create it, and so on. In the end, we want to have a set of R scripts and .R + .qmd pairs that give a comprehensive and uptodate analysis (with beautify graphical illustrations) of coffee and cafe industry sector in Edmonton, in a way that could be useful to SOC for its operations and development.  Place this text into rap-1-task-assignment.

---

## Key Decisions Made During Session

### Architecture Clarification
- **Agent role**: Data collection + script adjustment (not execution)
- **Flow.R role**: Script execution and report compilation
- **Separation of concerns**: Agent prepares, separate trigger executes

### Scope Boundaries
- **Permitted**: Modifications within `./analysis/rap-1/`, data output to `./data-private/derived/`
- **Prohibited**: Changes to files outside `./analysis/rap-1/` (except data-private/derived)
- **Integration point**: `./flow.R` entries for orchestration

### Priority Focus
- **Phase 1**: Fundamentals - scripts run, reports render, graphs follow style guide
- **Phase 2**: Enrichment - additional data sources, sophisticated analyses
- **Phase 3**: Automation - agentic workflow (future, after fundamentals proven)

### Technical Requirements
- Extend `edmonton_cafes.sqlite` foundation
- Follow Ellis-pattern ferry scripts (`./manipulation/ellis-lane.R` reference)
- Implement graph families per `eda-style-guide.md`
- Each graph: unique identifier (g21, g22...), 8.5×5.5 inch dimensions
- R scripts use `ggsave()`, Quarto documents use `print()`

### Business Context
- Competitive intelligence for Square One Coffee
- Support operations and strategic development
- Enable expansion decisions (including beyond coffee, within cafe business)
- Comprehensive Edmonton coffee/cafe market analysis

---

## Deliverable Created

`./analysis/rap-1/rap-1-task-assignment.md` - Comprehensive task assignment document including:
- Mission and context
- 4 core objectives
- Technical architecture (directory structure, data flow, flow.R integration)
- 3-phase deliverables with checkboxes
- Standards & constraints (graph families, boundary rules, quality standards)
- 8 key questions for @oleksandkov to answer
- Resources & references
- Success criteria (technical, research, business value)
- Getting started guide with concrete first steps

---

## Notes for Future Reference

- **Human-authored inputs preserved** in this log file
- **Design rationale documented** for future iterations
- **Agent platforms explored**: Logic Studio and Agent Builder Console
- **Repository architecture respected**: Self-contained RAP-1 design
- **FIDES framework compliance**: Transparency, reproducibility, human-centered
- **UK Gov RAP reference**: Best practices for reproducible analytical pipelines

This session established the foundation for RAP-1 competitive intelligence system development.
