# ==============================================================================
# concept_functions.R
# Functions for working with concept mappings across waves
# ==============================================================================

library(readr)
library(dplyr)
library(here)
library(haven)

#' Load concept mappings from CSV
#'
#' @param path Path to concept_mappings.csv
#' @return Tibble with concept definitions and wave mappings
load_concept_mappings <- function(path = here("docs/concept_mappings.csv")) {
  if (!file.exists(path)) {
    stop("Concept mappings file not found: ", path)
  }
  read_csv(path, show_col_types = FALSE)
}

#' Get variable name for a concept in a specific wave
#'
#' @param concept_name Name of the concept (e.g., "trust_executive")
#' @param wave Wave identifier ("W2", "W3", "W4", "W5", or "W6")
#' @param mappings Concept mappings tibble (loaded from CSV)
#' @return Variable name or NA if concept not in that wave
#' @examples
#' get_concept_variable("trust_executive", "W3", mappings)
get_concept_variable <- function(concept_name, wave, mappings = load_concept_mappings()) {
  wave_col <- paste0(tolower(wave), "_var")

  if (!wave_col %in% names(mappings)) {
    stop("Invalid wave: ", wave, ". Use W2, W3, W4, W5, or W6")
  }

  concept_row <- mappings %>% filter(concept == concept_name)

  if (nrow(concept_row) == 0) {
    stop("Concept not found: ", concept_name)
  }

  var_name <- concept_row[[wave_col]]

  if (is.na(var_name) || var_name == "") {
    return(NA_character_)
  }

  return(var_name)
}

#' Extract concept data from a wave
#'
#' @param data Wave data frame (with haven_labelled columns)
#' @param concept_name Name of the concept
#' @param wave Wave identifier
#' @param clean Apply label-based NA cleaning
#' @param mappings Concept mappings tibble
#' @return Vector with concept data, or NULL if not available
#' @examples
#' get_concept(w3_data, "trust_executive", "W3", clean = TRUE)
get_concept <- function(data, concept_name, wave,
                        clean = TRUE,
                        mappings = load_concept_mappings()) {
  # Get variable name for this concept in this wave
  var_name <- get_concept_variable(concept_name, wave, mappings)

  if (is.na(var_name)) {
    warning(paste("Concept", concept_name, "not available in", wave))
    return(NULL)
  }

  if (!var_name %in% names(data)) {
    warning(paste("Variable", var_name, "not found in data"))
    return(NULL)
  }

  # Extract the variable
  var_data <- data[[var_name]]

  # Clean if requested
  if (clean && is.labelled(var_data)) {
    source(here("functions/cleaning_functions.R"))
    var_data <- clean_variable_by_label(var_data, na_labels_list)
  }

  return(var_data)
}

#' Extract concept from all waves and combine
#'
#' @param concept_name Name of the concept
#' @param wave_data_list Named list of wave data frames (W2, W3, W4, W5, W6)
#' @param clean Apply label-based NA cleaning
#' @param add_wave_column Add wave identifier column
#' @return Tibble with concept data from all waves
#' @examples
#' waves <- list(W2 = w2_data, W3 = w3_data, W4 = w4_data, W5 = w5_data, W6 = w6_data)
#' trust_exec <- get_concept_all_waves("trust_executive", waves)
get_concept_all_waves <- function(concept_name, wave_data_list,
                                   clean = TRUE,
                                   add_wave_column = TRUE,
                                   mappings = load_concept_mappings()) {
  result_list <- list()

  for (wave_name in names(wave_data_list)) {
    wave_data <- wave_data_list[[wave_name]]

    concept_data <- get_concept(wave_data, concept_name, wave_name,
                                 clean = clean, mappings = mappings)

    if (!is.null(concept_data)) {
      if (add_wave_column) {
        result_list[[wave_name]] <- tibble(
          wave = wave_name,
          !!concept_name := concept_data
        )
      } else {
        result_list[[wave_name]] <- tibble(
          !!concept_name := concept_data
        )
      }
    }
  }

  if (length(result_list) == 0) {
    warning(paste("Concept", concept_name, "not found in any wave"))
    return(NULL)
  }

  bind_rows(result_list)
}

