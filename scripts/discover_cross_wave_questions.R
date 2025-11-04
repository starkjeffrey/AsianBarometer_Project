# ==============================================================================
# Discover Cross-Wave Question Similarities
# ==============================================================================
#
# Purpose: Systematically identify questions that appear across multiple waves
#          using label text similarity and value structure
#
# Methods:
#   1. Exact label matching (same question text)
#   2. Partial text matching (common keywords)
#   3. Value label matching (same response options)
#   4. Question number pattern matching
#
# Output: Candidate mappings for manual review and addition to concept_mappings.csv
#
# ==============================================================================

library(haven)
library(dplyr)
library(here)
library(tidyr)

cat("\n=== Cross-Wave Question Discovery Tool ===\n\n")

# ==============================================================================
# STEP 1: Load all waves and extract metadata
# ==============================================================================

cat("Step 1: Loading wave data and extracting metadata...\n")

# Load all waves
waves <- list(
  W2 = read_sav(here("data/raw/Wave2_20250609.sav")),
  W3 = read_sav(here("data/raw/ABS3 merge20250609.sav")),
  W4 = read_sav(here("data/raw/W4_v15_merged20250609_release.sav")),
  W5 = read_sav(here("data/raw/20230505_W5_merge_15.sav")),
  W6 = read_sav(here("data/raw/W6_Cambodia_Release_20240819.sav"))
)

# Filter Cambodia only for W2-W5
waves$W2 <- waves$W2 %>% filter(country == 12)
waves$W3 <- waves$W3 %>% filter(country == 12)
waves$W4 <- waves$W4 %>% filter(country == 12)
waves$W5 <- waves$W5 %>% filter(COUNTRY == 12)

cat(sprintf("  Loaded %d waves\n", length(waves)))
cat("\n")

# ==============================================================================
# STEP 2: Extract variable metadata from each wave
# ==============================================================================

cat("Step 2: Extracting variable metadata...\n")

extract_metadata <- function(wave_data, wave_name) {
  var_names <- names(wave_data)

  metadata <- data.frame(
    wave = wave_name,
    var_name = var_names,
    var_label = sapply(var_names, function(v) {
      label <- attr(wave_data[[v]], "label")
      if (is.null(label)) "" else as.character(label)
    }),
    n_unique = sapply(var_names, function(v) {
      length(unique(wave_data[[v]][!is.na(wave_data[[v]])]))
    }),
    value_labels = sapply(var_names, function(v) {
      val_labs <- attr(wave_data[[v]], "labels")
      if (is.null(val_labs) || length(val_labs) == 0) {
        ""
      } else {
        paste(names(val_labs), collapse = " | ")
      }
    }),
    stringsAsFactors = FALSE
  )

  # Clean labels for comparison
  metadata$var_label_clean <- tolower(trimws(metadata$var_label))
  metadata$var_label_clean <- gsub("[[:punct:]]", " ", metadata$var_label_clean)
  metadata$var_label_clean <- gsub("\\s+", " ", metadata$var_label_clean)

  metadata
}

all_metadata <- bind_rows(
  lapply(names(waves), function(w) extract_metadata(waves[[w]], w))
)

# Focus on q variables (survey questions)
q_metadata <- all_metadata %>%
  filter(grepl("^q[0-9]", var_name, ignore.case = TRUE)) %>%
  filter(var_label != "")

cat(sprintf("  Extracted metadata for %d variables\n", nrow(all_metadata)))
cat(sprintf("  Focusing on %d question variables (q###)\n", nrow(q_metadata)))
cat("\n")

# ==============================================================================
# STEP 3: Method 1 - Exact label matching
# ==============================================================================

cat("Step 3: Method 1 - Exact label matching...\n")

exact_matches <- q_metadata %>%
  group_by(var_label_clean) %>%
  filter(n() >= 2) %>%  # Appears in at least 2 waves
  arrange(var_label_clean, wave) %>%
  summarise(
    label_text = first(var_label),
    waves_present = paste(wave, collapse = ", "),
    n_waves = n(),
    variable_names = paste(var_name, collapse = ", "),
    example_values = first(value_labels),
    .groups = "drop"
  ) %>%
  arrange(desc(n_waves), var_label_clean)

