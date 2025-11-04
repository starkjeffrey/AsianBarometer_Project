# Concept Mapping System Guide

## Overview

The **concept mapping system** allows you to work with theoretical constructs (concepts) across waves, even though the same concept may be measured by different question numbers in different waves.

### The Problem It Solves

```
Wave 2: Trust in executive = q7
Wave 3: Trust in executive = q7
Wave 4: Trust in executive = q7  (but REVERSED scale!)
Wave 5: Trust in executive = q7  (6-point scale)
Wave 6: Trust in executive = q7

Democracy satisfaction: q93 (W2), q89 (W3), q92 (W4), q90 (W5), q92 (W6)
```

**Without concept mapping**: You'd need to remember all these mappings and handle them manually.

**With concept mapping**: Just use `get_concept(data, "trust_executive", "W3")` and it handles everything.

## System Components

### 1. Concept Mappings File (`docs/concept_mappings.csv`)

The master registry of concepts:

```csv
concept,domain,description,w2_var,w3_var,w4_var,w5_var,w6_var,scale_type,direction,notes
trust_executive,trust,Trust in executive,q7,q7,q7,q7,q7,mixed,higher_more,"W2/W4/W6=4pt, W3/W5=6pt"
econ_country_current,economic,Country economic condition,q1,q1,q1,q1,q1,5-point,higher_better,W4 reversed
```

**Fields**:
- `concept`: Unique identifier (lowercase, underscores)
- `domain`: Category (trust, economic, democracy, politics)
- `description`: Human-readable description
- `w2_var` through `w6_var`: Variable names in each wave (blank if not in that wave)
- `scale_type`: Response scale (4-point, 5-point, mixed, varies)
- `direction`: Interpretation (higher_more, higher_better)
- `notes`: Comparability issues, scale differences

### 2. Concept Functions (`functions/concept_functions.R`)

Core functions for working with concepts:

| Function | Purpose |
|----------|---------|
| `load_concept_mappings()` | Load the CSV file |
| `get_concept_variable(concept, wave)` | Get variable name for concept in wave |
| `get_concept(data, concept, wave)` | Extract concept data from a wave |
| `get_concept_all_waves(concept, waves)` | Extract concept from all waves |
| `list_concepts(domain, wave)` | Browse available concepts |
| `list_wave_concepts(wave)` | List concepts in a specific wave |
| `extract_concepts(data, concepts, wave)` | Extract multiple concepts |
| `validate_concept(data, concept, wave)` | Check if concept is available |

### 3. Quarto Tools

#### Wave Explorer (`wave_explorer_template.qmd`)
- Browse all variables in a wave
- Discover concepts by domain (trust, economic, etc.)
- Find NA label patterns
- Identify unmapped variables
- Validate existing mappings

#### Concept Builder (`concept_builder.qmd`)
- View all mappings
- Validate across waves
- Compare distributions
- Document new concepts
- Extract examples

## Workflow

### Phase 1: Discovery (Per Wave)

```r
# Render wave explorer
quarto::quarto_render(
  "wave_explorer_template.qmd",
  execute_params = list(
    wave = "W3",
    wave_file = "data/raw/ABS3 merge20250609.sav"
  ),
  output_file = "wave3_explorer.html"
)
```

**Actions**:
1. Browse variables and their labels
2. Find concepts (trust, economic, democracy)
3. Note variable names for each concept
4. Identify new NA label patterns
5. Add patterns to `na_labels_list` in `cleaning_functions.R`

### Phase 2: Mapping

Edit `docs/concept_mappings.csv` to add new concepts:

```csv
new_concept,politics,Political efficacy,q45,q47,q48,q46,q49,4-point,higher_more,""
```

**Guidelines**:
- Use descriptive concept names
- Assign to appropriate domain
- Map all available waves
- Document scale differences
- Note comparability issues

### Phase 3: Validation

```r
# Open concept_builder.qmd in RStudio
# Or render it:
quarto::quarto_render("concept_builder.qmd")
```

**Check**:
- Variables exist in data
- Distributions look reasonable
- Cross-wave comparability
- NA patterns handled correctly

### Phase 4: Analysis

Use concepts in your Quarto analysis documents:

```r
library(haven)
library(dplyr)
library(here)

source(here("functions/cleaning_functions.R"))
source(here("functions/concept_functions.R"))

# Load data
w3 <- read_sav(here("data/raw/ABS3 merge20250609.sav"))

# Extract single concept
trust <- get_concept(w3, "trust_executive", "W3", clean = TRUE)

# Extract multiple concepts
trust_concepts <- c("trust_executive", "trust_legislature", "trust_courts")
trust_data <- extract_concepts(w3, trust_concepts, "W3", clean = TRUE)

# Cross-wave analysis
waves <- list(
  W2 = read_sav(here("data/raw/Wave2_20250609.sav")) %>% filter(country == 12),
  W3 = read_sav(here("data/raw/ABS3 merge20250609.sav")) %>% filter(country == 12),
  # ... etc
)

trust_all_waves <- get_concept_all_waves("trust_executive", waves, clean = TRUE)

# Analyze
trust_all_waves %>%
  group_by(wave) %>%
  summarise(mean_trust = mean(trust_executive, na.rm = TRUE))
```

