# ============================================================================
# Asian Barometer Cross-Wave Harmonization Functions
# ============================================================================
#
# This file contains functions to:
# 1. Map variable names across waves (questions that change numbers)
# 2. Reverse-code scales that changed direction between waves
# 3. Standardize variable names for cross-wave analysis
#
# Based on cross_wave.md analysis and label files
# ============================================================================

library(dplyr)

# ============================================================================
# VARIABLE NAME MAPPINGS
# ============================================================================
#
# These lists map conceptual variables to their wave-specific question numbers
# Usage: question_map$concept_name$wave_name returns the variable name

question_map <- list(

  # Economic Perceptions (consistent q1-q6 across all waves)
  econ_country_current = list(W2 = "q1", W3 = "q1", W4 = "q1", W5 = "q1", W6 = "q1"),
  econ_country_change = list(W2 = "q2", W3 = "q2", W4 = "q2", W5 = "q2", W6 = "q2"),
  econ_country_future = list(W2 = "q3", W3 = "q3", W4 = "q3", W5 = "q3", W6 = "q3"),
  econ_family_current = list(W2 = "q4", W3 = "q4", W4 = "q4", W5 = "q4", W6 = "q4"),
  econ_family_change = list(W2 = "q5", W3 = "q5", W4 = "q5", W5 = "q5", W6 = "q5"),
  econ_family_future = list(W2 = "q6", W3 = "q6", W4 = "q6", W5 = "q6", W6 = "q6"),

  # Trust in Institutions (q7-q19 series, mostly consistent)
  trust_executive = list(W2 = "q7", W3 = "q7", W4 = "q7", W5 = "q7", W6 = "q7"),
  trust_courts = list(W2 = "q8", W3 = "q8", W4 = "q8", W5 = "q8", W6 = "q8"),
  trust_national_gov = list(W2 = "q9", W3 = "q9", W4 = "q9", W5 = "q9", W6 = "q9"),
  trust_parties = list(W2 = "q10", W3 = "q10", W4 = "q10", W5 = "q10", W6 = "q10"),
  trust_parliament = list(W2 = "q11", W3 = "q11", W4 = "q11", W5 = "q11", W6 = "q11"),
  trust_civil_service = list(W2 = "q12", W3 = "q12", W4 = "q12", W5 = "q12", W6 = "q12"),
  trust_military = list(W2 = "q13", W3 = "q13", W4 = "q13", W5 = "q13", W6 = "q13"),
  trust_police = list(W2 = "q14", W3 = "q14", W4 = "q14", W5 = "q14", W6 = "q14"),
  trust_local_gov = list(W2 = "q15", W3 = "q15", W4 = "q15", W5 = "q15", W6 = "q15"),
  trust_election_commission = list(W2 = "q18", W3 = "q16", W4 = "q16", W5 = "q18", W6 = "q16"),
  trust_ngos = list(W2 = "q19", W3 = "q17", W4 = "q19", W5 = "q17", W6 = "q17"),

  # Social Trust
  general_trust = list(W2 = "q23", W3 = "q22", W4 = "q23", W5 = "q22", W6 = "q22"),
  trust_relatives = list(W2 = "q24", W3 = "q24", W4 = "q25", W5 = "q24", W6 = "q24"),
  trust_neighbors = list(W2 = "q25", W3 = "q25", W4 = "q26", W5 = "q25", W6 = "q25"),
  trust_others = list(W2 = "q26", W3 = "q26", W4 = "q27", W5 = "q26", W6 = "q26"),

  # Political Participation
  voted_last_election = list(W2 = "q32", W3 = "q32", W4 = "q33", W5 = NA, W6 = "q33"),
  interest_politics = list(W2 = "q43", W3 = "q43", W4 = "q44", W5 = "q47", W6 = "q47"),
  follow_news = list(W2 = "q44", W3 = "q44", W4 = "q45", W5 = "q48", W6 = "q48"),
  discuss_politics = list(W2 = "q45", W3 = "q48", W4 = "q46", W5 = "q49", W6 = "q49"),

  # Democratic Values
  satisfaction_democracy = list(W2 = "q93", W3 = "q89", W4 = "q92", W5 = "q90", W6 = "q90"),
  level_democracy = list(W2 = "q94", W3 = "q90", W4 = "q93", W5 = "q91", W6 = "q91"),
  democracy_suitable = list(W2 = "q98", W3 = "q94", W4 = "q97", W5 = "q95", W6 = "q95"),
  satisfaction_government = list(W2 = "q99", W3 = "q95", W4 = "q98", W5 = "q96", W6 = "q96"),
  democracy_preferable = list(W2 = "q121", W3 = "q132", W4 = "q125", W5 = "q124", W6 = "q124")
)


