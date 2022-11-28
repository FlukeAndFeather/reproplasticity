# Created by use_targets().
# Follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(here)
library(targets)

# Set target options:
depends <- c(
  "dplyr",
  "here",
  "readr"
)
tar_option_set(
  packages = depends,
  format = "rds"
)

# Run the R scripts in the R/ folder with custom functions:
tar_source()

# Define the pipeline:
list(
  tar_target(
    name = mammal_lht_path,
    command = here("analysis", "data", "raw_data",
                   "Amniote_Database_Aug_2015.csv"),
    format = "file"
  ),
  tar_target(
    name = mammal_lht,
    command = read_lht(mammal_lht_path)
  )
)
