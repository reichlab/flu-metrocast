library(dplyr)
library(ggplot2)
library(hubUtils)
library(hubVis)
library(hubEnsembles)

model_names = c("epiENGAGE-GBQR", "epiENGAGE-Copycat", "epiENGAGE-INFLAenza", "epiforecasts-dyngam")
reference_date = "2025-03-15"

for(i in 1:length(model_names)){
  assign("tmp", read.csv(paste("https://raw.githubusercontent.com/reichlab/flu-metrocast/main/model-output/", model_names[i], "/", reference_date, "-", model_names[i], ".csv", sep="")))
  assign(paste("output",i, sep=""), get("tmp") %>% mutate(model_id = model_names[i]))
}

forecast_output <- output1 %>% 
  bind_rows(output2) %>%
  bind_rows(output3) %>%
  bind_rows(output4) 
  

linear_pool_norm <- forecast_output |>
  hubEnsembles::linear_pool(model_id = "linear-pool-normal")
write.csv(linear_pool_norm, paste("model-output/epiENGAGE-lop_norm/",reference_date, "-epiENGAGE-lop_norm.csv", sep = ""), row.names = FALSE)

mean_ens <- forecast_output |>
  hubEnsembles::simple_ensemble(
    model_id = "simple-ensemble-mean"
  )

write.csv(mean_ens, paste("model-output/epiENGAGE-ensemble_mean/",reference_date, "-epiENGAGE-ensemble_mean.csv", sep = ""), row.names = FALSE)
