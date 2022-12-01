# Convert IWC length format to something easier to work with
convert_length_m <- function(len, len_u) {
  # "These are coded in their original units, either metric or imperial.  The
  # units are specified by the indicator in the following field which also
  # distinguishes between lengths given to the nearest foot and those given to
  # the nearest inch.  Unknown lengths are coded as 0000.
  # Eg 46 ft 7ins is entered as 4607 with length switch 4
  #    21.3m       is entered as 2130 with length switch 3.
  # The length switch denotes the units of length (in previous field).  It is
  # coded as 2: feet only 3: metric 4: feet and inches"
  stopifnot(is.numeric(len))
  stopifnot(all(len_u %in% 2:4))
  len_whole <- floor(len / 100)
  len_frac <- len - len_whole
  case_when(
    len_u == 2 ~ len_whole * 0.3048,
    len_u == 3 ~ (len_whole + len_frac / 12) * 0.3048,
    len_u == 4 ~ len_whole + len_frac / 100
  )
}

# Read an IWC data file
read_iwc <- function(iwc_data_paths, iwc_schema_path) {
  iwc_schema <- read_csv(iwc_schema_path, show_col_types = FALSE)
  iwc_col_names <- iwc_schema$iwc_names
  iwc_col_types <- iwc_schema$iwc_types
  read_csv(iwc_data_paths,
           col_names = iwc_col_names,
           col_types = iwc_col_types,
           skip = 1) %>%
    transmute(date = as.Date(sprintf("%s-%s-%s", Year, Mon, Day)),
              catch_year = year(date),
              species = factor(Sp,
                               levels = 1:22,
                               labels = c("Pilot",
                                          "Bottlenose",
                                          "Killer",
                                          "Blue",
                                          "Fin",
                                          "Sperm",
                                          "Humpback",
                                          "Sei",
                                          "Common Minke",
                                          "Bryde's",
                                          "Right",
                                          "Gray",
                                          "Baird's Beaked",
                                          "Baleen",
                                          "Pygmy Blue",
                                          "Pygmy Right",
                                          "Cuvier's Beaked",
                                          "Bowhead",
                                          "Beaked (unspecified)",
                                          "Antarctic Minke",
                                          "Sei/Bryde's",
                                          "Dolphin")),
              length_m = convert_length_m(Len, L_u),
              sex = factor(Sx,
                           levels = 0:3,
                           labels = c("Unknown",
                                      "Male",
                                      "Female",
                                      "Hermaphrodite")),
              latitude = (Lat + Mn_lat / 60) * ifelse(NS == "S", -1, 1),
              longitude = (Lon + Mn_lon / 60) * ifelse(EW == "W", -1, 1),
              repro = factor(Fem,
                             levels = 0:9,
                             labels = c("Not pregnant",
                                        "Pregnant",
                                        "Ovulating",
                                        "Lactating",
                                        "Pregnant and lactating",
                                        "Ovulating and lactating",
                                        "Ovulating or Pregnant",
                                        "Resting",
                                        "Pregnancy lost",
                                        "Unknown")),
              is_pregnant = Fem %in% c(1, 2, 4),
              maturity = factor(Mat,
                                levels = 0:4,
                                labels = c("Unknown",
                                           "Mature",
                                           "Immature",
                                           "Mother",
                                           "Calf"))) %>%
    drop_na(date, species) %>%
    filter(species %in% c("Blue", "Fin", "Sperm"),
           latitude < 0) %>%
    mutate(species = paste(species, "Whale"))
}
