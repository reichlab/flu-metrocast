library(readr)
library(dplyr)
library(epidatr)
library(lubridate)


## covert nyc data daily to weekly

NY_ili_ED_daily_to_weekly_ts <- function(df_daily, as_of = NULL){
  if(is.null(as_of)){
    as_of = Sys.Date()
  }else{
    as_of = as_of
  }
  
  # Clean the newly downloaded data
  df <- df_daily %>%
    filter(Dim2Value == "All age groups", #,
           Dim1Value == "Citywide"
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
      target = "ILI ED visits pct",
      X = as.numeric(gsub(",", "", X))
    ) %>%
    select(-Ind1Name, -Dim1Name, -Dim1Value, -Dim2Name, -Select.Metric, -Dim2Value, -Dim1Value, - Date) %>%
    rename(
      observation = X
    ) %>%
    select(as_of, WeekStart, location, target, target_end_date, observation)
  
  # Aggregate the data to weekly summaries
  df_weekly <- df %>% group_by(as_of, location, WeekStart, target, target_end_date) %>%
    mutate(observation = as.numeric(observation)) %>%
    summarise(observation = mean(observation, na.rm = TRUE), .groups = "drop") %>%
    select(-WeekStart) %>%
    arrange(target_end_date) %>%
    mutate(location = tolower(gsub(" ", "-", location)),
           observation = observation*100) 
  
  return(df_weekly)
}


as_of = Sys.Date()
new_date_str <- format(Sys.Date(), "%m-%d-%Y")

raw_nyc_df <- read.csv(paste("raw-data/NYC_pct_ED_daily_asof_", new_date_str, ".csv", sep = ""))


weekly_nyc <- NY_ili_ED_daily_to_weekly_ts(raw_nyc_df)


NYC_data <- weekly_nyc %>%
  mutate(observation = round(observation, 2)) %>%
  filter(target_end_date <= today(),
         target_end_date >= '2024-08-01')


##########################################
##########################################
## NSSP data
##########################################
##########################################

epidatr::disable_cache()
NSSP_hsa <- pub_covidcast(
  source = "beta_nssp_github",
  signals = "pct_ed_visits_influenza",
  geo_type = "hsa_nci",
  time_type = "week",              
)
max(NSSP_hsa$time_value)


NSSP_state <- pub_covidcast(
  source = "beta_nssp_github",
  signals = "pct_ed_visits_influenza",
  geo_type = "state",
  time_type = "week",              
)
max(NSSP_state$time_value)


locations <- read_csv("auxiliary-data/locations.csv")
hsa_list <- locations %>%
  filter(location_type == "hsa_nci_id", 
         location != 'nyc',
         original_location_code != 'All')

state_list <- locations %>%
  filter(original_location_code == "All",
         location != 'north-carolina') %>%
  mutate(state_abb2 = tolower(state_abb))

NSSP_hsa_df <- NSSP_hsa %>% 
  filter(geo_value %in% hsa_list$original_location_code) %>%
  left_join(hsa_list %>%
              select(location, original_location_code, population), 
            by = c("geo_value" = "original_location_code")) %>%
  mutate(as_of = Sys.Date(),
         target = "Flu ED visits pct",
         target_end_date = time_value + 6) %>%
  select(as_of, location, target, target_end_date, observation = value)


NSSP_state_df <- NSSP_state %>% 
  filter(geo_value %in% state_list$state_abb2) %>%
  left_join(state_list %>%
              select(location, state_abb2, population), 
            by = c("geo_value" = "state_abb2")) %>%
  mutate(as_of = Sys.Date(),
         target = "Flu ED visits pct",
         target_end_date = time_value + 6) %>%
  select(as_of, location, target, target_end_date, observation = value)


nssp1 <- rbind(NSSP_hsa_df, NSSP_state_df) 
nssp <- nssp1 %>%
  mutate(observation = round(observation,2)) 

##########################################
##########################################
## time_series
##########################################
##########################################

time_series <- read_csv("target-data/time-series.csv")

time_series %>% filter(location == "athens") %>%group_by(location, as_of) |> summarize(tot_rows = n())

NY_ts <- NYC_data %>%
  filter(target_end_date >= '2024-08-01') %>%
  distinct()

NSSP_ts <- nssp %>%
  filter(target_end_date >= '2024-08-01') %>%
  distinct()

today_time_series <-  rbind(NY_ts, NSSP_ts) 
new_time_series <- rbind(time_series, today_time_series)

write.csv(new_time_series, "target-data/time-series.csv", row.names = FALSE)


##########################################
##########################################
#### latest-data
##########################################
##########################################

latest_data <- read_csv("target-data/latest-data.csv")

new_latest_data  <- NYC_data %>%
  filter(target_end_date >= '2024-08-01') %>%
  select(target_end_date, location, target, observation) %>%
  distinct()  %>%
  rbind(nssp %>%
          filter(target_end_date >= '2024-08-01') %>%
          select(target_end_date, location, target, observation) %>%
          distinct())



updated_latest_data <- latest_data %>%
  rows_upsert(new_latest_data,
              by = c("target_end_date", "location", "target"))


write.csv(updated_latest_data, "target-data/latest-data.csv", row.names = FALSE)


##########################################
##########################################
#### oracle-data
##########################################
##########################################

target_end_date_list <- c("2025-11-22", "2025-11-29", "2025-12-06", "2025-12-13",
                          "2025-12-20", "2025-12-27", "2026-01-03", "2026-01-10",
                          "2026-01-17", "2026-01-24", "2026-01-31", "2026-02-07",
                          "2026-02-14", "2026-02-21", "2026-02-28", "2026-03-07",
                          "2026-03-14", "2026-03-21", "2026-03-28", "2026-04-04",
                          "2026-04-11", "2026-04-18", "2026-04-25", "2026-05-02",
                          "2026-05-09", "2026-05-16", "2026-05-23", "2026-05-30")

oracle_output <- read_csv("target-data/oracle-output.csv")

oracle_output1 <- updated_latest_data %>%
  rename(oracle_value = observation) %>%
  filter(target_end_date %in% target_end_date_list)

new_oracle_output  <- oracle_output  %>%
  rows_upsert(oracle_output1 ,
              by = c("target_end_date", "location", "target"))

write.csv(new_oracle_output, "target-data/oracle-output.csv", row.names = FALSE)

