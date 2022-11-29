# Read life history trait data
read_lht <- function(lht_path, resolution_path) {
  # The trait database and phylogenetic tree have 344 taxonomic conflicts. I
  # manually verified the results of rotl::tnrs_match_names() and saved the
  # resolutions to CSV.
  lht_tax_resolutions <- read_csv(resolution_path, show_col_types = FALSE) %>%
    drop_na(corrected_name) %>%
    select(search_string, corrected_name)

  # Read trait database
  read_csv(lht_path, show_col_types = FALSE) %>%
    mutate(
      across(everything(), ~ na_if(.x, -999)),
      inter_birth_interval_y = 1 / litters_or_clutches_per_y,
      adult_body_mass_kg = adult_body_mass_g,
      great_whale = case_when(
        paste(genus, species) == "Balaenoptera musculus"  ~ "Blue Whale",
        paste(genus, species) == "Balaenoptera physalus"  ~ "Fin Whale",
        # Note outdated species name
        paste(genus, species) == "Physeter catodon" ~ "Sperm Whale",
        TRUE ~ NA_character_
      )
    ) %>%
    # Subset mammals
    filter(class == "Mammalia") %>%
    # Resolve taxonomic conflicts
    mutate(search_string = trimws(tolower(paste(genus, species)))) %>%
    left_join(lht_tax_resolutions, by = "search_string") %>%
    mutate(tree_name = coalesce(corrected_name,
                                paste(genus, species, sep = "_"))) %>%
    select(tree_name, order, family, adult_body_mass_kg, female_maturity_d,
           gestation_d, weaning_d, longevity_y, litter_or_clutch_size_n,
           inter_birth_interval_y) %>%
    # As a result of taxonomy resolution, some species were lumped. Aggregate
    # their life history traits by the median. Drop species with incomplete LHT
    # records.
    drop_na() %>%
    group_by(tree_name, order, family) %>%
    summarize(across(everything(), median, na.rm = TRUE),
              .groups = "drop")
}

# Read phylogenetic data
read_tree <- function(tree_path, lht) {
  # There are 100 trees in the nexus file because they're generated probabilistically.
  mammal_trs <- read.nexus(tree_path)
  # We'll try the analysis on the first one
  mammal_tr <- mammal_trs[[1]]

  # Subset tree to retained species
  keep.tip(mammal_tr,
           lht$tree_name[lht$tree_name %in% mammal_tr$tip.label])
}
