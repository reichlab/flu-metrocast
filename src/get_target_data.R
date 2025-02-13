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

library(epidatr)
library(tidyr)

NY_ili_ED_daily_to_weekly_ts <- function(df_daily, as_of){
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
    arrange(target_end_date)
  
  return(df_weekly)
}

TX_nssp_flu_ED_pct_weekly_ts <- function(myfips, as_of=NULL){
  nssp <- pub_covidcast(
    source = "nssp",
    signals = "pct_ed_visits_influenza",
    geo_type = "county",
    time_type = "week",
    geo_values = myfips$geo_value,
    as_of = NULL
  ) %>%
    select(geo_value, signal, time_value, value) %>%
    left_join(myfips, by = "geo_value") %>%
    select(-state, -state_code, -state_name, -county_code) 
  
  if(is.null(as_of)){
    as_of = as.Date(today())
  }else{
    as_of = as_of
  }
  nssp_ts <- nssp %>%
    mutate(as_of_date = as_of,
           County = gsub(" County", "", county),
           target_end_date = as.Date(time_value) + 6,
           observation = value) %>%
    mutate(location = case_when(
      County == "Bexar"  ~ "San Antonio",  # Example mapping
      County == "Dallas" ~ "Dallas",
      County == "El Paso" ~ "El Paso",
      County == "Harris"  ~ "Houston",
      County == "Travis"  ~ "Austin",
      TRUE ~ County
    )) %>%
    select(as_of_date, location, target_end_date, observation)
  
  return(nssp_ts)
}

ts_to_oracle <- function(df_weekly, target, as_of){
  for_oracle <- df_weekly %>%
    group_by(location, target_end_date) %>%
    filter(as_of_date == max(as_of_date)) %>% # filtering with recent as_of_date
    ungroup()
  
  oracle_output <- for_oracle %>%
    select(-as_of_date) %>%
    mutate(target = target) %>%
    rename(oracle_value = observation) %>%
    arrange(target_end_date) %>%
    filter(target_end_date <= as_of) %>%
    select(target_end_date, location, target, oracle_value)
  
  return(oracle_output)
}


create_initial_oracle_and_ts <- function(df_daily){
  as_of = as.Date('2025-01-03')
  df_weekly <- NY_ili_ED_daily_to_weekly_ts(df_daily, as_of = as_of)
  oracle_output <- ts_to_oracle(df_weekly, target = "ILI ED visits", as_of = as_of)
  # Write the updated time-series data back to the file
  write.csv(df_weekly, "target-data/time-series-ili-ed-visits.csv", row.names = FALSE)
  # Write the updated oracle output data back to the file
  write.csv(oracle_output, "target-data/oracle-output.csv", row.names = FALSE)
}


create_weekly_updated_oracle_and_ts <- function(df_daily, as_of){
  # Read existing time-series data
  time_series <- read.csv("target-data/time-series-ili-ed-visits.csv")
  time_series <- time_series %>%
    mutate(target_end_date = as.Date(target_end_date)) # Convert date column to Date type
  
  df_weekly <- NY_ili_ED_daily_to_weekly_ts(df_daily, as_of = as_of)
  
  new_time_series <- rbind(df_weekly, time_series)
  oracle_output <- ts_to_oracle(new_time_series, target = "ILI ED visits", as_of = as_of)
  
  # Write the updated time-series data back to the file
  write.csv(new_time_series, "target-data/time-series-ili-ed-visits.csv", row.names = FALSE)
  # Write the updated oracle output data back to the file
  write.csv(oracle_output, "target-data/oracle-output.csv", row.names = FALSE)
  
}

create_oracle_and_ts_add_flu <- function(as_of){
  # Read existing time-series data
  time_series_ili <- read.csv("target-data/time-series-ili-ed-visits.csv")
  time_series_ili <- time_series_ili %>%
    mutate(target_end_date = as.Date(target_end_date),
           target = "ILI ED visits") # Convert date column to Date type
  
  time_series_flu <- read.csv("target-data/time-series-flu-ed-visits-pct.csv")
  time_series_flu <- time_series_flu %>%
    mutate(target_end_date = as.Date(target_end_date),
           target = "Flu ED visits pct") # Convert date column to Date type
  
  
  new_time_series <- rbind(time_series_ili, time_series_flu)
  
  for_oracle <- new_time_series %>%
    group_by(location, target_end_date, target) %>%
    filter(as_of_date == max(as_of_date)) %>% # filtering with recent as_of_date
    ungroup()
  
  oracle_output <- for_oracle %>%
    select(-as_of_date) %>%
    rename(oracle_value = observation) %>%
    arrange(target_end_date, target) %>%
    filter(target_end_date <= as_of) %>%
    select(target_end_date, location, target, oracle_value)
  
  # Write the updated oracle output data back to the file
  write.csv(oracle_output, "target-data/oracle-output.csv", row.names = FALSE)
}



read_write <- function(as_of){
  parts <- unlist(strsplit(as_of, "-"))  
  new_date_str <- paste(parts[2], parts[3], parts[1], sep="-")  

  df_daily <- read.csv(paste("raw-data/NYC_ED_daily_asof_", new_date_str, ".csv", sep = ""))
  if(as_of == as.Date("2025-01-03")){
    create_initial_oracle_and_ts(df_daily)
  }else if(as_of > as.Date("2025-01-03")){
    create_weekly_updated_oracle_and_ts(df_daily, as_of = as_of)
  }
}

## The `create_initial_oracle_ts` function is for one-time use only.
## It retrieves data from 2016 through January 3, 2025.

read_write("2025-01-03")

## For weekly updates, please use the `create_weekly_updated_oracle_ts` function.
## It appends new data to the time-series.csv file for dates ranging from '2024-09-29' to the most recent date.
## The oracle data is updated with the most recent value, ensuring each date and location has only one entry.

read_write("2025-01-21")
read_write("2025-01-30")
read_write("2025-02-03")
read_write("2025-02-11")


## As of now (2/12/2025), we have an additional data source.
## We created the initial time-series data for this additional data source

library(tidycensus)
data(fips_codes)

myfips <- fips_codes %>%
  filter(state == "TX",
         county %in% c("Travis County", 
                       "Harris County", 
                       "Dallas County", 
                       "El Paso County", 
                       "Bexar County")) %>%
  mutate(geo_value = paste(state_code, county_code, sep = ""))


flu_ED_pct_ts <- TX_nssp_flu_ED_pct_weekly_ts(myfips = myfips, as_of = "2025-02-12")
write.csv(flu_ED_pct_ts, "target-data/time-series-flu-ed-visits-pct.csv", row.names = FALSE)




create_oracle_and_ts_add_flu(as_of = "2025-02-12")

#as.Date(today())