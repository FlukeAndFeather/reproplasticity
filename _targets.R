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
  "ggplot2",
  "here",
  "purrr",
  "readr",
  "tidyr"
)
tar_option_set(
  packages = depends,
  format = "rds"
)

# Run the R scripts in the R/ folder with custom functions:
tar_source()

# Define the pipeline:
lht_cols <- c("female_maturity_d", "gestation_d", "weaning_d", "longevity_y",
              "litter_or_clutch_size_n", "inter_birth_interval_y")
lht_names <- c("Female age at maturity (days)", "Gestation (days)",
               "Weaning (days)", "Longevity (years)", "Fecundity (n offspring)",
               "Inter-birth interval (y)")
list(
  # Life history trait data
  tar_target(
    name = mammal_lht_path,
    command = here("analysis", "data", "raw_data",
                   "Amniote_Database_Aug_2015.csv"),
    format = "file"
  ),
  tar_target(
    name = mammal_lht,
    command = read_lht(mammal_lht_path)
  ),
  tar_target(
    name = lht_plots,
    command = map2(lht_cols, lht_names, life_history_plot, dat = mammal_lht)
  ),
  # Phylogenetic data
  tar_target(
    name = mammal_tr_path,
    command = here("analysis", "data", "raw_data", "mammals.nex"),
    format = "file"
  ),
  tar_target(
    name = tax_resolutions_path,
    command = here("analysis", "data", "raw_data", "tnr_lht.csv"),
    format = "file"
  ),
  tar_target(
    name = mammal_tr,
    command = read_tree(mammal_tr_path, tax_resolutions_path, mammal_lht)
  ),
  # Generate LHT report
  tar_quarto(
    name = lht_report,
    path = here("analysis", "reports", "03_life_history.qmd")
  )
)
