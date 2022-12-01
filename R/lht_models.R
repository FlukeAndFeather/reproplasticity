# Fit a PGLS model to a life history trait w.r.t. body size (log-log),
# accounting for  phylogeny
fit_pgls <- function(trait, lht, tr) {
  f <- update(~ log(adult_body_mass_kg),
              as.formula(sprintf("log(%s) ~ .", trait)))
  cor <- corBrownian(phy = tr, form = ~ tree_name)
  gls(f, lht, cor, method = "ML")
}

# Get life history trait residuals accounting for body size and phylogeny
lht_residuals <- function(lht, tr) {
  pgls_models <- map(
    c("female_maturity_d", "gestation_d", "weaning_d", "longevity_y",
      "litter_or_clutch_size_n", "inter_birth_interval_y"),
    fit_pgls,
    lht = lht,
    tr = tr
  )
  lht %>%
    mutate(female_maturity_d_resid = resid(pgls_models[[1]]),
           gestation_d_resid = resid(pgls_models[[2]]),
           weaning_d_resid = resid(pgls_models[[3]]),
           longevity_y_resid = resid(pgls_models[[4]]),
           litter_or_clutch_size_n_resid = resid(pgls_models[[5]]),
           inter_birth_interval_y_resid = resid(pgls_models[[6]]))
}

# Reduce life history trait dimensionality using phylogenetic PCA
lht_phyl_pca <- function(lht, tr) {
  lht_mtx <- lht %>%
    column_to_rownames("tree_name") %>%
    mutate(across(ends_with("resid"), ~ (.x - mean(.x)) / sd(.x))) %>%
    select(ends_with("resid")) %>%
    as.matrix()
  phyl.pca(tr, lht_mtx, method = "lambda", mode = "corr")
}
