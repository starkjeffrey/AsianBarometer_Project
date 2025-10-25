# ==============================================================================
# 01_data_import.R
# Load and combine all waves of Asian Barometer data for Cambodia
# ==============================================================================

cat("\n===== STARTING DATA IMPORT =====\n\n")

# Load required packages
library(here)
library(haven)
library(dplyr)
library(purrr)
library(janitor)
library(labelled)
library(readr)

# Source helper functions
source(here("functions/cleaning_functions.R"))

# Define paths to raw data files
# NOTE: Adjust these paths if your folder structure is different
wave2_path <- here("data/raw/Wave2_20250609/merge/Wave2_20250609.sav")
wave3_path <- here("data/raw/ABS3 merge20250609/ABS3 merge20250609.sav")
wave4_path <- here("data/raw/W4_v15_merged20250609_release/W4_v15_merged20250609_release.sav")
wave6_path <- here("data/raw/W6_12_Cambodia_20240819/W6_Cambodia_Release_20240819.sav")

# Check if files exist
cat("Checking for data files...\n")
files_to_check <- list(
  "Wave 2" = wave2_path,
  "Wave 3" = wave3_path,
  "Wave 4" = wave4_path,
  "Wave 6" = wave6_path
)

for (wave_name in names(files_to_check)) {
  if (file.exists(files_to_check[[wave_name]])) {
    cat("  ✓", wave_name, "found\n")
  } else {
    cat("  ✗", wave_name, "NOT FOUND:", files_to_check[[wave_name]], "\n")
  }
}

# ---------------------
# Load Wave 2
# ---------------------
cat("\nLoading Wave 2...\n")
cambodia_w2 <- read_sav(wave2_path) %>%
  filter(country == 12) %>%  # Cambodia country code
  mutate(wave = "Wave2") %>%
  janitor::clean_names()      # Standardize variable names

cat("  - Rows:", nrow(cambodia_w2), "\n")
cat("  - Columns:", ncol(cambodia_w2), "\n")

# ---------------------
# Load Wave 3
# ---------------------
cat("\nLoading Wave 3...\n")
cambodia_w3 <- read_sav(wave3_path) %>%
  filter(country == 12) %>%
  mutate(wave = "Wave3") %>%
  janitor::clean_names()

cat("  - Rows:", nrow(cambodia_w3), "\n")
cat("  - Columns:", ncol(cambodia_w3), "\n")

# ---------------------
# Load Wave 4
# ---------------------
cat("\nLoading Wave 4...\n")
cambodia_w4 <- read_sav(wave4_path) %>%
  filter(country == 12) %>%
  mutate(wave = "Wave4") %>%
  janitor::clean_names()

cat("  - Rows:", nrow(cambodia_w4), "\n")
cat("  - Columns:", ncol(cambodia_w4), "\n")

# ---------------------
# Load Wave 6
# ---------------------
cat("\nLoading Wave 6...\n")
cambodia_w6 <- read_sav(wave6_path) %>%
  mutate(wave = "Wave6") %>%  # No country filter needed for Wave 6
  janitor::clean_names()

cat("  - Rows:", nrow(cambodia_w6), "\n")
cat("  - Columns:", ncol(cambodia_w6), "\n")

# ---------------------
# Create list of waves for codebook export
# ---------------------
list_of_waves <- list(
  Wave2 = cambodia_w2,
  Wave3 = cambodia_w3,
  Wave4 = cambodia_w4,
  Wave6 = cambodia_w6
)

# ---------------------
# Export variable codebook
# ---------------------
cat("\nExporting variable codebook...\n")
codebook_path <- here("docs/codebook.csv")
codebook <- export_codebook(list_of_waves, codebook_path)

cat("  ✓ Codebook saved:", codebook_path, "\n")
cat("  - Total unique variables:", nrow(codebook), "\n")

# ---------------------
# Combine all waves
# ---------------------
cat("\nCombining all waves...\n")
cambodia_all <- bind_rows(
  cambodia_w2,
  cambodia_w3,
  cambodia_w4,
  cambodia_w6,
  .id = "source_wave"
)

cat("  ✓ Combined dataset created\n")
cat("  - Total rows:", nrow(cambodia_all), "\n")
cat("  - Total columns:", ncol(cambodia_all), "\n")

# ---------------------
# Summary by wave
# ---------------------
cat("\nSummary by wave:\n")
wave_summary <- cambodia_all %>%
  group_by(wave) %>%
  summarise(
    n_respondents = n(),
    .groups = "drop"
  )
print(wave_summary)

# ---------------------
# Save processed data
# ---------------------
cat("\nSaving processed data...\n")

# Save individual waves
saveRDS(cambodia_w2, here("data/processed/cambodia_w2.rds"))
saveRDS(cambodia_w3, here("data/processed/cambodia_w3.rds"))
saveRDS(cambodia_w4, here("data/processed/cambodia_w4.rds"))
saveRDS(cambodia_w6, here("data/processed/cambodia_w6.rds"))

# Save combined dataset
saveRDS(cambodia_all, here("data/processed/cambodia_all_waves.rds"))

cat("  ✓ Data saved to data/processed/\n")
cat("  - cambodia_w2.rds\n")
cat("  - cambodia_w3.rds\n")
cat("  - cambodia_w4.rds\n")
cat("  - cambodia_w6.rds\n")
cat("  - cambodia_all_waves.rds\n")

cat("\n===== DATA IMPORT COMPLETE =====\n\n")

# Clean up environment (optional - keeps only combined data)
rm(cambodia_w2, cambodia_w3, cambodia_w4, cambodia_w6, list_of_waves)
rm(wave2_path, wave3_path, wave4_path, wave6_path, files_to_check, wave_name)

cat("Next step: Run scripts/02_data_cleaning.R\n\n")
