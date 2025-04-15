library(hubUtils)
library(hubVis)
library(hubEnsembles)
library(hubData)
library(dplyr)
library(purrr)

hub_path <- "/Users/dk29776/Dropbox/UTAustin/flu-metrocast"
hub_con <- connect_hub(hub_path)

model_names <- hub_con %>%
  select(model_id) %>%
  distinct() %>%
  collect()

model_names

reference_date = "2025-04-12"

required_horizons <- tibble::tibble(
  target = c("ILI ED visits", "Flu ED visits pct"),
  required = list(c(0, 1, 2, 3), c(-1, 0, 1, 2))
)

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
    has_all_required = map2_lgl(horizons, required, ~ all(.y %in% .x))  # 조건을 만족하는지 확인
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
  select(-model_id, required)
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
  select(-model_id, required)
dim(mean_ens)
write.csv(mean_ens, paste("model-output/epiENGAGE-ensemble_mean/",reference_date, "-epiENGAGE-ensemble_mean.csv", sep = ""), row.names = FALSE)

