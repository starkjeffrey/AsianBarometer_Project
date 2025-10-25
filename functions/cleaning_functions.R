# ==============================================================================
# cleaning_functions.R
# Reusable helper functions for data cleaning
# ==============================================================================

#' Clean survey variable by setting missing value codes to NA
#'
#' @param x A numeric vector
#' @param missing_codes Numeric vector of codes to treat as missing (default: c(0, 97, 98, 99))
#' @return Vector with missing codes replaced by NA
#' @examples
#' clean_variable(c(1, 2, 97, 98, 3, 0))
clean_variable <- function(x, missing_codes = c(0, 97, 98, 99)) {
  ifelse(x %in% missing_codes, NA, x)
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
