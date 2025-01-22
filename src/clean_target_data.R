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

    # Read existing oracle output data
    oracle_output <- read.csv("target-data/oracle-output.csv")
    oracle_output <- oracle_output %>%
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
    left_join(NYC_pop, by = "location")

  # Combine new weekly data with the existing time series
  if(as_of > "2025-01-03" ){
    new_time_series <- rbind(df_weekly, time_series)
  }else{
    new_time_series <- df_weekly
  }



  # Prepare the new oracle output data
  df_oracle <- df_weekly %>%
    select(-as_of_date) %>%
    mutate(target = "ILI ED visits") %>%
    rename(oracle_value = observation) %>%
    select(target_end_date, location, target, oracle_value, population)


  # Merge new and existing oracle output and keep the maximum oracle_value for duplicates
  if(as_of > "2025-01-03" ){
    new_oracle_output <- bind_rows(df_oracle, oracle_output) %>%
      group_by(target_end_date, location, target, population) %>%  # Group by overlapping columns
      filter(oracle_value == max(oracle_value)) %>%    # Keep rows with the max oracle_value
      ungroup()
  }else{
    new_oracle_output <- df_oracle
  }


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

df <- read.csv("target-data/oracle-output.csv")


df_weekly1 %>%
  #filter(target_end_date <= max(df_weekly$target_end_date)) %>%
  ggplot(aes(target_end_date, observation)) +
  geom_line() +
  facet_wrap(~location, scales = "free_y")

df_weekly %>%
  filter(target_end_date %in% unique(df_weekly1$target_end_date)) %>%
  ggplot(aes(target_end_date, observation)) +
  geom_line() +
  facet_wrap(~location, scales = "free_y")

df <- read.csv("target-data/oracle-output.csv")
df %>%
  filter(target_end_date >'2024-07-01') %>%
  ggplot(aes(as.Date(target_end_date), oracle_value)) +
  geom_line() +
  facet_wrap(~location, scales = "free_y")

