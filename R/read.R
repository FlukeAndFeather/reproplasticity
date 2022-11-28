# Read life history trait data
read_lht <- function(path) {
  read_csv(path, show_col_types = FALSE) %>%
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
    filter(class == "Mammalia")
}

# Read phylogenetic data
read_tree <- function(tree_path, resolution_path, lht) {
  # There are 100 trees in the nexus file because they're generated probabilistically.
  mammal_trs <- read.nexus(tree_path)
  # We'll try the analysis on the first one
  mammal_tr <- mammal_trs[[1]]

  # 344 species are in the life history trait database but not the phylogeny. I
  # manually verified the results of rotl::tnrs_match_names() to resolve
  # taxonomic disagreements. Results of manual audit saved to CSV file.

  # As a result of taxonomy resolution, some species were lumped. Aggregate
  # their life history traits by the median. Drop species with incomplete LHT
  # records.
  lht_tax_resolutions <- read_csv(resolution_path, show_col_types = FALSE) %>%
    drop_na(corrected_name) %>%
    select(search_string, corrected_name)
  mammal_lht_resolved <- lht %>%
    mutate(search_string = trimws(tolower(paste(genus, species)))) %>%
    left_join(lht_tax_resolutions, by = "search_string") %>%
    mutate(tree_name = coalesce(corrected_name, paste(genus, species, sep = "_")),
           in_tree = tree_name %in% mammal_tr$tip.label) %>%
    filter(in_tree) %>%
    select(tree_name, order, family, adult_body_mass_kg, female_maturity_d,
           gestation_d, weaning_d, longevity_y, litter_or_clutch_size_n,
           inter_birth_interval_y) %>%
    drop_na() %>%
    group_by(tree_name, order, family) %>%
    summarize(across(everything(), median, na.rm = TRUE),
              .groups = "drop")
  # Leaves 1322 species

  # Subset tree to retained species
  mammal_tr_subset <- keep.tip(mammal_tr, mammal_lht_resolved$tree_name)

  mammal_tr_subset
}
