library(hubUtils)
library(hubVis)
library(hubEnsembles)
library(hubData)
library(dplyr)


hub_path <- "/Users/dk29776/Dropbox/UTAustin/flu-metrocast"
hub_con <- connect_hub(hub_path)

model_names <- hub_con %>%  
  select(model_id) %>% 
  distinct() %>% 
  collect()

model_names

reference_date = "2025-03-15"

linear_pool_norm <- hub_con %>%
  filter(
    reference_date == reference_date,
    !(model_id %in% c("epiENGAGE-ensemble_mean", "epiENGAGE-lop_norm"))
  ) %>%
  collect_hub() %>%
  hubEnsembles::linear_pool(model_id = "linear-pool-normal")|>
  select(-model_id)
write.csv(linear_pool_norm, paste("model-output/epiENGAGE-lop_norm/",reference_date, "-epiENGAGE-lop_norm.csv", sep = ""), row.names = FALSE)


mean_ens <- hub_con %>%
  filter(
    reference_date == reference_date,
    !(model_id %in% c("epiENGAGE-ensemble_mean", "epiENGAGE-lop_norm"))
  ) %>%
  collect_hub() %>%
  hubEnsembles::simple_ensemble(model_id = "simple-ensemble-mean")|>
  select(-model_id)

write.csv(mean_ens, paste("model-output/epiENGAGE-ensemble_mean/",reference_date, "-epiENGAGE-ensemble_mean.csv", sep = ""), row.names = FALSE)

