
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
    is_ca = target == "Flu hosp admits",
    n_submission_horizons = if_else(is_ca, 5L, 4L),
    include = weeks_behind %in% c(1L, 2L),

    # Number of simulation steps needed
    simulation_horizons = weeks_behind + 3L
  )
# --------------------------------------------------
# Locations requiring an extra simulation step
# --------------------------------------------------

extra_step_locations <- latest_dates %>%
  filter(weeks_behind == 2L) %>%
  arrange(location, target) %>%
  select(
    location,
    target,
    last_observed_date,
    weeks_behind,
    simulation_horizons
  )

cat("\n========================================\n")
cat("Locations with 2-week reporting delay\n")
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
  select(
    location,
    target,
    last_observed_date,
    weeks_behind
  )

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

cat(
  "Standard ED forecasts:",
  sum(latest_dates$include & !latest_dates$is_ca),
  "\n"
)

cat(
  "California hospital forecasts:",
  sum(latest_dates$include & latest_dates$is_ca),
  "\n"
)

cat(
  "Excluded forecasts:",
  nrow(excluded_locations),
  "\n\n"
)

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

  # Skip locations with unsupported reporting delays
  if (!weeks_behind %in% c(1L, 2L)) {
    return(NULL)
  }

  # California: -1, 0, 1, 2, 3
  # Other states: 0, 1, 2, 3
  is_ca <- key$target == "Flu hosp admits"

  submission_horizons <- if (is_ca) {
    -1:3
  } else {
    0:3
  }

  # Simulation step for each submission horizon
  # Step 0 represents the latest observed value
  selected_steps <- weeks_behind + submission_horizons

  # Number of future simulation steps required
  simulation_horizons <- max(selected_steps)

  # Fit baseline model
  fitted <- fit_quantile_baseline(
    incidence,
    symmetrize = TRUE
  )

  # Generate future trajectories
  trajectories <- new_predict.quantile_baseline(
    quantile_baseline = fitted,
    newdata = incidence,
    horizon = simulation_horizons,
    nsim = n_samples
  )

  trajectories <- pmax(trajectories, 0)

  # Select required simulation steps
  # Step 0: latest observed value (if applicable)
  # Step >= 1: simulated future values
  selected_trajectories <- matrix(
    NA_real_,
    nrow = n_samples,
    ncol = length(submission_horizons)
  )

  for (h in seq_along(submission_horizons)) {

    step <- selected_steps[h]

    if (step == 0L) {

      # Already observed week
      selected_trajectories[, h] <- tail(incidence, 1)

    } else {

      selected_trajectories[, h] <- trajectories[, step]

    }
  }

  stopifnot(
    ncol(selected_trajectories) ==
      length(submission_horizons)
  )

  # Convert trajectories to hub submission format
  bind_rows(
    lapply(seq_along(submission_horizons), function(h) {

      horizon <- submission_horizons[h]

      tibble(
        reference_date = reference_date,
        target = key$target,
        target_end_date = reference_date + 7L * horizon,
        location = key$location,
        output_type = "sample",
        output_type_id = if (is_ca) {
          paste0("CA", seq_len(n_samples))
        } else {
          paste0("T", seq_len(n_samples))
        },
        value = as.numeric(selected_trajectories[, h])
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

# Expected horizons for each target
expected_horizons <- function(target) {
  if (target == "Flu hosp admits") {
    -1:3
  } else {
    0:3
  }
}

# Calculate submission horizon from target end date
forecast_check <- forecast_output %>%
  mutate(
    horizon = as.integer(
      (target_end_date - reference_date) / 7
    )
  )

# Check number of dates per trajectory
check <- forecast_check %>%
  count(
    reference_date,
    target,
    location,
    output_type_id,
    name = "n_dates"
  )

stopifnot(
  all(
    check$n_dates ==
      ifelse(
        check$target == "Flu hosp admits",
        5L,
        4L
      )
  )
)

# Check exact horizon sets for each location-target
horizon_check <- forecast_check %>%
  group_by(location, target) %>%
  summarise(
    valid = setequal(
      unique(horizon),
      expected_horizons(first(target))
    ),
    .groups = "drop"
  )

stopifnot(all(horizon_check$valid))

# Print horizon summary
cat("\n========================================\n")
cat("Submission horizon summary\n")
cat("========================================\n")

print(
  forecast_check %>%
    group_by(target) %>%
    summarise(
      horizons = paste(
        sort(unique(horizon)),
        collapse = ", "
      ),
      n_locations = n_distinct(location),
      .groups = "drop"
    ),
  n = Inf
)

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
