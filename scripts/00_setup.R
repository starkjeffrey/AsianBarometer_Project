# ==============================================================================
# 00_setup.R
# One-time package installation script
# Run this once when you first set up the project on a new machine
# ==============================================================================

cat("===== ASIAN BAROMETER PROJECT SETUP =====\n\n")

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org"))

# List of all required packages
packages_needed <- c(
  # Data manipulation
  "dplyr",
  "purrr",
  "tidyr",
  
  # Data import/export
  "readr",
  "haven",
  
  # Data cleaning
  "janitor",
  "labelled",
  
  # Path management
  "here",
  
  # Analysis
  "survey",
  "srvyr",
  
  # Exploration
  "skimr",
  "naniar",
  "DataExplorer",
  "GGally",
  
  # Visualization
  "ggplot2",
  "FactoMineR",
  "factoextra",
  
  # Tables
  "gtsummary",
  
  # Shiny (if needed)
  "shiny"
)

# Check which packages are missing
missing_packages <- packages_needed[!(packages_needed %in% installed.packages()[, "Package"])]

# Install missing packages
if (length(missing_packages) > 0) {
  cat("Installing missing packages:\n")
  cat(paste("-", missing_packages, collapse = "\n"), "\n\n")
  
  install.packages(missing_packages, dependencies = TRUE)
  
  cat("\n✓ Package installation complete!\n")
} else {
  cat("✓ All required packages are already installed.\n")
}

# Verify installation
cat("\n===== VERIFICATION =====\n")
all_installed <- all(packages_needed %in% installed.packages()[, "Package"])

if (all_installed) {
  cat("✓ All packages successfully installed and ready to use.\n")
  cat("\nYou can now run the analysis scripts:\n")
  cat("  - scripts/01_data_import.R\n")
  cat("  - scripts/02_data_cleaning.R\n")
  cat("  - scripts/03_analysis.R\n")
  cat("  - scripts/04_visualization.R\n")
  cat("\nOr run everything at once:\n")
  cat("  - scripts/99_run_all.R\n")
} else {
  cat("✗ Some packages failed to install. Please check for errors above.\n")
}

cat("\n=====================================\n")