# ============================================================================
# SCALE REVERSAL FUNCTIONS
# ============================================================================
#
# These functions reverse-code scales that changed direction between waves
# to ensure consistent interpretation (higher = more positive)

#' Reverse code a 5-point scale
#' @param x Numeric vector with values 1-5
#' @return Reversed vector where 1->5, 2->4, 3->3, 4->2, 5->1. Invalid values become NA.
reverse_5point <- function(x) {
  # Only reverse valid values 1-5, convert invalid values (0, 97, 98, 99, etc.) to NA
  ifelse(x >= 1 & x <= 5, 6 - x, NA)
}

#' Reverse code a 4-point scale
#' @param x Numeric vector with values 1-4
#' @return Reversed vector where 1->4, 2->3, 3->2, 4->1. Invalid values become NA.
reverse_4point <- function(x) {
  # Only reverse valid values 1-4, convert invalid values (0, 97, 98, 99, etc.) to NA
  ifelse(x >= 1 & x <= 4, 5 - x, NA)
}

#' Reverse code a 6-point scale
#' @param x Numeric vector with values 1-6
#' @return Reversed vector where 1->6, 2->5, etc. Invalid values become NA.
reverse_6point <- function(x) {
  # Only reverse valid values 1-6, convert invalid values (0, 97, 98, 99, etc.) to NA
  ifelse(x >= 1 & x <= 6, 7 - x, NA)
}


# ============================================================================
# HARMONIZE ECONOMIC QUESTIONS
# ============================================================================
#
# Economic questions (q1-q6) changed scale direction between waves:
# - W2: 1=Very bad to 5=Very good (for current state)
# - W3-W6: 1=Very good to 5=Very bad (reversed!)
#
# This function standardizes all to: 1=Very bad, 5=Very good

#' Harmonize economic perception variables across waves
#' @param data Data frame containing economic variables
#' @param wave Character string: "W2", "W3", "W4", "W5", or "W6"
#' @param vars Vector of variable names to harmonize (default: q1-q6)
#' @return Data frame with harmonized variables (suffix _harm)
harmonize_economic <- function(data, wave,
                                vars = c("q1", "q2", "q3", "q4", "q5", "q6")) {

  # W3, W4, W5, W6 need reversal to match W2 direction
  # After reversal: 1 = worst/very bad, 5 = best/very good
  if (wave %in% c("W3", "W4", "W5", "W6")) {
    for (var in vars) {
      if (var %in% names(data)) {
        # Create harmonized version with suffix
        harm_var <- paste0(var, "_harm")
        data[[harm_var]] <- reverse_5point(data[[var]])

        # Add descriptive label
        attr(data[[harm_var]], "label") <- paste0(
          attr(data[[var]], "label", exact = TRUE),
          " [harmonized: 1=worst, 5=best]"
        )
      }
    }
  } else if (wave == "W2") {
    # W2 is already in correct direction, just copy with suffix
    for (var in vars) {
      if (var %in% names(data)) {
        harm_var <- paste0(var, "_harm")
        data[[harm_var]] <- data[[var]]
        attr(data[[harm_var]], "label") <- paste0(
          attr(data[[var]], "label", exact = TRUE),
          " [harmonized: 1=worst, 5=best]"
        )
      }
    }
  }

  return(data)
}


# ============================================================================
# HARMONIZE TRUST QUESTIONS
# ============================================================================
#
# Trust questions (q7-q19 series) have complex changes:
# - W2: 1=None at all to 4=A great deal (4-point)
# - W3, W5: 1=Trust fully to 6=Distrust fully (6-point, reversed!)
# - W4, W6: 1=A great deal to 4=None at all (4-point, reversed!)
#
# This function standardizes to: higher = more trust

#' Harmonize trust variables across waves
#' @param data Data frame containing trust variables
#' @param wave Character string: "W2", "W3", "W4", "W5", or "W6"
#' @param vars Vector of trust variable names (default: q7-q19)
#' @return Data frame with harmonized trust variables
harmonize_trust <- function(data, wave,
                             vars = paste0("q", 7:19)) {

  if (wave == "W2") {
    # W2: Already correct direction (1=none, 4=great deal)
    for (var in vars) {
      if (var %in% names(data)) {
        harm_var <- paste0(var, "_harm")
        data[[harm_var]] <- data[[var]]
        attr(data[[harm_var]], "label") <- paste0(
          attr(data[[var]], "label", exact = TRUE),
          " [harmonized 4pt: 1=none, 4=great deal]"
        )
      }
    }

  } else if (wave %in% c("W3", "W5")) {
    # W3, W5: 6-point scale, needs reversal (1=trust fully, 6=distrust fully)
    # After reversal: 6=trust fully, 1=distrust fully
    for (var in vars) {
      if (var %in% names(data)) {
        harm_var <- paste0(var, "_harm")
        data[[harm_var]] <- reverse_6point(data[[var]])
        attr(data[[harm_var]], "label") <- paste0(
          attr(data[[var]], "label", exact = TRUE),
          " [harmonized 6pt: 1=distrust, 6=trust fully]"
        )
      }
    }

  } else if (wave %in% c("W4", "W6")) {
    # W4, W6: 4-point scale, needs reversal (1=great deal, 4=none)
    for (var in vars) {
      if (var %in% names(data)) {
        harm_var <- paste0(var, "_harm")
        data[[harm_var]] <- reverse_4point(data[[var]])
        attr(data[[harm_var]], "label") <- paste0(
          attr(data[[var]], "label", exact = TRUE),
          " [harmonized 4pt: 1=none, 4=great deal]"
        )
      }
    }
  }

  return(data)
}


