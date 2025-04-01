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

NY_ili_ED_daily_to_weekly_ts <- function(df_daily, as_of = NULL){
  if(is.null(as_of)){
    as_of = as.Date(today())
  }else{
    as_of = as_of
  }

  # Clean the newly downloaded data
  df <- df_daily %>%
    filter(Dim2Value == "All age groups" #,
           #Dim1Value != "Unknown"
    ) %>%
    mutate(
      as_of = as_of,    # Add the 'as_of' date to track data version
      Date = as.Date(Date, format = "%m/%d/%y"),
      WeekStart = as.Date(cut(Date, breaks = "week", start.on.monday = FALSE)),  # Calculate the week start (Sunday)
      target_end_date = WeekStart + 6,   # Calculate the corresponding target end date (Saturday)
      location = ifelse(Dim1Value == "Citywide", "NYC", Dim1Value),
      #Week = week(WeekStart),
      #Year = year(WeekStart),
      target = "ILI ED visits",
      X = as.numeric(gsub(",", "", X))
    ) %>%

    {if (as_of > "2025-01-03") filter(., WeekStart >= '2024-09-29') else .} %>%
    select(-Ind1Name, -Dim1Name, -Dim1Value, -Dim2Name, -Select.Metric, -Dim2Value, -Dim1Value, - Date) %>%
    rename(
      observation = X
    ) %>%
    select(as_of, WeekStart, location, target, target_end_date, observation)


  # Aggregate the data to weekly summaries
  df_weekly <- df %>% group_by(as_of, location, WeekStart, target, target_end_date) %>%
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
    mutate(as_of = as_of,
           County = gsub(" County", "", county),
           target_end_date = as.Date(time_value) + 6,
           target = "Flu ED visits pct",
           observation = value) %>%
    mutate(location = case_when(
      County == "Bexar"  ~ "San Antonio",  # Example mapping
      County == "Dallas" ~ "Dallas",
      County == "El Paso" ~ "El Paso",
      County == "Harris"  ~ "Houston",
      County == "Travis"  ~ "Austin",
      TRUE ~ County
    )) %>%
    select(as_of, location, target, target_end_date, observation)

  return(nssp_ts)
}


add_previous_season <- function(df_weekly, as_of = NULL){
  if(is.null(as_of)){
    as_of = as.Date(today())
  }else{
    as_of = as_of
  }
  ts <- read.csv("target-data/time-series.csv")
  ts <- ts %>%
    mutate(as_of = as.Date(as_of),
           target_end_date = as.Date(target_end_date ))

  df_weekly <- df_weekly %>%
    bind_rows(ts %>%
                filter(target == "ILI ED visits") %>%
                filter(as_of == min(as_of)) %>%
                filter(target_end_date < "2024-10-05") %>%
                mutate(as_of = as.Date(today()))
    )

  print(dim(ts))
  new_ts <- ts %>%
    bind_rows(df_weekly) %>%
    mutate(as_of = as.character(as_of),
           target_end_date = as.character(target_end_date)) %>%
    arrange(as_of, target_end_date) %>%
    filter(target_end_date <= as_of)
  print(dim(new_ts))
  return(new_ts)
}



ts_to_oracle <- function(df_weekly, target, as_of){
  if(is.null(as_of)){
    as_of = as.Date(today())
  }else{
    as_of = as_of
  }
  for_oracle <- df_weekly %>%
    group_by(location, target_end_date) %>%
    filter(as_of == max(as_of)) %>% # filtering with recent as_of_date
    ungroup()

  oracle_output <- for_oracle %>%
    select(-as_of) %>%
    mutate(target = target) %>%
    rename(oracle_value = observation) %>%
    arrange(target_end_date) %>%
    filter(target_end_date <= as_of) %>%
    select(target_end_date, location, target, oracle_value)

  return(oracle_output)
}


create_csv_check <- function(as_of){
  parts <- unlist(strsplit(as_of, "-"))
  new_date_str <- paste(parts[2], parts[3], parts[1], sep="-")

  NYC_data <- read.csv(paste("raw-data/NYC_ED_daily_asof_", new_date_str, ".csv", sep = ""))
  NYC_weekly <- NY_ili_ED_daily_to_weekly_ts(df_daily = NYC_data, as_of = NULL)
  head(NYC_weekly)

  myfips <- fips_codes %>%
    filter(state == "TX",
           county %in% c("Travis County",
                         "Harris County",
                         "Dallas County",
                         "El Paso County",
                         "Bexar County")) %>%
    mutate(geo_value = paste(state_code, county_code, sep = ""))

  TX_weekly <- TX_nssp_flu_ED_pct_weekly_ts(myfips = myfips, as_of=NULL)
  head(TX_weekly)

  df_weekly <- rbind(NYC_weekly, TX_weekly)

  new_ts <- add_previous_season(df_weekly, as_of = NULL)

  ## check correctly added
  new_ts |>
    group_by(as_of, target, location) |>
    summarize(n=n()) |>
    View()

  new_oracle <- ts_to_oracle(df_weekly = new_ts, as_of = NULL)
  write.csv(new_ts, "target-data/time-series.csv", row.names = FALSE)
  write.csv(new_oracle, "target-data/oracle-output.csv", row.names = FALSE)

}

create_csv_check(as_of = as.character(today()))

aa <- read.csv("target-data/oracle-output.csv")
aa$target_end_date <- as.Date(aa$target_end_date)
write.csv(aa, "target-data/oracle-output.csv", row.names = FALSE)








