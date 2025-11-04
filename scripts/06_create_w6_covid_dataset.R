# ==============================================================================
# Create W6 Cross-National COVID Dataset
# ==============================================================================
#
# Purpose: Merge Cambodia, Vietnam, and Thailand Wave 6 data for cross-national
#          COVID-19 and democracy comparison
#
# Output: data/processed/w6_covid_combined.rds
#
# ==============================================================================

library(haven)
library(dplyr)
library(here)
library(janitor)

source(here("functions/cleaning_functions.R"))

cat("\n=== Creating W6 Cross-National COVID Dataset ===\n\n")

# ============================================================================
# STEP 1: Load Wave 6 data for three countries
# ============================================================================

cat("Step 1: Loading Wave 6 data...\n")

cambodia <- read_sav(here("data/raw/W6_Cambodia_Release_20240819.sav"))
vietnam <- read_sav(here("data/raw/W6_11_Vietnam_Release_20250117.sav"))
thailand <- read_sav(here("data/raw/W6_8_Thailand_Release_20250108.sav"))

cat(sprintf("  Cambodia: %d observations, %d variables\n", nrow(cambodia), ncol(cambodia)))
cat(sprintf("  Vietnam: %d observations, %d variables\n", nrow(vietnam), ncol(vietnam)))
cat(sprintf("  Thailand: %d observations, %d variables\n", nrow(thailand), ncol(thailand)))
cat("\n")

# ============================================================================
# STEP 2: Standardize variable names
# ============================================================================

cat("Step 2: Standardizing variable names...\n")

cambodia <- clean_names(cambodia)
vietnam <- clean_names(vietnam)
thailand <- clean_names(thailand)

cat("  ✓ Variable names cleaned and standardized\n\n")

# ============================================================================
# STEP 3: Identify common variables
# ============================================================================

cat("Step 3: Identifying common variables...\n")

cambodia_vars <- names(cambodia)
vietnam_vars <- names(vietnam)
thailand_vars <- names(thailand)

# Find variables common to all three
common_vars <- Reduce(intersect, list(cambodia_vars, vietnam_vars, thailand_vars))

cat(sprintf("  Cambodia unique vars: %d\n", length(cambodia_vars)))
cat(sprintf("  Vietnam unique vars: %d\n", length(vietnam_vars)))
cat(sprintf("  Thailand unique vars: %d\n", length(thailand_vars)))
cat(sprintf("  Common to all three: %d\n", length(common_vars)))
cat("\n")

# Check COVID questions specifically
covid_questions <- paste0("q", c(138, 140, 141, 142, 144, 145, "143a", "143b", "143c", "143d", "143e", "172a"))

cat("Checking COVID questions:\n")
for (q in covid_questions) {
  in_cambodia <- q %in% cambodia_vars
  in_vietnam <- q %in% vietnam_vars
  in_thailand <- q %in% thailand_vars

  status <- ifelse(in_cambodia && in_vietnam && in_thailand, "✓ All three",
                   ifelse(in_cambodia || in_vietnam || in_thailand,
                          paste("⚠ Partial:",
                                paste(c(if(in_cambodia) "KH",
                                       if(in_vietnam) "VN",
                                       if(in_thailand) "TH"), collapse=" ")),
                          "✗ None"))

  cat(sprintf("  %s: %s\n", q, status))
}
cat("\n")

# ============================================================================
# STEP 4: Add country identifier and select common variables
# ============================================================================

cat("Step 4: Adding country identifiers and selecting common variables...\n")

# Function to standardize character/numeric conflicts
standardize_types <- function(df, common_vars) {
  # Check for type conflicts across datasets
  for (var in common_vars) {
    if (var %in% names(df)) {
      # Get the underlying data (remove haven_labelled class if present)
      var_data <- if (haven::is.labelled(df[[var]])) {
        haven::zap_labels(df[[var]])
      } else {
        df[[var]]
      }

      # If variable is character, try to convert to numeric
      if (is.character(var_data)) {
        numeric_test <- suppressWarnings(as.numeric(var_data))
        # Only convert if at least some values are numeric
        if (!all(is.na(numeric_test))) {
          df[[var]] <- numeric_test
        }
      }
    }
  }
  df
}

# Helper function to convert character to numeric while preserving labels when possible
convert_char_to_num <- function(x) {
  # If it's a labelled variable with character data, zap labels first
  if (haven::is.labelled(x)) {
    x_unlabelled <- haven::zap_labels(x)
    if (is.character(x_unlabelled)) {
      return(suppressWarnings(as.numeric(x_unlabelled)))
    } else {
      return(x)  # Keep original with labels if already numeric
    }
  }
  # If plain character, convert to numeric
  if (is.character(x)) {
    return(suppressWarnings(as.numeric(x)))
  }
  # Otherwise return as-is
  return(x)
}