## Example Usage

### Example 1: Extract Economic Perceptions from Wave 3

```r
# Load data and functions
w3 <- read_sav(here("data/raw/ABS3 merge20250609.sav"))
source(here("functions/concept_functions.R"))

# Get all economic concepts
mappings <- load_concept_mappings()
econ_concepts <- mappings %>%
  filter(domain == "economic") %>%
  pull(concept)

# Extract them
econ_data <- extract_concepts(w3, econ_concepts, "W3", clean = TRUE)

# Analyze
summary(econ_data)
```

### Example 2: Compare Trust Across Waves

```r
# Load all waves
waves <- list(
  W2 = read_sav(here("data/raw/Wave2_20250609.sav")) %>% filter(country == 12),
  W3 = read_sav(here("data/raw/ABS3 merge20250609.sav")) %>% filter(country == 12),
  W4 = read_sav(here("data/raw/W4_v15_merged20250609_release.sav")) %>% filter(country == 12),
  W5 = read_sav(here("data/raw/20230505_W5_merge_15.sav")) %>% filter(COUNTRY == 12),
  W6 = read_sav(here("data/raw/W6_Cambodia_Release_20240819.sav"))
)

# Get trust in executive across all waves
trust_exec_all <- get_concept_all_waves("trust_executive", waves, clean = TRUE)

# Plot
library(ggplot2)
ggplot(trust_exec_all, aes(x = as.factor(trust_executive), fill = wave)) +
  geom_bar(position = "dodge") +
  labs(title = "Trust in Executive Across Waves",
       x = "Response (higher = more trust)",
       y = "Count")
```

### Example 3: Build Domain-Specific Dataset

```r
# Extract all trust concepts from Wave 3
trust_concepts <- list_concepts(domain = "trust") %>% pull(concept)
trust_w3 <- extract_concepts(w3, trust_concepts, "W3", clean = TRUE)

# Add wave identifier and other variables
trust_w3 <- trust_w3 %>%
  mutate(
    wave = "W3",
    respondent_id = row_number()
  )

# Save for analysis
saveRDS(trust_w3, here("data/processed/trust_w3.rds"))
```

## Best Practices

### 1. Concept Naming
- Use lowercase with underscores: `trust_executive`, not `TrustExecutive`
- Be specific: `econ_country_current` not just `economic`
- Use consistent prefixes: `trust_*`, `econ_*`, `democracy_*`

### 2. Mapping Strategy
- Start with concepts that appear in all waves
- Document scale changes (4-point vs 6-point)
- Note reversed scales in raw data
- Test extraction before assuming it works

### 3. Documentation
- Always fill in the `notes` field for non-trivial cases
- Document why certain waves lack a concept
- Note when question wording changes significantly

### 4. Validation
- Always validate after adding new mappings
- Check distributions look reasonable
- Compare means/medians across waves for sanity
- Use concept_builder.qmd regularly

### 5. Analysis
- Always use `clean = TRUE` to apply label-based NA conversion
- Keep variables as haven_labelled until final analysis
- Use concept names in your code, not question numbers
- Document which concepts you're using

## Advantages

1. **Maintainability**: Change a mapping once, applies everywhere
2. **Readability**: `get_concept(data, "trust_executive")` is clearer than `data$q7`
3. **Robustness**: Handles wave differences automatically
4. **Documentation**: Mappings document your decisions
5. **Flexibility**: Easy to add new concepts or waves
6. **Integration**: Works seamlessly with label-based cleaning

## Troubleshooting

### Concept not found
```r
# Check if concept exists
mappings <- load_concept_mappings()
"trust_executive" %in% mappings$concept

# List all concepts
list_concepts()
```

### Variable not in wave
```r
# Check what's mapped
get_concept_variable("trust_executive", "W3")

# Validate
validate_concept(w3, "trust_executive", "W3")
```

### Wrong values extracted
```r
# Check variable info
var_name <- get_concept_variable("trust_executive", "W3")
attr(w3[[var_name]], "label")
attr(w3[[var_name]], "labels")

# Check cleaning
trust_raw <- w3[[var_name]]
trust_clean <- clean_variable_by_label(trust_raw, na_labels_list)
table(trust_raw, useNA = "ifany")
table(trust_clean, useNA = "ifany")
```

## Next Steps

1. **Explore all waves**: Run wave_explorer_template.qmd for W2, W4, W5, W6
2. **Build complete mappings**: Add all important concepts to concept_mappings.csv
3. **Validate thoroughly**: Use concept_builder.qmd to check everything
4. **Start analyzing**: Use concepts in your Quarto analysis documents
5. **Document findings**: Note any comparability issues you discover
