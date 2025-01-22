#So far, we haven’t found a direct link for downloading the data.
#You need to visit the website
#https://a816-health.nyc.gov/hdi/epiquery/visualizations?PageType=ps&PopulationSource=Syndromic
#and manually download the data with the following settings:
#syndrome = ILI,
#metric = count,
#aggregate_by = day,
#date_range = between 2024-09-29 and the most recent date.


library(dplyr)
library(ISOweek)
library(tidycensus)
library(here)


clean_data <- function(df_daily, as_of){
  # Read existing time-series data
  time_series <- read.csv("target-data/time-series.csv")
  time_series <- time_series %>%
    select(-X) %>%
    mutate(target_end_date = as.Date(target_end_date)) # Convert date column to Date type

  # Read existing oracle output data
  oracle_output <- read.csv("target-data/oracle-output.csv")
  oracle_output <- oracle_output %>%
    select(-X) %>%
    mutate(target_end_date = as.Date(target_end_date)) # Convert date column to Date type


  # Clean the newly downloaded data
  df <- df_daily %>%
    mutate(
      as_of_date = as_of,    # Add the 'as_of' date to track data version
      Date = as.Date(Date, format = "%m/%d/%y"),
      WeekStart = as.Date(cut(Date, breaks = "week", start.on.monday = FALSE)),  # Calculate the week start (Sunday)
      target_end_date = WeekStart + 6,   # Calculate the corresponding target end date (Saturday)
      #Week = week(WeekStart),
      #Year = year(WeekStart),
      X = as.numeric(gsub(",", "", X))
    ) %>%
    filter(Dim2Value == "All age groups",
           WeekStart >= '2024-09-29') %>%   ##
    select(-Ind1Name, -Dim1Name, -Dim2Name, -Select.Metric, -Dim2Value) %>%
    rename(
      location = Dim1Value,
      observation = X
    )


  # Aggregate the data to weekly summaries
  df_weekly <- df %>% group_by(as_of_date, location, WeekStart, target_end_date) %>%
    mutate(observation = as.numeric(observation)) %>%
    summarise(observation = sum(observation, na.rm = TRUE), .groups = "drop") %>%
    select(-WeekStart)

  # Combine new weekly data with the existing time series
  new_time_series <- rbind(df_weekly, time_series)


  # Prepare the new oracle output data
  df_oracle <- df_weekly %>%
    select(-as_of_date) %>%
    mutate(target = "ILI ED Visits") %>%
    rename(oracle_value = observation) %>%
    select(target_end_date, location, target, oracle_value)


  # Merge new and existing oracle output and keep the maximum oracle_value for duplicates
  new_oracle_output <- bind_rows(df_oracle, oracle_output) %>%
    group_by(target_end_date, location, target) %>%  # Group by overlapping columns
    filter(oracle_value == max(oracle_value)) %>%    # Keep rows with the max oracle_value
    ungroup()


  # Write the updated time-series data back to the file
  write.csv(new_time_series, "target-data/time-series.csv")
  # Write the updated oracle output data back to the file
  write.csv(new_oracle_output, "target-data/oracle-output.csv")

  return(new_oracle_output)
}


df_daily <- read.csv("raw-data/NYC_ED_daily_asof_01-03-2025.csv")
df1 <- clean_data(df_daily, as_of = as.Date("2025-01-03"))
df_daily1 <- read.csv("raw-data/NYC_ED_daily_asof_01-21-2025.csv")
df2 <- clean_data(df_daily1, as_of = as.Date("2025-01-21"))
