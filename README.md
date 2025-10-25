# Asian Barometer Analysis - Cambodia

## Project Overview
Analysis of Asian Barometer survey data for Cambodia across Waves 2, 3, 4, and 6.

## Data Sources
- **Wave 2**: Wave2_20250609/merge/Wave2_20250609.sav
- **Wave 3**: ABS3 merge20250609/ABS3 merge20250609.sav
- **Wave 4**: W4_v15_merged20250609_release/W4_v15_merged20250609_release.sav
- **Wave 6**: W6_12_Cambodia_20240819/W6_Cambodia_Release_20240819.sav

Source: [Asian Barometer Survey](http://www.asianbarometer.org/)

## Project Structure
```
AsianBarometer/
├── README.md                     # This file
├── AsianBarometer.Rproj         # RStudio project file
├── scripts/
│   ├── 00_setup.R               # One-time package installation
│   ├── 01_data_import.R         # Load and combine waves
│   ├── 02_data_cleaning.R       # Clean variables (q92-q95)
│   ├── 03_analysis.R            # Main statistical analysis
│   ├── 04_visualization.R       # Create plots
│   └── 99_run_all.R             # Master script to run everything
├── functions/
│   └── cleaning_functions.R     # Reusable helper functions
├── data/
│   ├── raw/                     # Original SPSS files (DO NOT MODIFY)
│   └── processed/               # Cleaned datasets (.rds files)
├── output/
│   ├── figures/                 # Saved plots
│   ├── tables/                  # Exported tables/CSVs
│   └── reports/                 # Generated reports
└── docs/
    └── codebook.csv             # Variable names and labels
```

## How to Run This Project

### First Time Setup
1. **Open the project**: Double-click `AsianBarometer.Rproj` in RStudio
2. **Install packages**: Run `source("scripts/00_setup.R")` once
3. **Add your data**: Place raw SPSS files in `data/raw/` folder

### Running the Analysis
**Option 1 - Run everything at once:**
```r
source("scripts/99_run_all.R")
```

**Option 2 - Run scripts individually:**
```r
source("scripts/01_data_import.R")    # Load data
source("scripts/02_data_cleaning.R")  # Clean variables
source("scripts/03_analysis.R")       # Analyze
source("scripts/04_visualization.R")  # Create plots
```

## Key Variables
- **q92-q95**: Main survey questions (cleaned versions: q92_clean, q93_clean, etc.)
- **wave**: Survey wave identifier (Wave2, Wave3, Wave4, Wave6)
- **country**: Country code (12 = Cambodia)

## Requirements
- R >= 4.0.0
- RStudio (recommended)
- Required packages listed in `scripts/00_setup.R`

## Notes
- All paths are relative to the project root (no absolute paths needed)
- Raw data files are never modified
- Processed data is saved in `.rds` format for fast loading
- Missing values: Codes >= 97 and 0 are treated as missing

## Author
Jeffrey Stark

## Last Updated
October 2025
