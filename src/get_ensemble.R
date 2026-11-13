
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
target_horizons <- list(
  "Flu ED visits pct" = 0:3,
  "Flu hosp admits" = -1:3
)

excluded_models <- c(
  "epiENGAGE-ensemble_mean",
  "epiENGAGE-lop_norm",
  "epiENGAGE-ensemble_short",
  "epiENGAGE-ensemble_long",
  "epiENGAGE-baseline",
  "FluSight-ensemble"
)

samples <- submitted %>%
  filter(
    output_type == "sample",
    !model_id %in% excluded_models,
    target %in% names(target_horizons)
  ) %>%
  mutate(
    horizon = as.integer(
      (target_end_date - reference_date) / 7
    )
  ) %>%
  filter(
    !is.na(horizon),
    horizon >= -1,
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
  filter(max_horizon > 3)

cat("\nLong-term candidate models:\n")

print(
  long_candidates %>%
    distinct(target, model_id) %>%
    arrange(target, model_id),
  n = Inf
)

get_long_horizons <- function(target_name) {

  candidates <- long_candidates %>%
    filter(target == target_name)

  if (nrow(candidates) == 0) {
    return(NULL)
  }

  start_h <- min(target_horizons[[target_name]])

  start_h:min(candidates$max_horizon)
}

long_ed_horizons <- get_long_horizons("Flu ED visits pct")
long_ca_horizons <- get_long_horizons("Flu hosp admits")

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

# Short-term
short_ed_input <- prepare_trajectories(
  samples %>% filter(target == "Flu ED visits pct"),
  horizons = target_horizons[["Flu ED visits pct"]]
)

short_ca_input <- prepare_trajectories(
  samples %>% filter(target == "Flu hosp admits"),
  horizons = target_horizons[["Flu hosp admits"]]
)

# Long-term
long_ed_input <- NULL
long_ca_input <- NULL

if (!is.null(long_ed_horizons)) {

  long_ed_models <- long_candidates %>%
    filter(target == "Flu ED visits pct") %>%
    pull(model_id) %>%
    unique()

  long_ed_input <- prepare_trajectories(
    samples %>% filter(target == "Flu ED visits pct"),
    horizons = long_ed_horizons,
    models = long_ed_models
  )
}

if (!is.null(long_ca_horizons)) {

  long_ca_models <- long_candidates %>%
    filter(target == "Flu hosp admits") %>%
    pull(model_id) %>%
    unique()

  long_ca_input <- prepare_trajectories(
    samples %>% filter(target == "Flu hosp admits"),
    horizons = long_ca_horizons,
    models = long_ca_models
  )
}


# ------------------------------------------------------------
# 5. Validate and save
# ------------------------------------------------------------

validate_and_save <- function(data, model_id, horizons_by_target) {

  if (nrow(data) == 0) {
    stop("Empty ensemble: ", model_id)
  }

  for (target_name in unique(data$target)) {

    target_data <- data %>%
      filter(target == target_name)

    horizons <- horizons_by_target[[target_name]]

    if (is.null(horizons)) {
      stop("Missing horizons for: ", target_name)
    }

  n_horizons <- length(horizons)
  required_dates <- reference_date + 7 * horizons

  check <- target_data %>%
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

  check_locations <- target_data %>%
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
  }

  # Original output formatting and saving
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

short_outputs <- list()

if (nrow(short_ed_input) > 0) {

  short_outputs[["Flu ED visits pct"]] <-
    hubEnsembles::linear_pool(
      short_ed_input,
      model_id = "epiENGAGE-ensemble_short",
      compound_taskid_set = c(
        "reference_date", "target", "location"
      ),
      n_output_samples = n_samples
    )
}

if (nrow(short_ca_input) > 0) {

  short_outputs[["Flu hosp admits"]] <-
    hubEnsembles::linear_pool(
      short_ca_input,
      model_id = "epiENGAGE-ensemble_short",
      compound_taskid_set = c(
        "reference_date", "target", "location"
      ),
      n_output_samples = n_samples
    )
}

if (length(short_outputs) == 0) {
  stop("No complete short-term trajectories.")
}

short_ensemble <- bind_rows(short_outputs)

short_output <- validate_and_save(
  short_ensemble,
  model_id = "epiENGAGE-ensemble_short",
  horizons_by_target = target_horizons
)

# ------------------------------------------------------------
# 7. Long-term ensemble
# ------------------------------------------------------------

long_outputs <- list()
long_horizons_by_target <- list()

if (!is.null(long_ed_input) && nrow(long_ed_input) > 0) {

  long_outputs[["Flu ED visits pct"]] <-
    hubEnsembles::linear_pool(
      long_ed_input,
      model_id = "epiENGAGE-ensemble_long",
      compound_taskid_set = c(
        "reference_date", "target", "location"
      ),
      n_output_samples = n_samples
    )

  long_horizons_by_target[["Flu ED visits pct"]] <-
    long_ed_horizons
}

if (!is.null(long_ca_input) && nrow(long_ca_input) > 0) {

  long_outputs[["Flu hosp admits"]] <-
    hubEnsembles::linear_pool(
      long_ca_input,
      model_id = "epiENGAGE-ensemble_long",
      compound_taskid_set = c(
        "reference_date", "target", "location"
      ),
      n_output_samples = n_samples
    )

  long_horizons_by_target[["Flu hosp admits"]] <-
    long_ca_horizons
}

if (length(long_outputs) > 0) {

  long_ensemble <- bind_rows(long_outputs)

  long_output <- validate_and_save(
    long_ensemble,
    model_id = "epiENGAGE-ensemble_long",
    horizons_by_target = long_horizons_by_target
  )

} else {
  cat("\nSkipping long-term ensemble this week.\n")
}
