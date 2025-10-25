# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

R-based analysis project for Asian Barometer survey data focused on Cambodia across Waves 2, 3, 4, and 6. The project uses a modular script-based workflow with RStudio project structure for reproducible analysis.

## Essential Commands

### Setup (Run Once)
```r
# Open RStudio project first: AsianBarometer.Rproj
source("scripts/00_setup.R")
```

### Run Complete Analysis Pipeline
```r
source("scripts/99_run_all.R")
```

### Run Individual Steps
```r
source("scripts/01_data_import.R")      # Load SPSS files, create codebook
source("scripts/02_data_cleaning.R")    # Clean survey variables
source("scripts/03_analysis.R")         # Statistical analysis
source("scripts/04_visualization.R")    # Generate plots
```

### Development & Testing
```r
# Test single function from helper file
source("functions/cleaning_functions.R")
clean_variable(c(1, 2, 97, 98, 3, 0))  # Test cleaning function

# Load processed data for interactive exploration
cambodia_all <- readRDS(here("data/processed/cambodia_all_waves_clean.rds"))

# View codebook
codebook <- read_csv(here("docs/codebook.csv"))
```

## Architecture

### Data Flow Pipeline
1. **Import** (01_data_import.R): Load 4 SPSS files → Filter Cambodia → Standardize names → Combine waves → Export codebook → Save .rds files
2. **Cleaning** (02_data_cleaning.R): Load combined data → Clean q92-q95 variables → Recode missing values (0, 97, 98, 99 → NA) → Generate statistics → Save cleaned .rds
3. **Analysis** (03_analysis.R): Statistical analysis on cleaned variables
4. **Visualization** (04_visualization.R): Generate plots and export to output/figures/

### Core Design Patterns
- **Path Management**: All paths use `here::here()` for reproducibility - no absolute paths, no `setwd()`
- **Naming Convention**: SPSS variable names standardized with `janitor::clean_names()` (lowercase, underscores)
- **Missing Value Handling**: Codes {0, 97, 98, 99} treated as missing (Asian Barometer standard)
- **Wave Identification**: Each wave tagged with `wave` column (Wave2, Wave3, Wave4, Wave6)
- **Data Preservation**: Raw data never modified, all processing creates new files in data/processed/

### Helper Functions (functions/cleaning_functions.R)
- `clean_variable(x, missing_codes)`: Recode missing values to NA for single variable
- `clean_multiple_vars(data, vars, suffix, missing_codes)`: Batch clean variables, add suffix
- `get_wave_summary(data, var_name, wave_var)`: Generate summary statistics by wave
- `export_codebook(data_list, output_path)`: Extract variable labels from SPSS files

### File Structure Logic
```
data/raw/              # Original SPSS (.sav) files - NEVER MODIFY
data/processed/        # Cleaned .rds files for R
functions/             # Reusable helper functions
scripts/               # Numbered workflow scripts (00-04, 99)
output/figures/        # Generated plots (.png)
output/tables/         # Exported data (.csv, .html)
docs/                  # Codebook and documentation
```

## Key Variables & Data Structure

### Critical Variables
- `wave`: Survey wave identifier (Wave2, Wave3, Wave4, Wave6)
- `country`: Country code (12 = Cambodia)
- `q92, q93, q94, q95`: Main survey questions
- `q92_clean, q93_clean, q94_clean, q95_clean`: Cleaned versions with missing values recoded

### Missing Value Codes (Asian Barometer Standard)
- `0`: Not applicable / Skip
- `97`: Not applicable
- `98`: Don't know
- `99`: Refuse to answer / Missing

### Wave-Specific Data Handling
- **Waves 2, 3, 4**: Filter by `country == 12` for Cambodia
- **Wave 6**: Cambodia-only file, no country filter needed
- **Variable consistency**: Check codebook for wave-specific variable names - not all variables exist in all waves

## Common Development Workflows

### Adding New Variables to Clean
1. Check if variable exists in codebook: `docs/codebook.csv`
2. Edit `scripts/02_data_cleaning.R` line ~30:
   ```r
   vars_to_clean <- c("q92", "q93", "q94", "q95", "NEW_VAR")
   ```
3. Optionally adjust missing codes if different from default (0, 97, 98, 99)

### Adding New Wave
1. Place SPSS file in `data/raw/NEW_WAVE_FOLDER/`
2. Edit `scripts/01_data_import.R`:
   - Add path definition (line ~20)
   - Add load section following existing pattern (line ~45-90)
   - Add to `list_of_waves` (line ~94)
   - Add to `bind_rows()` (line ~115)
   - Add to saveRDS section (line ~145)

### Troubleshooting Data Issues
1. **Variables not found**: Check `docs/codebook.csv` for actual variable names by wave
2. **File not found errors**: Verify paths in `scripts/01_data_import.R` match actual folder structure
3. **Unexpected missing values**: Check if missing value codes differ from default {0, 97, 98, 99}
4. **Wave-specific issues**: Some variables only exist in certain waves - use codebook to verify

## Important Constraints

### Data File Requirements
- Raw SPSS files must be in `data/raw/` subdirectories
- File paths in `01_data_import.R` must match actual folder names (including spaces)
- Cambodia country code is 12 for Waves 2-4
- Wave 6 is Cambodia-only, no country filtering needed

### R Environment Requirements
- Must open `AsianBarometer.Rproj` for `here()` package to work correctly
- All packages listed in `scripts/00_setup.R` must be installed
- Working directory automatically set by RStudio project - do not use `setwd()`

### Output Conventions
- Figures: PNG format in `output/figures/`
- Tables: CSV and HTML in `output/tables/`
- Processed data: .rds format in `data/processed/` for efficient R storage
- Codebook: CSV in `docs/codebook.csv` regenerated from SPSS labels each run
