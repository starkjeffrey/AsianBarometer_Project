# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

R-based analysis project for Asian Barometer survey data focused on Cambodia across Waves 2, 3, 4, 5, and 6. The project uses a modular script-based workflow with RStudio project structure for reproducible analysis.

**CRITICAL**: Asian Barometer uses different response scales across waves (4-point vs 6-point, reversed polarity). Always use harmonized variables (*_harm suffix) for cross-wave comparisons.

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

### Cross-Wave Harmonization (CRITICAL for Wave Comparisons)
```r
# Harmonize scales and create comparable variables across waves
source("scripts/05_harmonize_waves.R")

# Verify harmonization results
source("scripts/verify_harmonization.R")

# Compare 4-point vs 6-point trust scale distributions
source("scripts/05_trust_scale_comparison.R")
```

### Interactive Exploration
```r
# Render interactive Quarto dashboard for exploring trust variables
quarto::quarto_render("trust_explorer.qmd")
# Open trust_explorer.html in browser for interactive filtering and visualization
```

### Development & Testing
```r
# Test single function from helper file
source("functions/cleaning_functions.R")
clean_variable(c(1, 2, 97, 98, 3, 0))  # Test cleaning function

# Load processed data for interactive exploration
cambodia_all <- readRDS(here("data/processed/cambodia_all_waves_clean.rds"))

# Load harmonized data (for cross-wave analysis)
cambodia_harm <- readRDS(here("data/processed/cambodia_all_waves_harmonized.rds"))

# View codebook
codebook <- read_csv(here("docs/codebook.csv"))

# View harmonization mappings
harm_codebook <- read_csv(here("docs/harmonization_codebook.csv"))
```

## Architecture

### Data Flow Pipeline
1. **Import** (01_data_import.R): Load 5 SPSS files → Filter Cambodia (Waves 2-5) → Standardize names → Combine waves → Export codebook → Save .rds files
2. **Cleaning** (02_data_cleaning.R): Load combined data → Clean q92-q95 variables → Recode missing values (0, 97, 98, 99 → NA) → Generate statistics → Save cleaned .rds
3. **Harmonization** (05_harmonize_waves.R): Apply scale reversals → Standardize directionality (higher = better/more trust) → Create concept-level variables → Save harmonized .rds
4. **Analysis** (03_analysis.R): Statistical analysis on cleaned variables
5. **Visualization** (04_visualization.R): Generate plots and export to output/figures/

### Cross-Wave Harmonization System
**Purpose**: Resolve incompatible scales and reversed polarity across waves to enable valid comparisons.

**Scale Issues**:
- Trust questions: 4-point (W2, W4, W6) vs 6-point (W3, W5)
- Polarity reversals: Some waves use 1="positive" → 5="negative", others reverse this
- Example: W2 q1 (1=Very bad, 5=Very good) vs W4 q1 (1=Very good, 5=Very bad)

**Harmonization Process** (functions/wave_harmonization.R):
1. **Scale Reversal**: Flip reversed scales to consistent directionality (higher = more positive/trust)
2. **Suffix Convention**: Harmonized variables get `_harm` suffix (e.g., q1 → q1_harm)
3. **Concept Mapping**: Create standardized names (e.g., q1_harm → econ_country_current)
4. **Validation**: verify_harmonization.R confirms directionality consistency

**Critical Rule**: NEVER compare raw q* variables across waves. Always use:
- `*_harm` suffixed variables for numeric comparisons
- Concept names (e.g., `trust_executive`) for semantic clarity
- Check `docs/harmonization_codebook.csv` for variable mappings

### Core Design Patterns
- **Path Management**: All paths use `here::here()` for reproducibility - no absolute paths, no `setwd()`
- **Naming Convention**: SPSS variable names standardized with `janitor::clean_names()` (lowercase, underscores)
- **Missing Value Handling**: Codes {0, 97, 98, 99} treated as missing (Asian Barometer standard)
- **Wave Identification**: Each wave tagged with `wave` column (Wave2, Wave3, Wave4, Wave6)
- **Data Preservation**: Raw data never modified, all processing creates new files in data/processed/

### Helper Functions

**functions/cleaning_functions.R**:
- `clean_variable(x, missing_codes)`: Recode missing values to NA for single variable
- `clean_multiple_vars(data, vars, suffix, missing_codes)`: Batch clean variables, add suffix
- `get_wave_summary(data, var_name, wave_var)`: Generate summary statistics by wave
- `export_codebook(data_list, output_path)`: Extract variable labels from SPSS files

**functions/wave_harmonization.R**:
- `harmonize_wave(data, wave_id)`: Apply wave-specific scale reversals and create harmonized variables
- `create_harmonization_codebook()`: Generate mapping of raw → harmonized → concept variables
- Internal functions handle wave-specific scale directions and create standardized names

### File Structure Logic
```
data/raw/              # Original SPSS (.sav) files - NEVER MODIFY
data/processed/        # Cleaned and harmonized .rds files for R
functions/             # Reusable helper functions (cleaning, harmonization)
scripts/               # Numbered workflow scripts (00-05, 99)
  01-04: Basic pipeline (import, clean, analyze, visualize)
  05: Harmonization suite (05_harmonize_waves.R, 05_trust_scale_comparison.R)
  verify_harmonization.R: Validation checks
output/figures/        # Generated plots (.png)
output/tables/         # Exported data (.csv, .html)
docs/                  # Codebooks (codebook.csv, harmonization_codebook.csv)
*.qmd                  # Quarto documents (trust_explorer.qmd for interactive dashboards)
```

## Key Variables & Data Structure

