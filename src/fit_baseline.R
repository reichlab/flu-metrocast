# Trajectory baseline forecasts
# Run: Rscript src/fit_baseline_trajectory.R

source("src/quantile_baseline.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(arrow)
})

forecast_date <- Sys.Date()

reference_date <- forecast_date +
  (6 - as.integer(format(forecast_date, "%u"))) %% 7

reference_date <- as.Date(reference_date)

n_samples <- 100
n_horizons <- 4

weekly_seed <- as.integer(format(reference_date, "%Y%m%d"))
set.seed(weekly_seed)

# --------------------------------------------------
# Load data
# --------------------------------------------------

input <- read.csv(
  "target-data/latest-data.csv",
  stringsAsFactors = FALSE
) %>%
  mutate(target_end_date = as.Date(target_end_date)) %>%
  filter(
    target_end_date < reference_date,
    !is.na(location),
    location != "Unknown"
  )

required <- c(
  "location",
  "target",
  "target_end_date",
  "observation"
)

missing <- setdiff(required, names(input))

if (length(missing)) {
  stop("Missing columns: ", paste(missing, collapse = ", "))
}

# --------------------------------------------------
# Check latest observation dates
# --------------------------------------------------

latest_dates <- input %>%
  group_by(location, target) %>%
  summarise(
    last_observed_date = max(target_end_date),
    .groups = "drop"
  ) %>%
  mutate(
    weeks_behind = as.integer(
      (reference_date - last_observed_date) / 7
    ),
    simulation_horizons = n_horizons + weeks_behind - 1L,
    include = weeks_behind %in% c(1L, 2L)
  )

# --------------------------------------------------
# Locations requiring an extra simulation step
# --------------------------------------------------

extra_step_locations <- latest_dates %>%
  filter(weeks_behind == 2L) %>%
  arrange(location, target) %>%
  select(location, target, last_observed_date, weeks_behind)

cat("\n========================================\n")
cat("Locations requiring 5-step simulation\n")
cat("(Forecast starts from horizon -1)\n")
cat("========================================\n")

if (nrow(extra_step_locations) > 0) {
  print(extra_step_locations, n = Inf)
} else {
  cat("None\n")
}

# --------------------------------------------------
# Locations excluded from forecasting
# --------------------------------------------------

excluded_locations <- latest_dates %>%
  filter(!include) %>%
  arrange(location, target) %>%
  select(location, target, last_observed_date, weeks_behind)

cat("\n========================================\n")
cat("Locations excluded from forecasting\n")
cat("========================================\n")

if (nrow(excluded_locations) > 0) {
  print(excluded_locations, n = Inf)
} else {
  cat("None\n")
}

# --------------------------------------------------
# Summary
# --------------------------------------------------

cat("\n========================================\n")
cat("Forecasting summary\n")
cat("========================================\n")

cat("Reference date:", as.character(reference_date), "\n")
cat("Standard 4-step forecasts:",
    sum(latest_dates$weeks_behind == 1L), "\n")
cat("Extended 5-step forecasts:",
    nrow(extra_step_locations), "\n")
cat("Excluded forecasts:",
    nrow(excluded_locations), "\n\n")

# --------------------------------------------------
# Forecast one location-target series
# --------------------------------------------------

forecast_one_series <- function(data) {

  data <- arrange(data, target_end_date)

  key <- distinct(data, location, target)

  if (nrow(key) != 1L) {
    stop("Expected one location-target pair per group")
  }

  if (anyDuplicated(data$target_end_date)) {
    stop(
      "Duplicate target_end_date for ",
      key$location, " / ", key$target
    )
  }

  incidence <- as.numeric(data$observation)

  if (
    length(incidence) < 2L ||
    any(!is.finite(incidence))
  ) {
    stop(
      "Insufficient or nonfinite observations for ",
      key$location, " / ", key$target
    )
  }

  last_observed_date <- max(data$target_end_date)

  weeks_behind <- as.integer(
    (reference_date - last_observed_date) / 7
  )

  # Skip if data are more than two weeks old
  if (!weeks_behind %in% c(1L, 2L)) {
    return(NULL)
  }

  # 1 week behind -> 4 simulation steps
  # 2 weeks behind -> 5 simulation steps
  simulation_horizons <- n_horizons + weeks_behind - 1L

  fitted <- fit_quantile_baseline(
    incidence,
    symmetrize = TRUE
  )

  trajectories <- new_predict.quantile_baseline(
    quantile_baseline = fitted,
    newdata = incidence,
    horizon = simulation_horizons,
    nsim = n_samples
  )

  trajectories <- pmax(trajectories, 0)

  # Select the final four simulation steps
  # weeks_behind = 1 -> columns 1:4
  # weeks_behind = 2 -> columns 2:5
  selected_steps <- seq.int(
    from = weeks_behind,
    length.out = n_horizons
  )

  trajectories <- trajectories[
    , selected_steps, drop = FALSE
  ]

  stopifnot(ncol(trajectories) == n_horizons)

  bind_rows(
    lapply(seq_len(n_horizons), function(h) {

      tibble(
        reference_date = reference_date,
        target = key$target,
        target_end_date = reference_date + 7L * (h - 1L),
        location = key$location,
        output_type = "sample",
        output_type_id = paste0("T", seq_len(n_samples)),
        value = as.numeric(trajectories[, h])
      )

    })
  )
}

# --------------------------------------------------
# Generate forecasts
# --------------------------------------------------

forecast_output <- input %>%
  group_by(location, target) %>%
  group_split() %>%
  map_dfr(forecast_one_series) %>%
  select(
    reference_date,
    target,
    target_end_date,
    location,
    output_type,
    output_type_id,
    value
  )

# --------------------------------------------------
# Validate
# --------------------------------------------------

stopifnot(
  nrow(forecast_output) > 0,
  !anyNA(forecast_output),
  all(forecast_output$value >= 0),
  all(forecast_output$output_type == "sample")
)

check <- forecast_output %>%
  count(
    reference_date,
    target,
    location,
    output_type_id,
    name = "n_dates"
  )

stopifnot(all(check$n_dates == n_horizons))

# --------------------------------------------------
# Save Parquet
# --------------------------------------------------

output_dir <- "model-output/epiENGAGE-baseline"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

output_file <- file.path(
  output_dir,
  paste0(
    reference_date,
    "-epiENGAGE-baseline.parquet"
  )
)

arrow::write_parquet(
  forecast_output,
  output_file
)

message(
  "Saved ",
  nrow(forecast_output),
  " rows to ",
  output_file
)
