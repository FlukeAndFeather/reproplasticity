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
  "forcats",
  "ggExtra",
  "ggplot2",
  "ggrepel",
  "ggtree",
  "here",
  "nlme",
  "phytools",
  "purrr",
  "readr",
  "tibble",
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
    name = tax_resolutions_path,
    command = here("analysis", "data", "raw_data", "tnr_lht.csv"),
    format = "file"
  ),
  tar_target(
    name = mammal_lht0,
    command = read_lht(mammal_lht_path, tax_resolutions_path)
  ),
  # Phylogenetic data
  tar_target(
    name = mammal_tr_path,
    command = here("analysis", "data", "raw_data", "mammals.nex"),
    format = "file"
  ),
  tar_target(
    name = mammal_tr,
    command = read_tree(mammal_tr_path, mammal_lht0)
  ),
  # Subset trait data
  tar_target(
    name = mammal_lht,
    command = filter(mammal_lht0, tree_name %in% mammal_tr$tip.label)
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
  # Generate LHT report
  tar_target(
    # Force dependencies for functions used in report
    name = report_dependencies,
    command = {
      life_history_plot
      phylogeny_plot
      biplot
      pol_plot
    }
  ),
  tar_render(
    name = lht_report,
    path = here("analysis", "reports", "03_life_history.qmd")
  )
)