### Critical Variables
- `wave`: Survey wave identifier (Wave2, Wave3, Wave4, Wave5, Wave6)
- `country`: Country code (12 = Cambodia)
- `q1-q150+`: Raw survey questions (SPSS variable names)
- `*_clean`: Cleaned versions with missing values recoded (suffix from 02_data_cleaning.R)
- `*_harm`: Harmonized versions with consistent scale direction (suffix from 05_harmonize_waves.R)
- Concept names: Semantic variable names (e.g., `econ_country_current`, `trust_executive`)

### Key Concept Variables (Standardized Names)
- **Economic perceptions**: `econ_country_current`, `econ_family_current`
- **Institutional trust**: `trust_executive`, `trust_courts`, `trust_national_gov`, `trust_parties`, `trust_parliament`
- **Democracy attitudes**: `satisfaction_democracy`, `level_democracy`, `democracy_preferable`
- **Political engagement**: `interest_politics`, `follow_news`

### Missing Value Codes (Asian Barometer Standard)
- `0`: Not applicable / Skip
- `97`: Not applicable
- `98`: Don't know
- `99`: Refuse to answer / Missing

### Wave-Specific Data Handling
- **Waves 2-5**: Filter by `country == 12` (or `COUNTRY == 12` for W5) for Cambodia
- **Wave 6**: Cambodia-only file, no country filter needed
- **Variable consistency**: Check codebook for wave-specific variable names - not all variables exist in all waves
- **Scale type by wave**:
  - 4-point scales: Wave 2, Wave 4, Wave 6
  - 6-point scales: Wave 3, Wave 5

## Common Development Workflows

### Adding New Variables to Clean
1. Check if variable exists in codebook: `docs/codebook.csv`
2. Edit `scripts/02_data_cleaning.R` line ~30:
   ```r
   vars_to_clean <- c("q92", "q93", "q94", "q95", "NEW_VAR")
   ```
3. Optionally adjust missing codes if different from default (0, 97, 98, 99)

### Adding Cross-Wave Comparable Variables
1. Check variable names across waves in `docs/codebook.csv`
2. Edit `functions/wave_harmonization.R`:
   - Add variable to appropriate wave-specific reversal list if scale is reversed
   - Add to concept mapping function to create standardized name
3. Test with `scripts/verify_harmonization.R` to confirm consistent directionality
4. Document in `docs/harmonization_codebook.csv`

### Adding New Wave
1. Place SPSS file in `data/raw/NEW_WAVE_FOLDER/`
2. Edit `scripts/01_data_import.R`:
   - Add path definition (line ~20)
   - Add load section following existing pattern (line ~45-90)
   - Add to `list_of_waves` (line ~94)
   - Add to `bind_rows()` (line ~115)
   - Add to saveRDS section (line ~145)
3. Edit `functions/wave_harmonization.R`:
   - Add wave-specific scale reversal logic
   - Update harmonize_wave() function to handle new wave ID
4. Update `scripts/05_harmonize_waves.R` to load and process new wave

### Troubleshooting Data Issues
1. **Variables not found**: Check `docs/codebook.csv` for actual variable names by wave
2. **File not found errors**: Verify paths in `scripts/01_data_import.R` match actual folder structure
3. **Unexpected missing values**: Check if missing value codes differ from default {0, 97, 98, 99}
4. **Wave-specific issues**: Some variables only exist in certain waves - use codebook to verify
5. **Cross-wave comparisons seem wrong**:
   - Verify you're using `*_harm` variables, not raw `q*` variables
   - Check `docs/harmonization_codebook.csv` for scale direction
   - Run `scripts/verify_harmonization.R` to validate
6. **haven_labelled errors in Quarto**: Use `haven::zap_labels()` or `as.numeric()` before pivoting/plotting
7. **Negative values in trust data**: Check if scale reversal function received correct inputs (use validation functions)

## Important Constraints

### Data File Requirements
- Raw SPSS files must be in `data/raw/` subdirectories
- File paths in `01_data_import.R` must match actual folder names (including spaces)
- Cambodia country code is 12 for Waves 2-5 (uppercase `COUNTRY` in Wave 5)
- Wave 6 is Cambodia-only, no country filtering needed
- Harmonized data required for cross-wave analysis: run `05_harmonize_waves.R` first

### R Environment Requirements
- Must open `AsianBarometer.Rproj` for `here()` package to work correctly
- All packages listed in `scripts/00_setup.R` must be installed
- Working directory automatically set by RStudio project - do not use `setwd()`
- For Quarto documents: Install `plotly`, `DT`, `crosstalk` packages

### Output Conventions
- Figures: PNG format in `output/figures/`
- Tables: CSV and HTML in `output/tables/`
- Processed data: .rds format in `data/processed/` for efficient R storage
- Codebooks:
  - `docs/codebook.csv`: Raw variable labels from SPSS files
  - `docs/harmonization_codebook.csv`: Raw → harmonized → concept mappings

### Cross-Wave Analysis Best Practices
1. **Always load harmonized data**: Use `cambodia_all_waves_harmonized.rds`, not `cambodia_all_waves_clean.rds`
2. **Variable selection**: Use `*_harm` or concept names (e.g., `trust_executive`), never raw `q*` variables
3. **Scale awareness**: Mixed scales (4-point + 6-point) require careful interpretation - see `scripts/05_trust_scale_comparison.R`
4. **Validation workflow**:
   ```r
   # After harmonization changes
   source("scripts/05_harmonize_waves.R")
   source("scripts/verify_harmonization.R")
   # Check console output for directionality confirmation
   ```
5. **Quarto/haven compatibility**: Always use `haven::zap_labels()` or `as.numeric()` before `pivot_longer()` to avoid attribute conflicts
