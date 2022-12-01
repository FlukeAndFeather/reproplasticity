# Calculate pregnancy rate for a given year
preg_rate <- function(is_pregnant, sex) {
  n_preg <- sum(is_pregnant)
  n_fem <- sum(sex == "Female")
  if (n_fem == 0) {
    NA
  } else {
    n_preg / n_fem
  }
}
