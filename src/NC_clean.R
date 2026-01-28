# This script cleans and processes the NC specific target data.
library(magrittr)
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
    pattern = "NC_DETECT_Respiratory.*\\.csv$",
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
    select(-starts_with("X", ignore.case = FALSE))

  NC_clean <-
    NC_raw |>
    mutate(
      Percentage.Of.Total.ED.Visits = as.numeric(
        gsub("%", "", Percentage.Of.Total.ED.Visits)
      ),
      observation = if_else(
        as_of_date == "2025-10-08",
        Percentage.Of.Total.ED.Visits,
        value
      ),
      target = if_else(
        is.na(Percentage.Of.Total.ED.Visits),
        signal,
        "pct_ed_visits_influenza"
      ),
      time_value = lubridate::mdy(time_value),
      Week.Ending.Date = lubridate::mdy(Week.Ending.Date),
      target_end_date = if_else(
        as_of_date == "2025-10-08",
        Week.Ending.Date,
        time_value
      ),
      location = if_else(
        as_of_date == "2025-10-08",
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
      target,
      target_end_date,
      observation
    ) |>
    mutate(as_of = lubridate::ymd(as_of_date)) |>
    select(!as_of_date) |>
    arrange(target_end_date)

  stopifnot(
    !anyNA(NC_clean),
    all(NC_clean$observation >= 0 & NC_clean$observation <= 100),
    setequal(unique(NC_clean$target), "pct_ed_visits_influenza")
  )

  return(NC_clean)
}

#' @title
#' Merge and write target CSV files.
#'
#' @description
#' Helper function to write data to the 'target-data/' directory files.
#'
#' @param data A formated tibble corresponding to the "new" data.
#' @param file The filename to write the `data` to.
#' @param mode Either 'append' or 'override' indicating the write mode. If
#' 'append' then the `data` is just appended to `file`. If 'override' then the
#' locations from `data` found in `file` are removed from `file` and then `data`
#' is appended to `file`.
#'
#' @returns
#' `NULL`
merge_and_write_csv <- function(data, file, mode) {
  # Check that `mode` is either 'append' or 'override'
  obs_col <- if (file == "target-data/oracle-output.csv") {
    "oracle_value"
  } else {
    "observation"
  }
  if (!mode %in% c("append", "override")) {
    stop(
      "Write mode '",
      mode,
      "' is not supported, please use 'append' or 'override'."
    )
  }
  # If file already exists have to consider the mode
  if (file.exists(file)) {
    original_data <- read_csv(file)
    if (mode == "override") {
      # In 'override' mode delete all data corresponding to the locations for
      # which we have data for and reappend to the original data.
      data <- rows_upsert(
        original_data,
        data,
        by = setdiff(colnames(data), obs_col)
      )
    } else {
      # In 'append' mode remove any data which is already present in the
      # original
      data <- anti_join(
        data,
        original_data,
        by = setdiff(
          union(colnames(data), colnames(original_data)),
          obs_col
        )
      )
    }
  }
  if (nrow(data)) {
    # If `data` has rows then write it.
    write.table(
      data,
      file = file,
      append = (mode == "append" && file.exists(file)),
      sep = ",",
      row.names = FALSE,
      col.names = (mode == "override" || !file.exists(file)),
      quote = which(names(data) %in% c("location", "target"))
    )
  }
}

# # Optional plot for debugging purposes
# library(ggplot2)
# ggplot(
#   NC_clean(),
#   aes(x = target_end_date, y = observation, color = location)
# ) +
#   geom_line() +
#   labs(
#     title = "NC Influenza Surveillance Data",
#     x = "Target End Date",
#     y = "Observation (%)"
#   ) +
#   theme_minimal()

# 0) From the `NC_clean` function we interpolate forward the last observation by
#    location, target, and target_end_date. This allows us to have observations
#    prior to 2025 present in our full dataset despite the fact tha NC detect
#    only provided them for a short period of time. We can assume that those old
#    observations do not change.
nc_clean <- NC_clean() %>%
  complete(nesting(location, target, target_end_date), as_of) %>%
  filter(target_end_date <= as_of) %>%
  group_by(location, target, target_end_date) %>%
  arrange(as_of, .by_group = TRUE) %>%
  fill(observation, .direction = "down") %>%
  ungroup()

# 1) We take the return of interpolation and subset it to the as of date minimum
#    for this season of flu metrocast hub and do some light formatting. Right
#    now `nc_time_series` contains all 'as_of'/'target_end_date' combos we have.
nc_time_series <- nc_clean %>%
  filter(as_of >= as.Date("2025-11-19")) %>%
  mutate(target = "Flu ED visits pct") %>%
  relocate(as_of, location, target, target_end_date, observation)

# 2) Compute `nc_latest_data` from `nc_time_series` by selecting the row with
#    the greatest 'as_of' date for a given 'location', 'target',
#    'target_end_date'.
nc_latest_data <- nc_time_series %>%
  group_by(location, target, target_end_date) %>%
  filter(as_of == max(as_of)) %>%
  slice(1L) %>%
  ungroup() %>%
  select(-as_of) %>%
  relocate(target_end_date, location, target, observation)

# 3) Compute `nc_oracle_output` from `nc_latest_data` to subsetting it to this
#    season of flu metrocast hub.
nc_oracle_output <- nc_latest_data %>%
  filter(target_end_date >= as.Date("2025-11-22")) %>%
  rename(oracle_value = observation) %>%
  relocate(target_end_date, location, target, oracle_value)

# 4) Subset `nc_time_series` to data with a 'target_end_date' of 2025-08-02 or
#    later and the max 'as_of' date.
time_series_as_of_filter_date <- as.Date(Sys.getenv(
  x = "AS_OF_FILTER_DATE",
  unset = as.character(max(nc_time_series$as_of))
))
nc_time_series <- nc_time_series %>%
  filter(target_end_date >= as.Date("2024-08-02")) %>%
  filter(as_of == time_series_as_of_filter_date)

# 5) Write the `nc_time_series`, `nc_latest_data`, and `nc_oracle_output`
#    variables to the "target-data/time-series.csv",
#    "target-data/latest-data.csv", and "target-data/oracle-output.csv",
#    respectively. The first is appended and the last two are overridden.
if (nrow(nc_time_series)) {
  merge_and_write_csv(
    nc_time_series,
    "target-data/time-series.csv",
    "append"
  )
}
if (nrow(nc_latest_data)) {
  merge_and_write_csv(
    nc_latest_data,
    "target-data/latest-data.csv",
    "override"
  )
}
if (nrow(nc_oracle_output)) {
  merge_and_write_csv(
    nc_oracle_output,
    "target-data/oracle-output.csv",
    "override"
  )
}
