# ==============================================================================
# 02_data_cleaning.R
# Clean survey variables (q92-q95) by removing missing value codes
# ==============================================================================

cat("\n===== STARTING DATA CLEANING =====\n\n")

# Load required packages
library(here)
library(dplyr)
library(readr)

# Source helper functions
source(here("functions/cleaning_functions.R"))

# ---------------------
# Load combined data
# ---------------------
cat("Loading combined dataset...\n")
cambodia_all <- readRDS(here("data/processed/cambodia_all_waves.rds"))

cat("  ✓ Data loaded\n")
cat("  - Rows:", nrow(cambodia_all), "\n")
cat("  - Columns:", ncol(cambodia_all), "\n")

# ---------------------
# Check which variables exist
# ---------------------
cat("\nChecking for variables q92-q95...\n")
vars_to_clean <- c("q92", "q93", "q94", "q95")
vars_exist <- vars_to_clean %in% names(cambodia_all)

for (i in seq_along(vars_to_clean)) {
  var <- vars_to_clean[i]
  if (vars_exist[i]) {
    cat("  ✓", var, "exists\n")
  } else {
    cat("  ✗", var, "NOT FOUND\n")
  }
}

# Only clean variables that exist
vars_to_clean <- vars_to_clean[vars_exist]

if (length(vars_to_clean) == 0) {
  stop("ERROR: None of the target variables (q92-q95) were found in the data!")
}

# ---------------------
# Apply cleaning
# ---------------------
cat("\nCleaning variables...\n")
cat("  Treating as missing: 0, 97, 98, 99\n\n")

# Use the helper function to clean multiple variables at once
cambodia_all_clean <- clean_multiple_vars(
  data = cambodia_all,
  vars = vars_to_clean,
  suffix = "_clean",
  missing_codes = c(0, 97, 98, 99)
)

cat("  ✓ Created cleaned versions:\n")
for (var in vars_to_clean) {
  cat("    -", paste0(var, "_clean"), "\n")
}

# ---------------------
# Compare before and after
# ---------------------
cat("\n--- CLEANING SUMMARY ---\n\n")

for (var in vars_to_clean) {
  clean_var <- paste0(var, "_clean")
  
  cat("Variable:", var, "\n")
  
  # Original variable stats
  n_total <- sum(!is.na(cambodia_all[[var]]))
  n_missing_orig <- sum(is.na(cambodia_all[[var]]))
  
  # Cleaned variable stats
  n_valid <- sum(!is.na(cambodia_all_clean[[clean_var]]))
  n_missing_clean <- sum(is.na(cambodia_all_clean[[clean_var]]))
  n_removed <- n_total - n_valid
  
  cat("  Before cleaning:\n")
  cat("    - Valid responses:", n_total, "\n")
  cat("    - Already missing:", n_missing_orig, "\n")
  
  cat("  After cleaning:\n")
  cat("    - Valid responses:", n_valid, "\n")
  cat("    - Total missing:", n_missing_clean, "\n")
  cat("    - Removed as missing:", n_removed, 
      sprintf("(%.1f%% of original valid)", 100 * n_removed / n_total), "\n")
  
  if (n_valid > 0) {
    cat("  Range:", 
        min(cambodia_all_clean[[clean_var]], na.rm = TRUE), "-",
        max(cambodia_all_clean[[clean_var]], na.rm = TRUE), "\n")
  }
  cat("\n")
}

# ---------------------
# Get detailed statistics by wave
# ---------------------
cat("--- STATISTICS BY WAVE ---\n\n")

for (var in vars_to_clean) {
  clean_var <- paste0(var, "_clean")
  
  if (sum(!is.na(cambodia_all_clean[[clean_var]])) > 0) {
    cat("Variable:", clean_var, "\n")
    stats <- get_wave_summary(cambodia_all_clean, clean_var)
    print(stats, n = Inf)
    cat("\n")
  }
}

# ---------------------
# Save cleaned data
# ---------------------
cat("Saving cleaned dataset...\n")
saveRDS(cambodia_all_clean, here("data/processed/cambodia_all_waves_clean.rds"))

cat("  ✓ Saved to: data/processed/cambodia_all_waves_clean.rds\n")

# Also export a CSV for easy viewing
cat("\nExporting CSV sample (first 1000 rows)...\n")
cambodia_all_clean %>%
  select(source_wave, wave, country, 
         starts_with("q9"), 
         ends_with("_clean")) %>%
  head(1000) %>%
  write_csv(here("output/tables/cambodia_sample_with_clean_vars.csv"))

cat("  ✓ Saved to: output/tables/cambodia_sample_with_clean_vars.csv\n")

cat("\n===== DATA CLEANING COMPLETE =====\n\n")

# Clean up
rm(cambodia_all, vars_to_clean, vars_exist, var, clean_var, 
   n_total, n_missing_orig, n_valid, n_missing_clean, n_removed, stats)

cat("Next step: Run scripts/03_analysis.R\n\n")
