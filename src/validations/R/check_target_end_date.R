# Custom validations of `target_end_date` deployed via hub-config/validations.yml.
#
# Through the 2025/26 season, rounds used (reference_date, horizon, target_end_date)
# with target_end_date derived as reference_date + horizon weeks. From the 2026/27
# season on, rounds have no horizon task ID and target_end_date is a true task ID.
# Each check below decides whether it applies based on whether the round being
# validated has a `horizon` task ID in tasks.json, and skips itself otherwise.

round_has_task_id <- function(hub_path, round_id, task_id) {
  config_tasks <- hubUtils::read_config(hub_path, "tasks")
  task_id %in% hubUtils::get_round_task_id_names(config_tasks, round_id)
}

# Rounds with a horizon task ID: target_end_date must equal
# reference_date + horizon * timediff.
cstm_check_tbl_horizon_timediff <- function(
  tbl,
  file_path,
  hub_path,
  round_id,
  t0_colname = "reference_date",
  t1_colname = "target_end_date",
  horizon_colname = "horizon",
  timediff = lubridate::weeks()
) {
  if (!round_has_task_id(hub_path, round_id, horizon_colname)) {
    return(
      hubValidations::capture_check_info(
        file_path = file_path,
        msg = cli::format_inline(
          "Round {.val {round_id}} has no {.var {horizon_colname}} task ID. Check skipped."
        )
      )
    )
  }
  hubValidations::opt_check_tbl_horizon_timediff(
    tbl = tbl,
    file_path = file_path,
    hub_path = hub_path,
    t0_colname = t0_colname,
    t1_colname = t1_colname,
    horizon_colname = horizon_colname,
    timediff = timediff
  )
}

# Rounds without a horizon task ID: for each target and location in the file,
# the set of target_end_date values must be exactly the weeks from the target's
# first horizon (`first_horizon`, default `default_first_horizon`) to:
#   - the end of the season, if the model's metadata has `long_term_forecasts: true`
#   - horizon `short_term_last_horizon`, if it has `long_term_forecasts: false`
#     or does not set it.
# Horizons are counted in weeks from reference_date. The end of the season is
# the last target_end_date tasks.json lists for the target in the round.
cstm_check_tbl_target_end_dates <- function(
  tbl,
  file_path,
  hub_path,
  round_id,
  file_meta,
  first_horizon = list(),
  default_first_horizon = 0L,
  short_term_last_horizon = 3L,
  t0_colname = "reference_date",
  t1_colname = "target_end_date",
  horizon_colname = "horizon"
) {
  if (round_has_task_id(hub_path, round_id, horizon_colname)) {
    return(
      hubValidations::capture_check_info(
        file_path = file_path,
        msg = cli::format_inline(
          "Round {.val {round_id}} has a {.var {horizon_colname}} task ID. Check skipped."
        )
      )
    )
  }

  model_id <- file_meta$model_id
  long_term <- get_long_term_forecasts(hub_path, model_id)
  season_end <- get_season_end(hub_path, round_id, t1_colname)
  tbl <- unique(tbl[, c("target", "location", t0_colname, t1_colname)])
  tbl[[t0_colname]] <- as.Date(tbl[[t0_colname]])
  tbl[[t1_colname]] <- as.Date(tbl[[t1_colname]])

  problems <- split(tbl, list(tbl$target, tbl$location), drop = TRUE) |>
    purrr::map(function(x) {
      target <- x$target[1]
      ref_date <- x[[t0_colname]][1]
      h0 <- first_horizon[[target]]
      if (is.null(h0)) {
        h0 <- default_first_horizon
      }
      start <- ref_date + 7L * h0
      end <- season_end[[target]]
      if (!long_term) {
        end <- min(end, ref_date + 7L * short_term_last_horizon)
      }
      expected <- seq(start, end, by = 7L)
      actual <- x[[t1_colname]]
      missing <- sort(setdiff(expected, actual))
      extra <- sort(setdiff(actual, expected))
      if (length(missing) == 0L && length(extra) == 0L) {
        return(NULL)
      }
      data.frame(
        target = target,
        location = x$location[1],
        missing = paste(as.Date(missing), collapse = ", "),
        extra = paste(as.Date(extra), collapse = ", ")
      )
    }) |>
    purrr::list_rbind()

  check <- is.null(problems) || nrow(problems) == 0L
  details <- NULL
  if (!check) {
    # Group locations with the same problem to keep the message short.
    details <- split(problems, problems[c("target", "missing", "extra")], drop = TRUE) |>
      purrr::map_chr(function(x) {
        parts <- c(
          if (nzchar(x$missing[1])) paste("missing", x$missing[1]),
          if (nzchar(x$extra[1])) paste("unexpected", x$extra[1])
        )
        cli::format_inline(
          "{.val {x$target[1]}} for location{?s} {.val {x$location}}: ",
          paste(parts, collapse = "; "),
          "."
        )
      }) |>
      paste(collapse = " ")
  }

  hubValidations::capture_check_cnd(
    check = check,
    file_path = file_path,
    msg_subject = cli::format_inline(
      "{.var {t1_colname}} values for each target and location"
    ),
    msg_verbs = c("cover", "must cover"),
    msg_attribute = cli::format_inline(
      "exactly the weeks required of a model with
      {.field long_term_forecasts}: {tolower(long_term)}."
    ),
    details = details
  )
}

# `long_term_forecasts` from the model's metadata file. Not set means FALSE.
get_long_term_forecasts <- function(hub_path, model_id) {
  path <- fs::path(hub_path, "model-metadata", model_id, ext = c("yml", "yaml"))
  path <- path[fs::file_exists(path)]
  if (length(path) == 0L) {
    return(FALSE)
  }
  isTRUE(yaml::read_yaml(path[1])[["long_term_forecasts"]])
}

# Last target_end_date tasks.json lists for each target in the round.
get_season_end <- function(hub_path, round_id, t1_colname) {
  config_tasks <- hubUtils::read_config(hub_path, "tasks")
  model_tasks <- hubUtils::get_round_model_tasks(config_tasks, round_id)
  ends <- purrr::map(model_tasks, function(mt) {
    targets <- unlist(mt$task_ids$target, use.names = FALSE)
    end <- max(as.Date(unlist(mt$task_ids[[t1_colname]], use.names = FALSE)))
    purrr::set_names(rep(list(end), length(targets)), targets)
  })
  purrr::list_flatten(ends)
}
