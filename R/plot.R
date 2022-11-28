life_history_plot <- function(param_col, param_pretty, dat) {
  lbls_exp <- function(brks) {
    round(exp(brks), 1)
  }
  pal <- c(
    "Blue Whale" = "#7DC0EA",
    "Fin Whale" = "#4CA888",
    "Sperm Whale" = "#E3B03C"
  )
  plot_dat <- dat %>%
    drop_na(adult_body_mass_g, .data[[param_col]]) %>%
    mutate(log_mass = log(adult_body_mass_kg),
           log_param = log(.data[[param_col]]))
  ggplot(plot_dat, aes(log_mass, log_param)) +
    geom_point(alpha = 0.5) +
    geom_smooth(method = "lm", formula = y ~ x, se = FALSE) +
    geom_point(aes(color = great_whale), drop_na(plot_dat, great_whale)) +
    scale_color_manual(values = pal) +
    scale_x_continuous("Adult mass (kg)",
                       labels = lbls_exp) +
    scale_y_continuous(param_pretty,
                       labels = lbls_exp) +
    expand_limits(x = 0, y = 0) +
    theme_classic() +
    theme(legend.position = "none")
}
