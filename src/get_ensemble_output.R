library(hubUtils)
library(hubVis)
library(hubEnsembles)
library(hubData)


library(gh)
library(purrr)
library(readr)
library(dplyr)

# GitHub API request to list files in the "model-output" folder
repo <- "reichlab/flu-metrocast"
path <- "model-output"

files <- gh("GET /repos/:owner/:repo/contents/:path",
            owner = "reichlab",
            repo = "flu-metrocast",
            path = "model-output")

# Extract only model names (folder names)
model_names <- map_chr(files, "name")

# remove readme.md 
model_names <- model_names[!grepl("README.md", model_names)]

read_forecast <- function(model, reference_date) {
  url <- paste0("https://raw.githubusercontent.com/reichlab/flu-metrocast/main/model-output/",
                model, "/", reference_date, "-", model, ".csv")
  
  # Try reading the file, if it fails, return NULL
  tryCatch({
    read_csv(url) %>% mutate(model_id = model)
  }, error = function(e) {
    message("File not found: ", url)
    return(NULL)  # Skip file if not found
  })
}



reference_date <- "2025-03-01"  # Example date, modify as needed

# Corrected function call with explicit reference_date
forecast_output <- map_dfr(model_names, ~read_forecast(.x, reference_date))



linear_pool_norm <- forecast_output |>
  hubEnsembles::linear_pool(model_id = "linear-pool-normal") |>
  select(-model_id)
write.csv(linear_pool_norm, paste("model-output/epiENGAGE-lop_norm/",reference_date, "-epiENGAGE-lop_norm.csv", sep = ""), row.names = FALSE)

mean_ens <- forecast_output |>
  hubEnsembles::simple_ensemble(
    model_id = "simple-ensemble-mean"
  )|>
  select(-model_id)

write.csv(mean_ens, paste("model-output/epiENGAGE-ensemble_mean/",reference_date, "-epiENGAGE-ensemble_mean.csv", sep = ""), row.names = FALSE)


