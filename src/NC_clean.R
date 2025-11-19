# ------------------------------------
#           North Carolina (NC)
# ------------------------------------
library(dplyr)
library(tidyr)
library(purrr)
library(lubridate)
library(readr)

#' @title NC_clean
#' @description
#' Cleans and standardises North Carolina influenza surveillance data.
#'
#' Reads raw CSV files from the "raw-data" folder matching the pattern
#' `"NC_DETECT_Respiratory_Regional_Influenza_only.csv"`, combines them,
#' converts dates to `Date` objects, standardises region names, and computes
#' an `observation` column for analysis.
#'
#' Ensures there are no missing values and that all observations are within
#' the range 0 to 100.
#'
#' @return A tibble with columns:
#' \describe{
#'   \item{as_of_date}{character}
#'   \item{location}{character, lower case, hyphenated. See locations.csv .}
#'   \item{target_end_date}{Date YYYY-MM-DD.}
#'   \item{observation}{Numeric.}
#' }
#'
NC_clean <- function() {
  NC_raw <- list.files(
    path = "raw-data",
    pattern = "NC_DETECT_Respiratory_Regional_Influenza_only\\.csv$",
    full.names = TRUE
  ) |>
    (\(x) tibble(file = x))() |>
    mutate(
      as_of_date = stringr::str_extract(basename(file), "^[0-9]+") |>
        as.Date(format = "%Y%m%d") |>
        as.character()
    ) |>
    mutate(data = map(file, read.csv)) |>
    select(-file) |>
    unnest(data) |>
    select(-X)

  NC_clean <-
    NC_raw |>
    mutate(
      Percentage.Of.Total.ED.Visits = as.numeric(
        gsub("%", "", Percentage.Of.Total.ED.Visits)
      ),
      observation = if_else(
        as_of_date == "2025-10-04",
        Percentage.Of.Total.ED.Visits,
        value
      ),
      time_value = lubridate::mdy(time_value),
      Week.Ending.Date = lubridate::mdy(Week.Ending.Date),
      target_end_date = if_else(
        as_of_date == "2025-10-04",
        Week.Ending.Date,
        time_value
      ),
      location = if_else(
        as_of_date == "2025-10-04",
        Region,
        region
      ) |>
        stringr::str_remove("^[0-9]+\\s+") |>
        stringr::str_to_lower() |>
        stringr::str_replace_all("[[:punct:]&&[^-]]", "") |>
        stringr::str_replace_all("\\s+", "-")
    ) |>
    select(
      as_of_date,
      location,
      target_end_date,
      observation
    ) |>
    arrange(target_end_date)

  stopifnot(
    all(colSums(is.na(NC_clean)) == 0),
    all(NC_clean$observation >= 0 & NC_clean$observation <= 100)
  )

  return(NC_clean)
}

# library(ggplot2)
# ggplot(NC_clean(), aes(x = target_end_date, y = observation, color = location)) +
#   geom_line() +
#   labs(
#     title = "NC Influenza Surveillance Data",
#     x = "Target End Date",
#     y = "Observation (%)"
#   ) +
#   theme_minimal()


merge_and_write_csv <- function(data, file) {
  locations <- unique(data$location)
  if (file.exists(file)) {
    original_data <- read_csv(file) %>%
      filter(!location %in% locations)
    data <- bind_rows(original_data, data)
  }
  write.table(
    data,
    file = file,
    sep = ",",
    row.names = FALSE,
    quote = which(names(data) %in% c("location", "target"))
  )
}


nc_time_series <- NC_clean() %>%
  mutate(as_of_date = as.Date(as_of_date)) %>%
  mutate(target = "Flu ED visits pct") %>%
  rename(as_of = as_of_date) %>%
  mutate(location = case_match(
    location,
    "nenc" ~ "Northeastern, NC",
    "senc" ~ "Southeastern, NC",
    "fay-area" ~ "Fayetteville Area, NC",
    "rtp-area" ~ "Research Triangle Park Area, NC",
    "triad-area" ~ "Triad Area, NC",
    "wnc" ~ "Western, NC",
    "clt-area" ~ "Charolette Area, NC",
    .default = location
  )) %>%
  relocate(as_of, location, target, target_end_date, observation)

nc_latest_data <- nc_time_series %>%
  group_by(location, target, target_end_date) %>%
  filter(as_of == max(as_of)) %>%
  slice(1L) %>%
  ungroup() %>%
  rename(oracle_value = observation) %>%
  select(-as_of) %>%
  relocate(target_end_date, location, target, oracle_value)

nc_oracle_output <- nc_latest_data %>%
  filter(target_end_date >= as.Date("2025-11-22")) %>%
  relocate(target_end_date, location, target, oracle_value)

nc_time_series <- nc_time_series %>%
  filter(target_end_date >= as.Date("2025-08-01"))

merge_and_write_csv(nc_time_series, "target-data/time-series.csv")
merge_and_write_csv(nc_latest_data, "target-data/latest-data.csv")
merge_and_write_csv(nc_oracle_output, "target-data/oracle-output.csv")