cat(sprintf("  Found %d questions with exact label matches across waves\n", nrow(exact_matches)))
cat(sprintf("  Questions in all 5 waves: %d\n", sum(exact_matches$n_waves == 5)))
cat(sprintf("  Questions in 4 waves: %d\n", sum(exact_matches$n_waves == 4)))
cat(sprintf("  Questions in 3 waves: %d\n", sum(exact_matches$n_waves == 3)))
cat(sprintf("  Questions in 2 waves: %d\n", sum(exact_matches$n_waves == 2)))
cat("\n")

# ==============================================================================
# STEP 4: Method 2 - Keyword-based matching
# ==============================================================================

cat("Step 4: Method 2 - Keyword-based matching...\n")

# Extract key terms from questions
keywords <- c(
  "trust", "confidence", "democracy", "democratic", "satisfaction", "satisfied",
  "government", "president", "prime minister", "parliament", "courts", "police",
  "military", "army", "election", "vote", "voting", "party", "parties",
  "economic", "economy", "income", "unemployment", "corruption", "corrupt",
  "freedom", "liberty", "rights", "protest", "demonstration",
  "media", "press", "newspaper", "television", "internet",
  "china", "united states", "japan", "covid", "coronavirus", "pandemic"
)

keyword_matches <- list()

for (keyword in keywords) {
  matches <- q_metadata %>%
    filter(grepl(keyword, var_label_clean, ignore.case = TRUE)) %>%
    group_by(var_label_clean) %>%
    filter(n() >= 2) %>%
    summarise(
      keyword = keyword,
      label = first(var_label),
      waves = paste(unique(wave), collapse = ", "),
      n_waves = n_distinct(wave),
      variables = paste(paste0(wave, ":", var_name), collapse = " | "),
      .groups = "drop"
    )

  if (nrow(matches) > 0) {
    keyword_matches[[keyword]] <- matches
  }
}

keyword_summary <- bind_rows(keyword_matches) %>%
  arrange(desc(n_waves), keyword)

cat(sprintf("  Found %d questions matching key concept keywords\n", nrow(keyword_summary)))
cat("\n")

# ==============================================================================
# STEP 5: Method 3 - Value label matching
# ==============================================================================

cat("Step 5: Method 3 - Value label matching...\n")

value_label_matches <- q_metadata %>%
  filter(value_labels != "") %>%
  group_by(value_labels) %>%
  filter(n() >= 2) %>%
  summarise(
    example_label = first(var_label),
    waves_present = paste(unique(wave), collapse = ", "),
    n_waves = n_distinct(wave),
    n_questions = n(),
    variables = paste(paste0(wave, ":", var_name), collapse = " | "),
    .groups = "drop"
  ) %>%
  arrange(desc(n_waves), desc(n_questions))

cat(sprintf("  Found %d response scale patterns appearing in multiple waves\n", nrow(value_label_matches)))
cat("\n")

# ==============================================================================
# STEP 6: Method 4 - Same question number across waves
# ==============================================================================

cat("Step 6: Method 4 - Same question number pattern...\n")

# Extract question numbers
q_metadata$q_number <- as.numeric(gsub("^q([0-9]+).*", "\\1", q_metadata$var_name, ignore.case = TRUE))

same_qnumber <- q_metadata %>%
  filter(!is.na(q_number)) %>%
  group_by(q_number) %>%
  filter(n_distinct(wave) >= 3) %>%  # Same q number in at least 3 waves
  arrange(q_number, wave) %>%
  summarise(
    waves_present = paste(wave, collapse = ", "),
    n_waves = n_distinct(wave),
    labels = paste(unique(substr(var_label, 1, 60)), collapse = " || "),
    variables = paste(var_name, collapse = ", "),
    .groups = "drop"
  ) %>%
  arrange(desc(n_waves), q_number)

cat(sprintf("  Found %d question numbers appearing in 3+ waves\n", nrow(same_qnumber)))
cat("  Note: Same number doesn't guarantee same question - labels may differ\n")
cat("\n")

