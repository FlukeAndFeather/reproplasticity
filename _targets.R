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
  "ggtree",
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
  tar_target(
    # Force dependencies for functions used in report
    name = report_dependencies,
    command = {
      life_history_plot
      phylogeny_plot
    }
  ),
  tar_render(
    name = lht_report,
    path = here("analysis", "reports", "03_life_history.qmd")
  )
)
