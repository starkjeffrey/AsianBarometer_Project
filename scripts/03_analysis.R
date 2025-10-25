# ==============================================================================
# 03_analysis.R
# Statistical analysis of cleaned survey data
# ==============================================================================

cat("\n===== STARTING ANALYSIS =====\n\n")

# Load required packages
library(here)
library(dplyr)
library(tidyr)
library(readr)
library(gtsummary)
library(skimr)

# Source helper functions
source(here("functions/cleaning_functions.R"))

# ---------------------
# Load cleaned data
# ---------------------
cat("Loading cleaned dataset...\n")
cambodia_all_clean <- readRDS(here("data/processed/cambodia_all_waves_clean.rds"))

cat("  ✓ Data loaded\n")
cat("  - Rows:", nrow(cambodia_all_clean), "\n")
cat("  - Waves:", paste(unique(cambodia_all_clean$wave), collapse = ", "), "\n\n")

# ---------------------
# Descriptive Statistics
# ---------------------
cat("=== DESCRIPTIVE STATISTICS ===\n\n")

# Overall summary
cat("--- Overall Data Quality ---\n")
data_quality <- cambodia_all_clean %>%
  select(wave, ends_with("_clean")) %>%
  group_by(wave) %>%
  summarise(
    n_respondents = n(),
    across(
      ends_with("_clean"),
      list(
        valid = ~sum(!is.na(.)),
        pct_valid = ~round(100 * sum(!is.na(.)) / n(), 1)
      ),
      .names = "{.col}_{.fn}"
    ),
    .groups = "drop"
  )

print(data_quality)
cat("\n")

# Detailed statistics for each cleaned variable
cat("--- Variable Distributions ---\n\n")

clean_vars <- names(cambodia_all_clean)[grepl("_clean$", names(cambodia_all_clean))]

for (var in clean_vars) {
  cat("Variable:", var, "\n")
  
  # Frequency distribution
  freq_table <- cambodia_all_clean %>%
    filter(!is.na(!!sym(var))) %>%
    count(!!sym(var), name = "n") %>%
    mutate(
      percent = round(100 * n / sum(n), 1)
    ) %>%
    arrange(!!sym(var))
  
  print(freq_table, n = Inf)
  cat("\n")
}

# ---------------------
# Cross-wave Comparisons
# ---------------------
cat("=== CROSS-WAVE COMPARISONS ===\n\n")

# Create summary table for each variable across waves
for (var in clean_vars) {
  cat("Variable:", var, "by Wave\n")
  
  wave_comparison <- cambodia_all_clean %>%
    filter(!is.na(!!sym(var))) %>%
    group_by(wave, !!sym(var)) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(wave) %>%
    mutate(
      percent = round(100 * n / sum(n), 1)
    ) %>%
    pivot_wider(
      names_from = wave,
      values_from = c(n, percent),
      names_glue = "{wave}_{.value}"
    )
  
  print(wave_comparison, n = Inf)
  cat("\n")
}

# ---------------------
# Statistical Tests
# ---------------------
cat("=== STATISTICAL TESTS ===\n\n")

cat("Testing for differences across waves...\n\n")

for (var in clean_vars) {
  cat("Variable:", var, "\n")
  
  # Check if variable has sufficient data
  n_valid <- sum(!is.na(cambodia_all_clean[[var]]))
  
  if (n_valid >= 30) {
    # Chi-square test for independence
    test_data <- cambodia_all_clean %>%
      filter(!is.na(!!sym(var))) %>%
      select(wave, !!sym(var))
    
    # Create contingency table
    cont_table <- table(test_data$wave, test_data[[var]])
    
    # Only run test if we have at least 2 waves and 2 response categories
    if (nrow(cont_table) >= 2 && ncol(cont_table) >= 2) {
      chi_test <- chisq.test(cont_table)
      
      cat("  Chi-square test: X² =", round(chi_test$statistic, 2), 
          ", df =", chi_test$parameter, 
          ", p =", format.pval(chi_test$p.value, digits = 3), "\n")
      
      if (chi_test$p.value < 0.05) {
        cat("  *** Significant difference across waves (p < 0.05)\n")
      } else {
        cat("  No significant difference across waves\n")
      }
    } else {
      cat("  Insufficient variation for chi-square test\n")
    }
  } else {
    cat("  Insufficient data (n =", n_valid, ")\n")
  }
  cat("\n")
}

# ---------------------
# Create Summary Tables
# ---------------------
cat("=== CREATING SUMMARY TABLES ===\n\n")

# Create a publication-ready table using gtsummary
cat("Creating formatted summary table...\n")

summary_table <- cambodia_all_clean %>%
  select(wave, ends_with("_clean")) %>%
  tbl_summary(
    by = wave,
    missing = "no",
    statistic = list(all_continuous() ~ "{mean} ({sd})",
                     all_categorical() ~ "{n} ({p}%)"),
    digits = list(all_continuous() ~ 2,
                  all_categorical() ~ c(0, 1))
  ) %>%
  add_overall() %>%
  add_p() %>%
  bold_labels()

# Save the table
gt_table <- as_gt(summary_table)
gt::gtsave(gt_table, here("output/tables/summary_statistics_by_wave.html"))

cat("  ✓ Saved HTML table to: output/tables/summary_statistics_by_wave.html\n")

# ---------------------
# Export Results
# ---------------------
cat("\nExporting analysis results...\n")

# Export data quality summary
write_csv(data_quality, here("output/tables/data_quality_by_wave.csv"))
cat("  ✓ Data quality: output/tables/data_quality_by_wave.csv\n")

# Export detailed frequency tables
for (var in clean_vars) {
  freq_table <- cambodia_all_clean %>%
    filter(!is.na(!!sym(var))) %>%
    count(wave, !!sym(var), name = "n") %>%
    group_by(wave) %>%
    mutate(percent = round(100 * n / sum(n), 1)) %>%
    arrange(wave, !!sym(var))
  
  filename <- paste0("frequency_", var, ".csv")
  write_csv(freq_table, here("output/tables", filename))
  cat("  ✓ Frequency table:", filename, "\n")
}

cat("\n===== ANALYSIS COMPLETE =====\n\n")

cat("Next step: Run scripts/04_visualization.R\n\n")
