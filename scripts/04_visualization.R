# ==============================================================================
# 04_visualization.R
# Create visualizations for cleaned survey data
# ==============================================================================

cat("\n===== STARTING VISUALIZATION =====\n\n")

# Load required packages
library(here)
library(dplyr)
library(tidyr)
library(ggplot2)
library(readr)

# Source helper functions
source(here("functions/cleaning_functions.R"))

# ---------------------
# Load cleaned data
# ---------------------
cat("Loading cleaned dataset...\n")
cambodia_all_clean <- readRDS(here("data/processed/cambodia_all_waves_clean.rds"))

cat("  ✓ Data loaded\n\n")

# Set up plotting theme
theme_set(theme_minimal(base_size = 12))

# Custom color palette for waves
wave_colors <- c(
  "Wave2" = "#1C3A5B",
  "Wave3" = "#3B82F6", 
  "Wave4" = "#60A5FA",
  "Wave6" = "#93C5FD"
)

# Identify cleaned variables
clean_vars <- names(cambodia_all_clean)[grepl("_clean$", names(cambodia_all_clean))]

cat("Creating visualizations for:", paste(clean_vars, collapse = ", "), "\n\n")

# ---------------------
# 1. Distribution plots for each variable
# ---------------------
cat("Creating distribution plots...\n")

for (var in clean_vars) {
  cat("  - Plotting", var, "\n")
  
  # Prepare data
  plot_data <- cambodia_all_clean %>%
    filter(!is.na(!!sym(var))) %>%
    group_by(wave, !!sym(var)) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(wave) %>%
    mutate(percent = 100 * n / sum(n))
  
  # Create bar plot
  p <- ggplot(plot_data, aes(x = factor(!!sym(var)), y = percent, fill = wave)) +
    geom_col(position = "dodge", alpha = 0.8) +
    scale_fill_manual(values = wave_colors) +
    labs(
      title = paste("Distribution of", var, "by Wave"),
      x = gsub("_clean", "", var),
      y = "Percent (%)",
      fill = "Wave"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      legend.position = "bottom"
    )
  
  # Save plot
  filename <- paste0("distribution_", var, ".png")
  ggsave(
    here("output/figures", filename),
    plot = p,
    width = 8,
    height = 6,
    dpi = 300
  )
}

cat("  ✓ Distribution plots saved to output/figures/\n\n")

# ---------------------
# 2. Trend plots across waves
# ---------------------
cat("Creating trend plots...\n")

for (var in clean_vars) {
  cat("  - Plotting trends for", var, "\n")
  
  # Calculate mean by wave
  trend_data <- cambodia_all_clean %>%
    filter(!is.na(!!sym(var))) %>%
    group_by(wave) %>%
    summarise(
      mean = mean(!!sym(var), na.rm = TRUE),
      se = sd(!!sym(var), na.rm = TRUE) / sqrt(n()),
      n = n(),
      .groups = "drop"
    ) %>%
    mutate(
      lower = mean - 1.96 * se,
      upper = mean + 1.96 * se
    )
  
  # Create line plot with confidence intervals
  p <- ggplot(trend_data, aes(x = wave, y = mean, group = 1)) +
    geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2, fill = "#3B82F6") +
    geom_line(color = "#1C3A5B", size = 1.2) +
    geom_point(color = "#1C3A5B", size = 3) +
    labs(
      title = paste("Trend in", var, "Across Waves"),
      subtitle = "Mean with 95% confidence interval",
      x = "Wave",
      y = paste("Mean", gsub("_clean", "", var))
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      axis.text.x = element_text(angle = 0)
    )
  
  # Save plot
  filename <- paste0("trend_", var, ".png")
  ggsave(
    here("output/figures", filename),
    plot = p,
    width = 8,
    height = 6,
    dpi = 300
  )
}

cat("  ✓ Trend plots saved to output/figures/\n\n")

# ---------------------
# 3. Sample size visualization
# ---------------------
cat("Creating sample size visualization...\n")

sample_sizes <- cambodia_all_clean %>%
  group_by(wave) %>%
  summarise(
    total_n = n(),
    across(
      ends_with("_clean"),
      ~sum(!is.na(.)),
      .names = "{.col}_valid"
    )
  ) %>%
  pivot_longer(
    cols = ends_with("_valid"),
    names_to = "variable",
    values_to = "n_valid"
  ) %>%
  mutate(
    variable = gsub("_valid", "", variable)
  )

p_sample <- ggplot(sample_sizes, aes(x = wave, y = n_valid, fill = variable)) +
  geom_col(position = "dodge", alpha = 0.8) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Valid Sample Sizes by Wave and Variable",
    x = "Wave",
    y = "Number of Valid Responses",
    fill = "Variable"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "bottom"
  )

ggsave(
  here("output/figures/sample_sizes_by_wave.png"),
  plot = p_sample,
  width = 10,
  height = 6,
  dpi = 300
)

cat("  ✓ Sample size plot saved\n\n")

# ---------------------
# 4. Correlation matrix (if multiple variables)
# ---------------------
if (length(clean_vars) > 1) {
  cat("Creating correlation matrix...\n")
  
  # Prepare data for correlation
  cor_data <- cambodia_all_clean %>%
    select(all_of(clean_vars)) %>%
    na.omit()
  
  if (nrow(cor_data) > 30) {
    # Calculate correlation
    cor_matrix <- cor(cor_data)
    
    # Convert to long format for plotting
    cor_long <- as.data.frame(cor_matrix) %>%
      mutate(var1 = rownames(.)) %>%
      pivot_longer(
        cols = -var1,
        names_to = "var2",
        values_to = "correlation"
      )
    
    # Create heatmap
    p_cor <- ggplot(cor_long, aes(x = var1, y = var2, fill = correlation)) +
      geom_tile() +
      geom_text(aes(label = round(correlation, 2)), color = "white", size = 4) +
      scale_fill_gradient2(
        low = "#1C3A5B",
        mid = "white",
        high = "#DC2626",
        midpoint = 0,
        limits = c(-1, 1)
      ) +
      labs(
        title = "Correlation Matrix of Cleaned Variables",
        x = NULL,
        y = NULL,
        fill = "Correlation"
      ) +
      theme_minimal(base_size = 12) +
      theme(
        plot.title = element_text(face = "bold", size = 14),
        axis.text.x = element_text(angle = 45, hjust = 1),
        panel.grid = element_blank()
      )
    
    ggsave(
      here("output/figures/correlation_matrix.png"),
      plot = p_cor,
      width = 8,
      height = 7,
      dpi = 300
    )
    
    cat("  ✓ Correlation matrix saved\n")
  } else {
    cat("  ⚠ Insufficient complete cases for correlation matrix\n")
  }
}

cat("\n===== VISUALIZATION COMPLETE =====\n\n")

cat("All plots saved to: output/figures/\n")
cat("\nYou can now view:\n")
cat("  - Distribution plots (distribution_*.png)\n")
cat("  - Trend plots (trend_*.png)\n")
cat("  - Sample size plot\n")
if (length(clean_vars) > 1) {
  cat("  - Correlation matrix\n")
}

cat("\n")
