# Fit logistic model
fit_preg <- function(preg_pop_data) {
  glm(preg_rate ~ pop_norm * species,
      data = filter(preg_pop_data, pop_norm >= 0.2),
      family = binomial,
      weights = f_catches)
}

# Generate predictions from logisitic model
predict_preg <- function(preg_pop_data, preg_model) {
  # Create prediction grid
  preg_grid <- expand_grid(
    species = unique(preg_pop_data$species),
    pop_norm = seq(0.2, 1, length.out = 100)
  )

  # Predictions with CI
  preg_pred <- predict(preg_model,
                       newdata = preg_grid,
                       type = "link",
                       se.fit = TRUE)
  invlink_fun <- family(preg_model)$linkinv
  preg_grid$preg_rate <- invlink_fun(preg_pred$fit)
  preg_grid$preg_rate_lwr <- invlink_fun(preg_pred$fit - 2 * preg_pred$se.fit)
  preg_grid$preg_rate_upr <- invlink_fun(preg_pred$fit + 2 * preg_pred$se.fit)

  # Constrain to interpolating pop sizes
  pop_constraints <- preg_pop_data %>%
    group_by(species) %>%
    summarize(min_pop = min(pop_norm),
              max_pop = max(pop_norm),
              .groups = "drop")
  preg_grid %>%
    left_join(pop_constraints, by = "species") %>%
    filter(pop_norm >= min_pop,
           pop_norm <= max_pop) %>%
    select(-min_pop, -max_pop)
}
