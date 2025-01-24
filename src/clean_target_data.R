#There is no direct link for downloading these data.
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


NYC_borough_pop <- get_decennial(
  geography = "county",
  variables = "P1_001N",  # Total population
  state = "NY",
  county = c("Bronx", "Kings", "New York", "Queens", "Richmond"),  # NYC counties
  year = 2020
)

NYC_pop <- NYC_borough_pop %>%
  mutate(
    location = case_when(
      NAME == "New York County, New York" ~ "Manhattan",
      NAME == "Richmond County, New York" ~ "Staten Island",
      NAME == "Bronx County, New York" ~ "Bronx",
      NAME == "Kings County, New York" ~ "Brooklyn",
      NAME == "Queens County, New York" ~ "Queens",
      TRUE ~ NA_character_  # Catch unexpected cases
    )
  ) %>%
  rename(population = value) %>%
  select(location, population)

# Add a new row for "Citywide"
NYC_pop <- NYC_pop %>%
  mutate(population = as.numeric(population)) %>%  # Ensure the population column is numeric
  bind_rows(
    tibble(
      location = "NYC",
      population = sum(as.numeric(NYC_pop$population), na.rm = TRUE)  # Sum all borough populations
    )
  )




clean_data <- function(df_daily, as_of){
  # Read existing time-series data
  if(as_of > "2025-01-03" ){
    time_series <- read.csv("target-data/time-series.csv")
    time_series <- time_series %>%
      select(-X) %>%
      mutate(target_end_date = as.Date(target_end_date)) # Convert date column to Date type
    }

  # Clean the newly downloaded data
  df <- df_daily %>%
    filter(Dim2Value == "All age groups",
           Dim1Value != "Unknown") %>%
    mutate(
      as_of_date = as_of,    # Add the 'as_of' date to track data version
      Date = as.Date(Date, format = "%m/%d/%y"),
      WeekStart = as.Date(cut(Date, breaks = "week", start.on.monday = FALSE)),  # Calculate the week start (Sunday)
      target_end_date = WeekStart + 6,   # Calculate the corresponding target end date (Saturday)
      location = ifelse(Dim1Value == "Citywide", "NYC", Dim1Value),
      #Week = week(WeekStart),
      #Year = year(WeekStart),
      X = as.numeric(gsub(",", "", X))
    ) %>%

    {if (as_of > "2025-01-03") filter(., WeekStart >= '2024-09-29') else .} %>%
    select(-Ind1Name, -Dim1Name, -Dim1Value, -Dim2Name, -Select.Metric, -Dim2Value, -Dim1Value, - Date) %>%
    rename(
      observation = X
    ) %>%
    select(as_of_date, WeekStart, target_end_date, location, observation)


  # Aggregate the data to weekly summaries
  df_weekly <- df %>% group_by(as_of_date, location, WeekStart, target_end_date) %>%
    mutate(observation = as.numeric(observation)) %>%
    summarise(observation = sum(observation, na.rm = TRUE), .groups = "drop") %>%
    select(-WeekStart) %>%
    left_join(NYC_pop, by = "location") %>%
    arrange(target_end_date)

  # Combine new weekly data with the existing time series
  if(as_of > "2025-01-03" ){
    new_time_series <- rbind(df_weekly, time_series)
  }else{
    new_time_series <- df_weekly
  }

  for_oracle <- new_time_series %>%
    group_by(location, target_end_date) %>%
    filter(as_of_date == max(as_of_date)) %>% # filtering with recent as_of_date
    ungroup()


  oracle_output <- for_oracle %>%
    select(-as_of_date) %>%
    mutate(target = "ILI ED visits") %>%
    rename(oracle_value = observation) %>%
    arrange(target_end_date) %>%
    select(target_end_date, location, target, oracle_value, population)

  # Write the updated time-series data back to the file
  write.csv(new_time_series, "target-data/time-series.csv")
  # Write the updated oracle output data back to the file
  write.csv(oracle_output, "target-data/oracle-output.csv")

  return(oracle_output)
}


df_daily <- read.csv("raw-data/NYC_ED_daily_asof_01-03-2025.csv")
df1 <- clean_data(df_daily, as_of = as.Date("2025-01-03"))
df_daily1 <- read.csv("raw-data/NYC_ED_daily_asof_01-21-2025.csv")
df2 <- clean_data(df_daily1, as_of = as.Date("2025-01-21"))
