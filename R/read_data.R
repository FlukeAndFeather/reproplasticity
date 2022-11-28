#' Read life history trait data
#'
#' @return A data frame with mammal life history traits
#' @export
#'
#' @examples
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