# ============================================================================
# HARMONIZE SOCIAL TRUST QUESTIONS
# ============================================================================
#
# Social trust questions (q24-q27 in W4) follow same pattern as institutional trust

#' Harmonize social trust variables (relatives, neighbors, others)
#' @param data Data frame
#' @param wave Character string
#' @param vars Vector of variable names
#' @return Data frame with harmonized variables
harmonize_social_trust <- function(data, wave,
                                    vars = paste0("q", 24:27)) {

  # Use same logic as institutional trust
  harmonize_trust(data, wave, vars)
}


# ============================================================================
# STANDARDIZE VARIABLE NAMES
# ============================================================================
#
# Create consistent variable names across waves using conceptual labels

#' Map wave-specific variables to standardized names
#' @param data Data frame with wave-specific variable names
#' @param wave Character string indicating wave
#' @param harmonize Logical: apply harmonization? (default: TRUE)
#' @return Data frame with standardized variable names
standardize_variables <- function(data, wave, harmonize = TRUE) {

  # First, apply harmonization if requested
  if (harmonize) {
    data <- harmonize_economic(data, wave)
    data <- harmonize_trust(data, wave)
    data <- harmonize_social_trust(data, wave)
  }

  # Then create standardized names
  for (concept in names(question_map)) {
    # Get the wave-specific variable name
    wave_var <- question_map[[concept]][[wave]]

    # Skip if NA or not in data
    if (is.na(wave_var) || !(wave_var %in% names(data))) {
      next
    }

    # Use harmonized version if it exists, otherwise original
    harm_var <- paste0(wave_var, "_harm")
    if (harm_var %in% names(data)) {
      data[[concept]] <- data[[harm_var]]
    } else {
      data[[concept]] <- data[[wave_var]]
    }

    # Preserve label
    if (!is.null(attr(data[[wave_var]], "label", exact = TRUE))) {
      attr(data[[concept]], "label") <- attr(data[[wave_var]], "label", exact = TRUE)
    }
  }

  return(data)
}


# ============================================================================
# CONVENIENCE FUNCTION: HARMONIZE ALL
# ============================================================================

#' Apply all harmonization steps to a wave dataset
#' @param data Data frame for one wave
#' @param wave Character string: "W2", "W3", "W4", "W5", or "W6"
#' @param add_wave_column Logical: add 'wave' identifier column? (default: TRUE)
#' @return Harmonized data frame
harmonize_wave <- function(data, wave, add_wave_column = TRUE) {

  # Add wave identifier
  if (add_wave_column) {
    data$wave <- wave
  }

  # Apply all harmonization
  data <- standardize_variables(data, wave, harmonize = TRUE)

  return(data)
}


# ============================================================================
# GENERATE CODEBOOK FOR HARMONIZED VARIABLES
# ============================================================================

#' Create a codebook showing variable mappings across waves
#' @return Data frame with concept names and wave-specific variable names
create_harmonization_codebook <- function() {

  codebook <- data.frame(
    concept = character(),
    W2 = character(),
    W3 = character(),
    W4 = character(),
    W5 = character(),
    W6 = character(),
    stringsAsFactors = FALSE
  )

  for (concept in names(question_map)) {
    row <- data.frame(
      concept = concept,
      W2 = ifelse(is.null(question_map[[concept]]$W2), NA, question_map[[concept]]$W2),
      W3 = ifelse(is.null(question_map[[concept]]$W3), NA, question_map[[concept]]$W3),
      W4 = ifelse(is.null(question_map[[concept]]$W4), NA, question_map[[concept]]$W4),
      W5 = ifelse(is.null(question_map[[concept]]$W5), NA, question_map[[concept]]$W5),
      W6 = ifelse(is.null(question_map[[concept]]$W6), NA, question_map[[concept]]$W6),
      stringsAsFactors = FALSE
    )
    codebook <- rbind(codebook, row)
  }

  return(codebook)
}
