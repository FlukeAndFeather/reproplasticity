# Fit a PGLS model to a life history trait w.r.t. body size (log-log),
# accounting for  phylogeny
fit_model <- function(trait, lht, tr, type = c("Gaussian", "Tweedie")) {

  type <- match.arg(type)

  type |> switch(
    Gaussian = lm(update(~ log(adult_body_mass_kg), as.formula(sprintf("log(%s) ~ .", trait))), data = lht),
    Tweedie = glmmTMB(as.formula(paste0(trait, "~ log(adult_body_mass_kg)")), data = lht, family = tweedie(link = "log"))
  )

}

# Get life history trait residuals accounting for body size and phylogeny
lht_residuals <- function(lht, tr) {

  traits <- c("female_maturity_d", "gestation_d", "weaning_d", "longevity_y",
              "fecundity", "inter_birth_interval_y")

  models <- traits |> map2(
    c("Gaussian", "Gaussian", "Gaussian", "Gaussian", "Tweedie", "Gaussian"),
    ~ fit_model(.x, lht = lht, tr = tr, type = .y)
  ) |> setNames(paste0(traits, "_resid"))

  model_resid <- bind_cols(lapply(models, resid, type = "pearson"))

  bind_cols(lht, model_resid)

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
