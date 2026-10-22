
# ============================================================
# Flu-MetroCast: Weekly Trajectory Ensembles
#
# Short-term: horizons 0–3
# Long-term: automatically determined each week
# Equal-weight mixture of complete model trajectories
# ============================================================

library(hubUtils)
library(hubData)
library(dplyr)
library(purrr)
library(here)

here::i_am("src/get_ensemble.R")

set.seed(123)

# ------------------------------------------------------------
# 1. Connect to hub
# ------------------------------------------------------------

hub_path <- here()
hub_con <- connect_hub(hub_path)

forecast_date <- Sys.Date()

reference_date <- as.Date(
  forecast_date +
    (6 - as.integer(format(forecast_date, "%u"))) %% 7
)

cat("Reference date:", as.character(reference_date), "\n")

submitted <- hub_con %>%
  filter(reference_date == .env$reference_date) %>%
  collect_hub() %>%
  mutate(
    reference_date = as.Date(reference_date),
    target_end_date = as.Date(target_end_date)
  )

# ------------------------------------------------------------
# 2. Settings
# ------------------------------------------------------------

n_samples <- 100
short_horizons <- 0:3

excluded_models <- c(
  "epiENGAGE-ensemble_mean",
  "epiENGAGE-lop_norm",
  "epiENGAGE-ensemble_short",
  "epiENGAGE-ensemble_long",
  "FluSight-ensemble"
)

samples <- submitted %>%
  filter(
    output_type == "sample",
    !model_id %in% excluded_models
  ) %>%
  mutate(
    horizon = as.integer(
      (target_end_date - reference_date) / 7
    )
  ) %>%
  filter(
    !is.na(horizon),
    horizon >= 0,
    target_end_date == reference_date + 7 * horizon
  )

if (nrow(samples) == 0) {
  stop("No sample forecasts found for this reference date.")
}

# ------------------------------------------------------------
# 3. Detect long-term models and horizon
# ------------------------------------------------------------

# Find models that submitted beyond horizon 3.
# Only complete, consecutive horizon ranges are considered.

model_horizons <- samples %>%
  group_by(model_id, target, location) %>%
  summarise(
    max_horizon = max(horizon),
    .groups = "drop"
  )

long_candidates <- model_horizons %>%
  filter(max_horizon > max(short_horizons))

if (nrow(long_candidates) == 0) {
  cat("No long-term forecasts submitted this week.\n")
  long_horizons <- NULL
} else {

  # Common long-term horizon across candidate models.
  # This avoids extending the ensemble beyond the
  # shortest contributing long-term forecast.

  long_max_horizon <- min(long_candidates$max_horizon)
  long_horizons <- 0:long_max_horizon

  cat(
    "Detected long-term horizon: 0–",
    long_max_horizon, "\n",
    sep = ""
  )
}

cat("\nLong-term candidate models:\n")

print(
  long_candidates %>%
    distinct(model_id) %>%
    arrange(model_id),
  n = Inf
)

# ------------------------------------------------------------
# 4. Prepare complete trajectories
# ------------------------------------------------------------

prepare_trajectories <- function(data, horizons, models = NULL) {

  required_dates <- reference_date + 7 * horizons

  result <- data %>%
    filter(target_end_date %in% required_dates)

  if (!is.null(models)) {
    result <- result %>%
      filter(model_id %in% models)
  }

  result %>%
    group_by(
      model_id, reference_date, target,
      location, output_type_id
    ) %>%
    filter(
      n() == length(required_dates),
      n_distinct(target_end_date) == length(required_dates),
      all(required_dates %in% target_end_date)
    ) %>%
    ungroup() %>%
    select(-horizon)
}

short_input <- prepare_trajectories(
  samples,
  horizons = short_horizons
)

long_input <- NULL

if (!is.null(long_horizons)) {

  long_models <- unique(long_candidates$model_id)

  long_input <- prepare_trajectories(
    samples,
    horizons = long_horizons,
    models = long_models
  )
}

# ------------------------------------------------------------
# 5. Validate and save
# ------------------------------------------------------------

validate_and_save <- function(data, model_id, horizons) {

  n_horizons <- length(horizons)
  required_dates <- reference_date + 7 * horizons

  check <- data %>%
    group_by(reference_date, target, location, output_type_id) %>%
    summarise(
      n_rows = n(),
      n_dates = n_distinct(target_end_date),
      has_all_dates = all(required_dates %in% target_end_date),
      .groups = "drop"
    )

  if (any(
    check$n_rows != n_horizons |
    check$n_dates != n_horizons |
    !check$has_all_dates
  )) {
    stop("Incomplete trajectories in ", model_id)
  }

  check_locations <- data %>%
    group_by(reference_date, target, location) %>%
    summarise(
      n_samples = n_distinct(output_type_id),
      n_rows = n(),
      .groups = "drop"
    )

  if (any(
    check_locations$n_samples != n_samples |
    check_locations$n_rows != n_samples * n_horizons
  )) {
    stop("Invalid sample counts in ", model_id)
  }

  output <- data %>%
    group_by(reference_date, target, location) %>%
    mutate(
      output_type_id = paste0(
        "S",
        match(output_type_id, unique(output_type_id))
      )
    ) %>%
    ungroup() %>%
    select(
      reference_date, target, target_end_date,
      location, output_type, output_type_id, value
    ) %>%
    arrange(
      target,
      location,
      output_type_id,
      target_end_date
    )

  output_dir <- file.path(hub_path, "model-output", model_id)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  output_file <- file.path(
    output_dir,
    paste0(reference_date, "-", model_id, ".parquet")
  )

  arrow::write_parquet(output, output_file)

  cat(
    "\n", model_id, ": ",
    n_distinct(output$location), " locations, ",
    nrow(output), " rows\n",
    "Saved: ", output_file, "\n",
    sep = ""
  )

  invisible(output)
}

# ------------------------------------------------------------
# 6. Short-term ensemble
# ------------------------------------------------------------

short_ensemble <- hubEnsembles::linear_pool(
  short_input,
  model_id = "epiENGAGE-ensemble_short",
  compound_taskid_set = c(
    "reference_date", "target", "location"
  ),
  n_output_samples = 100
)

short_output <- validate_and_save(
  short_ensemble,
  model_id = "epiENGAGE-ensemble_short",
  horizons = short_horizons
)

# ------------------------------------------------------------
# 7. Long-term ensemble
# ------------------------------------------------------------

if (!is.null(long_horizons) && nrow(long_input) > 0) {

  long_ensemble <- hubEnsembles::linear_pool(
    long_input,
    model_id = "epiENGAGE-ensemble_long",
    compound_taskid_set = c(
      "reference_date", "target", "location"
    ),
    n_output_samples = 100
  )

  long_output <- validate_and_save(
    long_ensemble,
    model_id = "epiENGAGE-ensemble_long",
    horizons = long_horizons
  )

} else {
  cat("\nSkipping long-term ensemble this week.\n")
}
