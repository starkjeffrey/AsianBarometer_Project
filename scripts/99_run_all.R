# ==============================================================================
# 99_run_all.R
# Master script to run the entire analysis pipeline
# ==============================================================================

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════════╗\n")
cat("║                                                                   ║\n")
cat("║         ASIAN BAROMETER PROJECT - CAMBODIA ANALYSIS              ║\n")
cat("║                                                                   ║\n")
cat("╚═══════════════════════════════════════════════════════════════════╝\n")
cat("\n")

# Record start time
start_time <- Sys.time()

cat("Started at:", format(start_time, "%Y-%m-%d %H:%M:%S"), "\n\n")

# ---------------------
# Check if packages are installed
# ---------------------
cat("Checking package installation...\n")

required_packages <- c("here", "haven", "dplyr", "purrr", "ggplot2", "readr")
missing_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]

if (length(missing_packages) > 0) {
  cat("\n⚠️  MISSING PACKAGES DETECTED\n")
  cat("The following packages are not installed:\n")
  cat(paste("-", missing_packages, collapse = "\n"), "\n\n")
  cat("Please run scripts/00_setup.R first:\n")
  cat("  source('scripts/00_setup.R')\n\n")
  stop("Missing required packages. Please install them before continuing.")
} else {
  cat("✓ All required packages are installed\n\n")
}

# ---------------------
# Step 1: Data Import
# ---------------------
cat("═══════════════════════════════════════════════════════════════════\n")
cat("STEP 1/4: DATA IMPORT\n")
cat("═══════════════════════════════════════════════════════════════════\n")

tryCatch({
  source(here::here("scripts/01_data_import.R"))
  cat("\n✓ STEP 1 COMPLETE\n\n")
}, error = function(e) {
  cat("\n✗ ERROR IN STEP 1:", conditionMessage(e), "\n")
  cat("Please check that raw data files are in the correct location.\n\n")
  stop("Data import failed. Stopping pipeline.")
})

# ---------------------
# Step 2: Data Cleaning
# ---------------------
cat("═══════════════════════════════════════════════════════════════════\n")
cat("STEP 2/4: DATA CLEANING\n")
cat("═══════════════════════════════════════════════════════════════════\n")

tryCatch({
  source(here::here("scripts/02_data_cleaning.R"))
  cat("\n✓ STEP 2 COMPLETE\n\n")
}, error = function(e) {
  cat("\n✗ ERROR IN STEP 2:", conditionMessage(e), "\n\n")
  stop("Data cleaning failed. Stopping pipeline.")
})

# ---------------------
# Step 3: Analysis
# ---------------------
cat("═══════════════════════════════════════════════════════════════════\n")
cat("STEP 3/4: STATISTICAL ANALYSIS\n")
cat("═══════════════════════════════════════════════════════════════════\n")

tryCatch({
  source(here::here("scripts/03_analysis.R"))
  cat("\n✓ STEP 3 COMPLETE\n\n")
}, error = function(e) {
  cat("\n✗ ERROR IN STEP 3:", conditionMessage(e), "\n\n")
  stop("Analysis failed. Stopping pipeline.")
})

# ---------------------
# Step 4: Visualization
# ---------------------
cat("═══════════════════════════════════════════════════════════════════\n")
cat("STEP 4/4: VISUALIZATION\n")
cat("═══════════════════════════════════════════════════════════════════\n")

tryCatch({
  source(here::here("scripts/04_visualization.R"))
  cat("\n✓ STEP 4 COMPLETE\n\n")
}, error = function(e) {
  cat("\n✗ ERROR IN STEP 4:", conditionMessage(e), "\n\n")
  stop("Visualization failed. Stopping pipeline.")
})

# ---------------------
# Summary
# ---------------------
end_time <- Sys.time()
elapsed_time <- difftime(end_time, start_time, units = "mins")

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════════╗\n")
cat("║                                                                   ║\n")
cat("║                   🎉  PIPELINE COMPLETE!  🎉                     ║\n")
cat("║                                                                   ║\n")
cat("╚═══════════════════════════════════════════════════════════════════╝\n")
cat("\n")

cat("Completed at:", format(end_time, "%Y-%m-%d %H:%M:%S"), "\n")
cat("Total time:", round(elapsed_time, 2), "minutes\n\n")

cat("═══════════════════════════════════════════════════════════════════\n")
cat("OUTPUT SUMMARY\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

cat("📁 Processed Data:\n")
cat("   data/processed/cambodia_all_waves_clean.rds\n\n")

cat("📊 Tables:\n")
cat("   output/tables/data_quality_by_wave.csv\n")
cat("   output/tables/summary_statistics_by_wave.html\n")
cat("   output/tables/frequency_*.csv\n\n")

cat("📈 Figures:\n")
cat("   output/figures/distribution_*.png\n")
cat("   output/figures/trend_*.png\n")
cat("   output/figures/sample_sizes_by_wave.png\n\n")

cat("📖 Documentation:\n")
cat("   docs/codebook.csv\n\n")

cat("═══════════════════════════════════════════════════════════════════\n\n")

cat("To view results:\n")
cat("  - Open HTML table: output/tables/summary_statistics_by_wave.html\n")
cat("  - View figures: output/figures/\n")
cat("  - Check codebook: docs/codebook.csv\n\n")

# Clean up global environment
cat("Cleaning up environment...\n")
rm(start_time, end_time, elapsed_time, required_packages, missing_packages)

cat("\n✨ All done! ✨\n\n")
