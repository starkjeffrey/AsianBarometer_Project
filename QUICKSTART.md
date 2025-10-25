# 🚀 Quick Start Guide

## Installation (One-Time Setup)

### Step 1: Download and Unzip This Project
Extract the project folder to your desired location (e.g., Documents folder)

### Step 2: Open in RStudio
- Double-click `AsianBarometer.Rproj` to open the project in RStudio
- This automatically sets the working directory correctly

### Step 3: Install Required Packages
In RStudio console, run:
```r
source("scripts/00_setup.R")
```

This will install all necessary packages. **You only need to do this once.**

### Step 4: Add Your Data Files
Place your raw SPSS (.sav) files in the `data/raw/` folder:

```
data/raw/
├── Wave2_20250609/
│   └── merge/
│       └── Wave2_20250609.sav
├── ABS3 merge20250609/
│   └── ABS3 merge20250609.sav
├── W4_v15_merged20250609_release/
│   └── W4_v15_merged20250609_release.sav
└── W6_12_Cambodia_20240819/
    └── W6_Cambodia_Release_20240819.sav
```

**Note:** If your folder structure is different, edit the paths in `scripts/01_data_import.R`

---

## Running the Analysis

### Option 1: Run Everything at Once (Recommended)
```r
source("scripts/99_run_all.R")
```

This will:
1. Load all data files
2. Clean variables (q92-q95)
3. Perform statistical analysis
4. Create visualizations

### Option 2: Run Step-by-Step
```r
source("scripts/01_data_import.R")      # Load data
source("scripts/02_data_cleaning.R")    # Clean variables
source("scripts/03_analysis.R")         # Analyze
source("scripts/04_visualization.R")    # Create plots
```

---

## Where to Find Your Results

After running the analysis, check these folders:

📊 **Tables** → `output/tables/`
- `data_quality_by_wave.csv` - Missing data summary
- `summary_statistics_by_wave.html` - Formatted summary table (open in browser)
- `frequency_*.csv` - Frequency distributions

📈 **Figures** → `output/figures/`
- `distribution_*.png` - Bar charts by wave
- `trend_*.png` - Line graphs across waves
- `sample_sizes_by_wave.png` - Valid responses
- `correlation_matrix.png` - Variable relationships

📁 **Processed Data** → `data/processed/`
- `cambodia_all_waves_clean.rds` - Cleaned dataset (for further analysis)

📖 **Codebook** → `docs/codebook.csv`
- Variable names and labels from all waves

---

## Troubleshooting

### "Error: could not find function"
**Problem:** Packages not installed
**Solution:** Run `source("scripts/00_setup.R")`

### "Error: cannot open file"
**Problem:** Data files not in correct location
**Solution:** Check that .sav files are in `data/raw/` folder

### "Error: object 'here' not found"
**Problem:** Not using RStudio Project
**Solution:** Open `AsianBarometer.Rproj` instead of individual .R files

### Script runs but variables not found (q92, q93, etc.)
**Problem:** Variables may have different names in your data
**Solution:** 
1. Check `docs/codebook.csv` for actual variable names
2. Update variable names in `scripts/02_data_cleaning.R`

---

## Customizing the Analysis

### Change Which Variables to Clean
Edit `scripts/02_data_cleaning.R`:
```r
# Line ~35: Change these variable names
vars_to_clean <- c("q92", "q93", "q94", "q95")
```

### Change Missing Value Codes
Edit `scripts/02_data_cleaning.R`:
```r
# Line ~53: Change which codes are treated as missing
missing_codes = c(0, 97, 98, 99)
```

### Add More Waves
Edit `scripts/01_data_import.R` and add:
```r
# Load Wave X
cambodia_wX <- read_sav(here("data/raw/WaveX/file.sav")) %>%
  filter(country == 12) %>%
  mutate(wave = "WaveX") %>%
  janitor::clean_names()

# Add to the bind_rows() section
cambodia_all <- bind_rows(
  cambodia_w2,
  cambodia_w3,
  cambodia_w4,
  cambodia_w6,
  cambodia_wX  # <- Add your new wave here
)
```

---

## Need Help?

1. Check `README.md` for full documentation
2. Look at comments in each script file
3. Review `functions/cleaning_functions.R` for helper functions

---

## What Changed from Your Original Script?

✅ **No more `setwd()`** - Uses RStudio Projects instead
✅ **No more absolute paths** - Uses `here()` package
✅ **Split into logical steps** - Easier to debug
✅ **Fixed the bug** - Your original code referenced `data_all` but created `all_waves`
✅ **Reusable functions** - Don't repeat yourself
✅ **Better organization** - Raw data protected, outputs organized
✅ **Documented** - Clear comments and README
✅ **Reproducible** - Works on any computer

---

**Last Updated:** October 2025
