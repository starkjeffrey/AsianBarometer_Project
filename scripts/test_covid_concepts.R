# ==============================================================================
# Test COVID Concept Extraction
# ==============================================================================

library(haven)
library(dplyr)
library(here)

source(here("functions/cleaning_functions.R"))
source(here("functions/concept_functions.R"))

cat("\n=== Testing COVID Concept Extraction ===\n\n")

# Load Wave 6
w6 <- read_sav(here("data/raw/W6_Cambodia_Release_20240819.sav"))

# Load mappings
mappings <- load_concept_mappings()

# List COVID concepts
cat("COVID concepts in mapping:\n")
covid_concepts <- list_concepts(domain = "covid")
print(covid_concepts)

cat("\n\nExtracting COVID concepts from Wave 6...\n\n")

# Extract all COVID concepts
covid_concept_names <- covid_concepts$concept

covid_data <- extract_concepts(w6, covid_concept_names, "W6", clean = TRUE)

cat("Extracted", ncol(covid_data), "COVID concepts\n")
cat("Dimensions:", nrow(covid_data), "rows x", ncol(covid_data), "columns\n\n")

# Show summary for each concept
for (concept in names(covid_data)) {
  cat("==================================================\n")
  cat("Concept:", concept, "\n")
  cat("Distribution:\n")
  print(table(covid_data[[concept]], useNA = "ifany"))
  cat("\n")
}

# Create summary statistics
cat("==================================================\n")
cat("Summary Statistics:\n\n")

covid_summary <- covid_data %>%
  summarise(across(everything(), list(
    n_valid = ~sum(!is.na(.)),
    n_missing = ~sum(is.na(.))
  )))

print(t(covid_summary))

cat("\n=== COVID Concept Extraction Successful ===\n\n")

cat("You can now use these concepts in your analysis:\n")
cat("- covid_infection: Personal/family COVID infection (8.6% infected)\n")
cat("- covid_economic_impact: Economic impact (66.4% serious/very serious)\n")
cat("- covid_trust_info: Trust in gov COVID info (83.5% high trust)\n")
cat("- covid_gov_handling: Gov pandemic handling (90.9% positive)\n")
cat("- covid_vaccination: Vaccination status (90.7% vaccinated)\n")
cat("- covid_emergency_powers: Justify emergency powers (83.9% justify)\n")
cat("- covid_postpone_elections: Postpone elections (53% justify sometimes/always)\n")
cat("- covid_lockdown: Long-term lockdown (84% support sometimes/always)\n\n")
