script_dir <- "src"  
source(file.path(script_dir, "quantile_baseline.R"))

#source("estimation.R")
#source("transform.R")
#source("prediction.R")

library(dplyr)
library(purrr)
library(lubridate)
library(readr)

# Define function to fit and predict using the baseline model
fit_and_forecast_baseline <- function(data, quantiles, horizon, num_samples) {
  # Ensure data is sorted by date
  data <- data %>% arrange(target_end_date)
  
  # Extract incidence data
  incidence <- data$observation
  
  # Fit the baseline model
  baseline_model <- fit_quantile_baseline(incidence, symmetrize = TRUE)
  
  # Generate forecasts
  forecast_results <- predict.quantile_baseline(
    quantile_baseline = baseline_model,
    inc_data = incidence,
    cum_data = cumsum(incidence),  # Simulated cumulative data
    quantiles = quantiles,
    horizon = horizon,
    num_samples = num_samples
  )
  
  # Add location information back
  forecast_results <- forecast_results %>%
    mutate(location = unique(data$location),
           target = unique(data$target))
  
  return(forecast_results)
}


# Set parameters for forecasting
quantiles <- c(0.025, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.975)  # Prediction intervals
horizon <- 4  # Forecast 7 days ahead
num_samples <- 1000  # Number of Monte Carlo samples

forecast_date <- Sys.Date()
reference_date = forecast_date + (6 - as.integer(format(forecast_date, "%u"))) %% 7
reference_date

c1 <- read.csv("target-data/latest-data.csv") %>%
  filter(target_end_date <= forecast_date)


# Apply the function to each location and combine results
forecast_output <- c1 %>%
  group_split(location) %>%  # Split data by location
  map_dfr(~fit_and_forecast_baseline(.x, quantiles, horizon, num_samples))  # Apply function and merge results


forecast_output1 <- forecast_output %>%
  filter(type == "inc", location != "Unknown") %>%
  mutate(reference_date = reference_date, 
         horizon = horizon - 1,  # Conditional horizon update
         output_type = "quantile") %>%
  rename(output_type_id = quantile) %>%
  mutate(target_end_date = reference_date + 7*horizon) %>%
  select(reference_date, location, horizon, target, target_end_date, output_type, output_type_id, value)
# View the first few rows
head(forecast_output1)

write.csv(forecast_output1, paste("model-output/epiENGAGE-baseline/", reference_date, "-epiENGAGE-baseline.csv", sep=""), 
          row.names = FALSE)
 
          