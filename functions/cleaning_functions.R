# ==============================================================================
# cleaning_functions.R
# Reusable helper functions for data cleaning
# ==============================================================================

# Master list of all labels to be converted to NA
# These are SPSS value label texts that indicate missing/invalid responses
# Advantage: numeric codes vary by question, but label text is consistent
na_labels_list <- c(
  # Generic missing indicators
  "Missing",                          # Common across waves
  "NA",
  "N/A",
  "Not applicable",

  # Don't know / Can't answer
  "don't understand",
  "Don't understand",
  "Do not understand the question",
  "don't understand the question",
  "Don't understand the question",
  "DK",
  "Don't know",
  "Can't choose",
  "Cannot choose",
  "Can't determine",

  # Refusal to answer
  "Refused",
  "Refuse",
  "Decline to answer",
  "No answer",
  "No more answer",
  "No further reply",

  # Question-specific NA indicators found so far
  "Not a member of any organization or group",  # Wave2, Q20
  "Unclassifiable / inconceivable"              # Wave 2, Q100

  # Add new label patterns as you discover them during wave exploration
)

#' Clean haven_labelled variable by converting label-based NA values
#'
#' Converts values to NA based on their SPSS value labels while preserving
#' the haven_labelled class and all label attributes. This is the CORRECT
#' way to handle missing values in SPSS data where numeric codes vary by question.
#'
#' @param x A haven_labelled vector
#' @param na_labels Character vector of value labels to treat as NA
#' @return haven_labelled vector with specified values replaced by NA
#' @examples
#' # Clean a variable using the standard NA label list
#' clean_q1 <- clean_variable_by_label(data$q1, na_labels_list)
#'
#' # Add custom NA labels for specific questions
#' clean_q20 <- clean_variable_by_label(data$q20,
#'                                       c(na_labels_list, "Not a member"))
clean_variable_by_label <- function(x, na_labels = na_labels_list) {
  if (!haven::is.labelled(x)) {
    warning("Variable is not haven_labelled, returning unchanged")
    return(x)
  }

  # Get value labels
  val_labs <- attr(x, "labels")
  if (is.null(val_labs) || length(val_labs) == 0) {
    warning("No value labels found")
    return(x)
  }

  # Find label names (not values) that match our NA patterns
  lab_names <- names(val_labs)
  matching <- lab_names %in% na_labels

  # Get the VALUES corresponding to those labels
  na_values_to_replace <- val_labs[matching]

  if (length(na_values_to_replace) == 0) {
    return(x)  # No matches, return unchanged
  }

  # Replace each value with NA using base R subsetting (preserves labelled class)
  for (val in na_values_to_replace) {
    x[x == val] <- NA
  }

  x
}

#' Clean survey variable by setting missing value codes to NA (numeric approach)
#'
#' @param x A numeric vector
#' @param missing_codes Codes to treat as missing
#' @return Vector with missing codes replaced by NA
#' @examples
#' clean_variable(c(-1))
clean_variable_dplyr <- function(x, missing_codes = c(-1)) {
  for (code in missing_codes) {
    x <- na_if(x, code)
  }
  x
}

#' Apply cleaning function to multiple columns
#'
#' @param data A data frame
#' @param vars Character vector of variable names to clean
#' @param suffix Suffix to add to cleaned variable names (default: "_clean")
#' @param missing_codes Codes to treat as missing
#' @return Data frame with additional cleaned columns
#' @examples
#' clean_multiple_vars(df, c("q92", "q93", "q94"))
clean_multiple_vars <- function(data, vars, suffix = "_clean", missing_codes = c(0, 97, 98, 99)) {
  for (var in vars) {
    if (var %in% names(data)) {
      new_var_name <- paste0(var, suffix)
      data[[new_var_name]] <- clean_variable(data[[var]], missing_codes)
    } else {
      warning(paste("Variable", var, "not found in data"))
    }
  }
  return(data)
}

#' Get summary statistics for a variable by wave
#'
#' @param data Data frame containing wave and the variable
#' @param var_name Name of the variable to summarize
#' @param wave_var Name of the wave variable (default: "wave")
#' @return Tibble with summary statistics by wave
get_wave_summary <- function(data, var_name, wave_var = "wave") {
  data %>%
    group_by(!!sym(wave_var)) %>%
    summarise(
      n_total = n(),
      n_valid = sum(!is.na(!!sym(var_name))),
      n_missing = sum(is.na(!!sym(var_name))),
      pct_valid = round(100 * n_valid / n_total, 1),
      mean = round(mean(!!sym(var_name), na.rm = TRUE), 2),
      median = median(!!sym(var_name), na.rm = TRUE),
      sd = round(sd(!!sym(var_name), na.rm = TRUE), 2),
      min = min(!!sym(var_name), na.rm = TRUE),
      max = max(!!sym(var_name), na.rm = TRUE),
      .groups = "drop"
    )
}

#' Export variable codebook from labeled data
#'
#' @param data_list Named list of data frames
#' @param output_path Path to save CSV file
#' @return Tibble with variable names and labels
export_codebook <- function(data_list, output_path) {
  codebook <- map_dfr(data_list, .id = "source_wave", function(df) {
    tibble(
      variable = names(df),
      label = var_label(df) %>% as.character()
    )
  })
  
  write_csv(codebook, output_path)
  message(paste("Codebook exported to:", output_path))
  
  return(codebook)
}
