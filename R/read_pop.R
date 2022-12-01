read_pop <- function(pop_path) {
  read_excel(pop_path) %>%
    # Sperm Whale populations weren't broken down by hemisphere, so
    # we're just using the global population for now
    filter(CommonName %in% c("Blue Whale", "Fin Whale", "Sperm Whale"),
           Region %in% c("Southern Hemisphere", "global")) %>%
    # Years have decimals for some reason
    transmute(catch_year = floor(Year),
              pop_size = Pop_size,
              species = CommonName)
}