cambodia_common <- cambodia %>%
  select(all_of(common_vars)) %>%
  mutate(across(everything(), convert_char_to_num)) %>%
  mutate(
    country_name = "Cambodia",
    country_code = 12,
    .before = 1
  )

vietnam_common <- vietnam %>%
  select(all_of(common_vars)) %>%
  mutate(across(everything(), convert_char_to_num)) %>%
  mutate(
    country_name = "Vietnam",
    country_code = 11,
    .before = 1
  )

thailand_common <- thailand %>%
  select(all_of(common_vars)) %>%
  mutate(across(everything(), convert_char_to_num)) %>%
  mutate(
    country_name = "Thailand",
    country_code = 8,
    .before = 1
  )

cat(sprintf("  Cambodia: %d rows x %d columns\n", nrow(cambodia_common), ncol(cambodia_common)))
cat(sprintf("  Vietnam: %d rows x %d columns\n", nrow(vietnam_common), ncol(vietnam_common)))
cat(sprintf("  Thailand: %d rows x %d columns\n", nrow(thailand_common), ncol(thailand_common)))
cat("\n")

# ============================================================================
# STEP 5: Combine datasets
# ============================================================================

cat("Step 5: Combining datasets...\n")

w6_covid <- bind_rows(cambodia_common, vietnam_common, thailand_common)

cat(sprintf("  Combined: %d rows x %d columns\n", nrow(w6_covid), ncol(w6_covid)))
cat(sprintf("  Countries: %s\n", paste(unique(w6_covid$country_name), collapse=", ")))
cat("\n")

# Verify country distribution
country_dist <- table(w6_covid$country_name)
cat("Country distribution:\n")
print(country_dist)
cat("\n")

# ============================================================================
# STEP 6: Apply label-based cleaning to key variables
# ============================================================================

cat("Step 6: Applying label-based NA cleaning...\n")

# Get all labelled variables
labelled_vars <- names(w6_covid)[sapply(w6_covid, haven::is.labelled)]

cat(sprintf("  Found %d labelled variables\n", length(labelled_vars)))

# Clean all labelled variables
for (var in labelled_vars) {
  w6_covid[[var]] <- clean_variable_by_label(w6_covid[[var]], na_labels_list)
}

cat("  ✓ Label-based cleaning applied\n\n")

# ============================================================================
# STEP 7: Generate summary statistics for COVID questions
# ============================================================================

cat("Step 7: Summary of COVID questions by country...\n\n")

# Check which COVID questions are available
available_covid <- covid_questions[covid_questions %in% names(w6_covid)]

if (length(available_covid) > 0) {
  cat("Available COVID questions:", paste(available_covid, collapse=", "), "\n\n")

  # Summary for each COVID question
  for (q in available_covid) {
    cat("==================================================\n")
    cat("Variable:", q, "\n")

    if (q %in% names(w6_covid)) {
      # Get variable label
      var_label <- attr(w6_covid[[q]], "label")
      if (!is.null(var_label)) {
        cat("Label:", var_label, "\n")
      }

      cat("\nBy country:\n")
      cross_tab <- table(w6_covid$country_name, w6_covid[[q]], useNA = "ifany")
      print(cross_tab)
      cat("\n")
    }
  }
} else {
  cat("⚠ WARNING: No COVID questions found in common variables!\n")
  cat("This may indicate different question numbering across countries.\n\n")
}

# ============================================================================
# STEP 8: Save merged dataset
# ============================================================================

cat("Step 8: Saving merged dataset...\n")

# Save as RDS
output_file <- here("data/processed/w6_covid_combined.rds")
saveRDS(w6_covid, output_file)

cat(sprintf("  ✓ Saved to: %s\n", output_file))
cat(sprintf("  File size: %.2f MB\n", file.size(output_file) / 1024^2))
cat("\n")

# ============================================================================
# STEP 9: Create summary report
# ============================================================================

cat("Step 9: Creating summary report...\n")

summary_stats <- w6_covid %>%
  group_by(country_name) %>%
  summarise(
    n_respondents = n(),
    n_variables = ncol(w6_covid) - 2,  # Exclude country identifiers
    .groups = "drop"
  )

cat("\n=== SUMMARY ===\n")
print(summary_stats)

cat("\n=== Dataset Ready ===\n")
cat("File: data/processed/w6_covid_combined.rds\n")
cat(sprintf("Total observations: %d\n", nrow(w6_covid)))
cat(sprintf("Total variables: %d\n", ncol(w6_covid)))
cat(sprintf("Countries: %d\n", length(unique(w6_covid$country_name))))
cat("\n")

cat("To load the dataset:\n")
cat("  w6_covid <- readRDS(here('data/processed/w6_covid_combined.rds'))\n\n")

cat("For cross-country COVID analysis:\n")
cat("  source('functions/concept_functions.R')\n")
cat("  covid_data <- extract_concepts(w6_covid, covid_concept_names, 'W6')\n\n")