# ==============================================================================
# STEP 7: Generate output reports
# ==============================================================================

cat("Step 7: Generating output reports...\n")

# Report 1: Exact matches - High confidence
write.csv(
  exact_matches,
  here("docs/cross_wave_exact_matches.csv"),
  row.names = FALSE
)
cat(sprintf("  ✓ Saved exact matches to: docs/cross_wave_exact_matches.csv\n"))

# Report 2: Keyword matches
write.csv(
  keyword_summary,
  here("docs/cross_wave_keyword_matches.csv"),
  row.names = FALSE
)
cat(sprintf("  ✓ Saved keyword matches to: docs/cross_wave_keyword_matches.csv\n"))

# Report 3: Value label patterns
write.csv(
  value_label_matches,
  here("docs/cross_wave_value_patterns.csv"),
  row.names = FALSE
)
cat(sprintf("  ✓ Saved value patterns to: docs/cross_wave_value_patterns.csv\n"))

# Report 4: Same question number patterns
write.csv(
  same_qnumber,
  here("docs/cross_wave_same_qnumber.csv"),
  row.names = FALSE
)
cat(sprintf("  ✓ Saved same q-number patterns to: docs/cross_wave_same_qnumber.csv\n"))

# ==============================================================================
# STEP 8: Show preview of top findings
# ==============================================================================

cat("\n=== PREVIEW: Top Cross-Wave Questions ===\n\n")

cat("Questions appearing in ALL 5 WAVES:\n")
cat("===================================\n")
top_five_wave <- exact_matches %>%
  filter(n_waves == 5) %>%
  head(20)

if (nrow(top_five_wave) > 0) {
  for (i in 1:nrow(top_five_wave)) {
    cat(sprintf("\n%2d. %s\n", i, top_five_wave$label_text[i]))
    cat(sprintf("    Variables: %s\n", top_five_wave$variable_names[i]))
  }
} else {
  cat("  None found\n")
}

cat("\n\nQuestions appearing in 4 WAVES:\n")
cat("===============================\n")
top_four_wave <- exact_matches %>%
  filter(n_waves == 4) %>%
  head(15)

if (nrow(top_four_wave) > 0) {
  for (i in 1:min(10, nrow(top_four_wave))) {
    cat(sprintf("\n%2d. %s\n", i, substr(top_four_wave$label_text[i], 1, 100)))
    cat(sprintf("    Variables: %s\n", top_four_wave$variable_names[i]))
    cat(sprintf("    Waves: %s\n", top_four_wave$waves_present[i]))
  }
}

cat("\n\n=== TOP KEYWORD FINDINGS ===\n\n")

# Show top keywords by frequency
top_keywords <- keyword_summary %>%
  group_by(keyword) %>%
  summarise(
    n_questions = n(),
    max_waves = max(n_waves),
    .groups = "drop"
  ) %>%
  arrange(desc(max_waves), desc(n_questions)) %>%
  head(10)

cat("Keywords with most cross-wave coverage:\n")
print(top_keywords)

cat("\n\n=== NEXT STEPS ===\n\n")

cat("1. Review docs/cross_wave_exact_matches.csv\n")
cat("   - High confidence matches ready to add to concept_mappings.csv\n")
cat("   - Questions in 5 waves are especially valuable\n\n")

cat("2. Review docs/cross_wave_keyword_matches.csv\n")
cat("   - Questions grouped by concept keywords\n")
cat("   - Useful for finding related questions across waves\n\n")

cat("3. Review docs/cross_wave_value_patterns.csv\n")
cat("   - Questions with same response scales may measure similar concepts\n")
cat("   - Useful for identifying question batteries\n\n")

cat("4. Review docs/cross_wave_same_qnumber.csv\n")
cat("   - Same question numbers may indicate intended tracking\n")
cat("   - CAUTION: Verify labels match before assuming same question\n\n")

cat("5. Use findings to expand docs/concept_mappings.csv\n")
cat("   - Add new concepts for questions appearing in multiple waves\n")
cat("   - Prioritize questions in 4-5 waves for longitudinal analysis\n\n")

cat("=== Discovery Complete ===\n\n")