#' List available concepts
#'
#' @param domain Filter by domain (trust, economic, democracy, politics)
#' @param wave Filter by wave availability
#' @param mappings Concept mappings tibble
#' @return Tibble with concept information
list_concepts <- function(domain = NULL, wave = NULL,
                          mappings = load_concept_mappings()) {
  result <- mappings %>%
    select(concept, domain, description, scale_type, notes)

  if (!is.null(domain)) {
    result <- result %>% filter(domain == !!domain)
  }

  if (!is.null(wave)) {
    wave_col <- paste0(tolower(wave), "_var")
    result <- result %>%
      filter(!is.na(.data[[wave_col]]) & .data[[wave_col]] != "")
  }

  return(result)
}

#' List concepts available in a specific wave
#'
#' @param wave Wave identifier
#' @param mappings Concept mappings tibble
#' @return Tibble with concepts and their variable names in that wave
list_wave_concepts <- function(wave, mappings = load_concept_mappings()) {
  wave_col <- paste0(tolower(wave), "_var")

  if (!wave_col %in% names(mappings)) {
    stop("Invalid wave: ", wave)
  }

  mappings %>%
    filter(!is.na(.data[[wave_col]]) & .data[[wave_col]] != "") %>%
    select(concept, domain, description, variable = !!wave_col, scale_type, notes)
}

#' Get concept metadata
#'
#' @param concept_name Name of the concept
#' @param mappings Concept mappings tibble
#' @return List with concept information
get_concept_info <- function(concept_name, mappings = load_concept_mappings()) {
  concept_row <- mappings %>% filter(concept == concept_name)

  if (nrow(concept_row) == 0) {
    stop("Concept not found: ", concept_name)
  }

  as.list(concept_row[1, ])
}

#' Check which waves have a concept
#'
#' @param concept_name Name of the concept
#' @param mappings Concept mappings tibble
#' @return Character vector of available waves
concept_availability <- function(concept_name, mappings = load_concept_mappings()) {
  concept_row <- mappings %>% filter(concept == concept_name)

  if (nrow(concept_row) == 0) {
    stop("Concept not found: ", concept_name)
  }

  wave_cols <- c("w2_var", "w3_var", "w4_var", "w5_var", "w6_var")
  available <- c()

  for (col in wave_cols) {
    if (!is.na(concept_row[[col]]) && concept_row[[col]] != "") {
      available <- c(available, toupper(gsub("_var", "", col)))
    }
  }

  return(available)
}

#' Validate that a concept variable exists in the data
#'
#' @param data Wave data frame
#' @param concept_name Name of the concept
#' @param wave Wave identifier
#' @param mappings Concept mappings tibble
#' @return Logical indicating if concept is available and valid
validate_concept <- function(data, concept_name, wave,
                              mappings = load_concept_mappings()) {
  var_name <- get_concept_variable(concept_name, wave, mappings)

  if (is.na(var_name)) {
    message(paste("✗ Concept", concept_name, "not mapped for", wave))
    return(FALSE)
  }

  if (!var_name %in% names(data)) {
    message(paste("✗ Variable", var_name, "not found in", wave, "data"))
    return(FALSE)
  }

  message(paste("✓ Concept", concept_name, "→", var_name, "in", wave))
  return(TRUE)
}

#' Extract multiple concepts from a wave
#'
#' @param data Wave data frame
#' @param concept_names Vector of concept names
#' @param wave Wave identifier
#' @param clean Apply label-based NA cleaning
#' @return Tibble with selected concepts as columns
extract_concepts <- function(data, concept_names, wave, clean = TRUE,
                              mappings = load_concept_mappings()) {
  result <- tibble()

  for (concept in concept_names) {
    concept_data <- get_concept(data, concept, wave, clean = clean, mappings = mappings)

    if (!is.null(concept_data)) {
      if (nrow(result) == 0) {
        result <- tibble(!!concept := concept_data)
      } else {
        result[[concept]] <- concept_data
      }
    }
  }

  if (ncol(result) == 0) {
    warning("No concepts extracted")
    return(NULL)
  }

  return(result)
}
