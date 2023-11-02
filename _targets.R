# Created by use_targets().
# Follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(here)
library(tarchetypes)
library(targets)

# Set target options:
depends <- c(
  "ape",
  "cowplot",
  "dplyr",
  "emmeans",
  "forcats",
  "ggExtra",
  "ggplot2",
  "ggrepel",
  "ggsignif",
  "ggtree",
  "here",
  "kableExtra",
  "knitr",
  "lubridate",
  "nlme",
  "phytools",
  "purrr",
  "readr",
  "readxl",
  "scales",
  "stringr",
  "tibble",
  "tidyr",
  "glmmTMB"
)
tar_option_set(
  packages = depends,
  format = "rds"
)

# Run the R scripts in the R/ folder with custom functions:
tar_source()

# Define the pipeline:
list(
  # Density Dependence in the Great Whales ----------------------------------
  # IWC data (catches and pregnancy rates)
  tar_target(
    name = iwc_schema_path,
    command = here("data", "iwc_schema.csv"),
    format = "file"
  ),
  tar_target(
    name = iwc_paths,
    command = c(
      here("data", "SHL.csv"),
      here("data", "SHP1.csv"),
      here("data", "SU.csv")
    ),
    format = "file"
  ),
  tar_target(
    name = iwc_data,
    command = read_iwc(iwc_paths, iwc_schema_path)
  ),
  tar_target(
    name = preg_data,
    command = iwc_data %>%
      group_by(catch_year, species) %>%
      summarize(catches = n(),
                f_catches = sum(sex == "Female"),
                preg_rate = preg_rate(is_pregnant, sex),
                .groups = "drop") %>%
      drop_na() %>%
      filter(f_catches > 0)
  ),
  # Population data
  tar_target(
    name = pop_path,
    command = here("data", "Whale_pops_time_Christensen 2006.xlsx"),
    format = "file"
  ),
  tar_target(
    name = whale_pops,
    command = read_pop(pop_path)
  ),
  tar_target(
    name = whale_pops_20th,
    command = whale_pops %>%
      filter(catch_year >= 1900) %>%
      group_by(species) %>%
      mutate(pop_norm = pop_size / max(pop_size)) %>%
      ungroup()
  ),
  # Population and pregnancy joined
  tar_target(
    name = preg_pop_data,
    command = inner_join(whale_pops_20th,
                         preg_data,
                         by = c("species", "catch_year"))
  ),
  # Logistic model
  tar_target(
    name = preg_model,
    command = fit_preg(preg_pop_data)
  ),
  tar_target(
    name = preg_predictions,
    command = predict_preg(preg_pop_data, preg_model)
  ),
  # Generate density dependence reports
  tar_render(
    name = pop_preg_report,
    path = here("reports", "01_whale_pop_preg.qmd")
  ),
  tar_render(
    name = density_report,
    path = here("reports", "02_density_model.qmd")
  ),

  # Life History Analysis ---------------------------------------------------
  # Life history trait data
  tar_target(
    name = mammal_lht_path,
    command = here("data", "Amniote_Database_Aug_2015.csv"),
    format = "file"
  ),
  tar_target(
    name = tax_resolutions_path,
    command = here("data", "tnr_lht.csv"),
    format = "file"
  ),
  tar_target(
    name = mammal_lht0,
    command = read_lht(mammal_lht_path, tax_resolutions_path)
  ),
  # Phylogenetic data
  tar_target(
    name = mammal_tr_path,
    command = here("data", "mammals.nex"),
    format = "file"
  ),
  tar_target(
    name = mammal_tr,
    command = read_tree(mammal_tr_path, mammal_lht0)
  ),
  # Subset trait data
  tar_target(
    name = mammal_lht,
    command = mutate(filter(mammal_lht0, tree_name %in% mammal_tr$tip.label), fecundity = pmax(0, litter_or_clutch_size_n - 1))
  ),
  # LHT residuals
  tar_target(
    name = lht_resid,
    command = lht_residuals(mammal_lht, mammal_tr)
  ),
  # LHT PCA
  tar_target(
    name = lht_pca,
    command = lht_phyl_pca(lht_resid, mammal_tr)
  ),
  tar_target(
    name = pol_dat,
    command =  lht_pca$S %>%
      as.data.frame() %>%
      rownames_to_column("tree_name") %>%
      select(tree_name, pc1 = PC1, pc2 = PC2) %>%
      left_join(mammal_lht, by = "tree_name") %>%
      mutate(order = fct_reorder(order, pc1))
  ),
  # Generate LHT report
  tar_render(
    name = lht_report,
    path = here("reports", "03_life_history.qmd")
  )
)
