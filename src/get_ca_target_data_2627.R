# This script downloads California Respiratory Virus Dashboard data from the
# CHHS open data portal and updates the 2026/2027 season California influenza
# admissions in the three target-data files.
library(dplyr)
library(readr)
library(lubridate)
library(stringr)

source_url <- paste0(
  "https://data.chhs.ca.gov/dataset/6724b36f-b89e-4fa7-9cbb-290526894511/",
  "resource/00a147ba-0410-4699-9e34-fd18bbb7017d/download/rv-dashboard.csv"
)
season <- "2026/2027"
target_name <- "Flu hosp admits"
age_groups <- c("0-4 yrs", "5-17 yrs", "18-64 yrs", ">64 yrs")
# as_of is the next Wednesday (or today if today is a Wednesday), so it lines
# up with the weekly as_of dates of the other locations in time-series.csv.
as_of <- Sys.Date() + (4 - wday(Sys.Date())) %% 7

# 1) Download the raw data and aggregate FLU_ADM across age groups for each
#    region and week of the season. "All Ages" is excluded, and so is "<18 yrs"
#    since it overlaps "0-4 yrs" and "5-17 yrs" (it currently has no FLU_ADM).
#    Blank FLU_ADM cells (suppressed small counts) are treated as missing and
#    dropped from the sum.
ca_raw <- read_csv(source_url, col_types = cols(.default = col_character()))

ca_latest <- ca_raw |>
  filter(SEASON == season, AGE_GRP %in% age_groups) |>
  mutate(
    target_end_date = mdy(WEEKENDING),
    location = RPHO_REGION |>
      str_to_lower() |>
      str_replace_all("[^a-z0-9]+", "-"),
    FLU_ADM = as.numeric(FLU_ADM)
  ) |>
  group_by(target_end_date, location) |>
  summarise(
    observation = if (all(is.na(FLU_ADM))) NA_real_ else sum(FLU_ADM, na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(!is.na(observation)) |>
  mutate(target = target_name) |>
  select(target_end_date, location, target, observation) |>
  arrange(target_end_date, location)

locations <- read_csv("auxiliary-data/locations.csv", show_col_types = FALSE)
stopifnot(
  nrow(ca_latest) > 0,
  all(ca_latest$location %in% locations$location),
  all(ca_latest$observation >= 0)
)

# 2) Stop without writing anything if the source has not changed since the
#    last update, so the workflow does not open a PR with only a new as_of.
latest_data <- read_csv("target-data/latest-data.csv", show_col_types = FALSE)
previous <- latest_data |>
  filter(target == target_name, location %in% ca_latest$location) |>
  semi_join(ca_latest |> distinct(target_end_date), by = "target_end_date") |>
  arrange(target_end_date, location)
if (isTRUE(all.equal(
  as.data.frame(previous),
  as.data.frame(ca_latest),
  check.attributes = FALSE
))) {
  message("California data unchanged since last update. Nothing written.")
  quit(save = "no", status = 0)
}

# 3) time-series: add this season's values under the as_of date. A rerun in
#    the same week replaces that week's values instead of duplicating them.
time_series <- read_csv("target-data/time-series.csv", show_col_types = FALSE) |>
  rows_upsert(
    ca_latest |>
      mutate(as_of = as_of) |>
      select(as_of, location, target, target_end_date, observation),
    by = c("as_of", "location", "target", "target_end_date")
  )

# 4) latest-data and oracle-output: replace this season's California values
#    with the newest ones, leaving every other row untouched.
latest_data <- latest_data |>
  rows_upsert(ca_latest, by = c("target_end_date", "location", "target"))

oracle_output <- read_csv("target-data/oracle-output.csv", show_col_types = FALSE) |>
  rows_upsert(
    ca_latest |> rename(oracle_value = observation),
    by = c("target_end_date", "location", "target")
  )

write_target <- function(data, file) {
  write.table(
    data,
    file = file,
    sep = ",",
    row.names = FALSE,
    quote = which(names(data) %in% c("location", "target"))
  )
}
write_target(time_series, "target-data/time-series.csv")
write_target(latest_data, "target-data/latest-data.csv")
write_target(oracle_output, "target-data/oracle-output.csv")
message("Wrote ", nrow(ca_latest), " California rows for ", season, ".")
