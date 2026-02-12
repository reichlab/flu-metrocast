library(hubUtils)
library(hubEnsembles)
library(hubData)
library(dplyr)
library(purrr)
here::i_am("src/get_ensemble_output.R")
library(here)
library(lubridate)


hub_path <- here()
hub_con <- connect_hub(hub_path)

## specify the reference_date to generate the ensemble model for
forecast_date <- as.Date(today())
ref_date = forecast_date + (6 - as.integer(format(forecast_date, "%u"))) %% 7
ref_date

model_names <- hub_con %>%
  filter(reference_date == ref_date) %>%
  select(model_id) %>%
  distinct() %>%
  collect()

model_names

required_horizons <- tibble::tibble(
  target = c("ILI ED visits pct", "Flu ED visits pct"),
  required = list(c(0, 1, 2, 3), c(0, 1, 2, 3))
)

reference_date = ref_date
# Identify valid models to include in the ensemble
valid_models <- hub_con %>%
  filter(
    reference_date == .env$reference_date,
    !(model_id %in% c("epiENGAGE-ensemble_mean", "epiENGAGE-lop_norm"))
  ) %>%
  collect_hub() %>%
  group_by(model_id, target, reference_date) %>%
  summarise(horizons = list(sort(unique(horizon))), .groups = "drop") %>%
  left_join(required_horizons, by = "target") %>%
  mutate(
    has_all_required = map2_lgl(horizons, required, ~ all(.y %in% .x))
  ) %>%
  group_by(model_id) %>%
  summarise(all_valid = all(has_all_required), .groups = "drop") %>%
  filter(all_valid) %>%
  pull(model_id)

linear_pool_norm <- hub_con %>%
  filter(
    reference_date == .env$reference_date,
    model_id %in% valid_models) %>%
  collect_hub() %>%
  left_join(required_horizons, by = "target") %>%
  filter(map2_lgl(horizon, required, ~ .x %in% .y)) %>%
  hubEnsembles::linear_pool(model_id = "linear-pool-normal")|>
  select(-model_id, -required)
dim(linear_pool_norm)
write.csv(linear_pool_norm, paste("model-output/epiENGAGE-lop_norm/",reference_date, "-epiENGAGE-lop_norm.csv", sep = ""), row.names = FALSE)


mean_ens <- hub_con %>%
  filter(
    reference_date == .env$reference_date,
    model_id %in% valid_models
  ) %>%
  collect_hub() %>%
  left_join(required_horizons, by = "target") %>%
  filter(map2_lgl(horizon, required, ~ .x %in% .y)) %>%
  hubEnsembles::simple_ensemble(model_id = "simple-ensemble-mean")|>
  select(-model_id, -required)
dim(mean_ens)
write.csv(mean_ens, paste("model-output/epiENGAGE-ensemble_mean/",reference_date, "-epiENGAGE-ensemble_mean.csv", sep = ""), row.names = FALSE)

