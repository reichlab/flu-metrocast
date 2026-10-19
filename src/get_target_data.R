library(readr)
library(dplyr)
library(epidatr)
library(lubridate)
library(tidycensus)
library(readxl)
library(stringr)

as_of <- Sys.Date() + (4 - wday(Sys.Date(), week_start = 7))

##########################################
##########################################
## NSSP data
##########################################
##########################################

NSSP_hsa <- epidata_snapshot(
  source = "nssp",
  signals = "pct_ed_visits_influenza",
  geo_type = "hsa_nci"
)

NSSP_state <- epidata_snapshot(
  source = "nssp",
  signals = "pct_ed_visits_influenza",
  geo_type = "state"
)

locations <- read_csv("auxiliary-data/locations.csv")
hsa_list <- locations %>%
  filter(location_type == "hsa_nci_id",
         location != 'nyc',
         original_location_code != 'All')

state_list <- locations %>%
  filter(original_location_code == "All",
         !location  %in% c('north-carolina', 'california', 'utah')) %>%
  mutate(state_abb2 = tolower(state_abb))

NSSP_hsa_df <- NSSP_hsa %>%
  filter(geo_value %in% hsa_list$original_location_code) %>%
  left_join(hsa_list %>%
              dplyr::select(location, original_location_code, population),
            by = c("geo_value" = "original_location_code")) %>%
  mutate(as_of = Sys.Date(),
         target = "Flu ED visits pct")%>%
  rename(target_end_date = reference_time) %>%
  dplyr::select(as_of, location, target, target_end_date, observation = value)


NSSP_state_df <- NSSP_state %>%
  filter(geo_value %in% state_list$state_abb2) %>%
  left_join(state_list %>%
              dplyr::select(location, state_abb2, population),
            by = c("geo_value" = "state_abb2")) %>%
  mutate(as_of = Sys.Date(),
         target = "Flu ED visits pct") %>%
  rename(target_end_date = reference_time) %>%
  dplyr::select(as_of, location, target, target_end_date, observation = value)


nssp1 <- rbind(NSSP_hsa_df, NSSP_state_df)
nssp <- nssp1 %>%
  mutate(observation = round(observation,2))


nyc_historic_flu <- read.csv(
  "https://raw.githubusercontent.com/nychealth/respiratory-illness-data/main/data/archive/historical_ED_data.csv"
) %>%
  filter(metric == "Influenza visits") %>%
  mutate(as_of = Sys.Date(),
         location = ifelse(submetric == "Overall", "nyc", submetric),
         target = "Flu ED visits pct",
         target_end_date = as.Date(date)) %>%
  rename(observation = value) %>%
  dplyr::select(as_of, location, target, target_end_date, observation)


nyc_recent_flu <- read.csv(
  "https://raw.githubusercontent.com/nychealth/respiratory-illness-data/main/data/ED_data_influenza.csv"
) %>%
  dplyr::select(date, Influenza.visits.overall) %>%
  mutate(as_of = Sys.Date(),
         location = "nyc",
         target = "Flu ED visits pct",
         target_end_date = as.Date(date)) %>%
  rename(observation = Influenza.visits.overall) %>%
  dplyr::select(as_of, location, target, target_end_date, observation)

nyc_flu <- nyc_historic_flu %>%
  rows_upsert(nyc_recent_flu,
              by = c("as_of", "target_end_date", "location", "target")) %>%
  mutate(observation = round(observation, 2))



##########################################
##########################################
## time_series
##########################################
##########################################

time_series <- read_csv("target-data/time-series.csv")

NY_ts <- nyc_flu %>%
  distinct()

NSSP_ts <- nssp %>%
  distinct()

today_time_series <- rbind(NY_ts, NSSP_ts)

new_time_series <- time_series %>%
  rows_upsert(
    today_time_series,
    by = c("as_of", "target_end_date", "location", "target")
  )

write.csv(new_time_series, "target-data/time-series.csv", row.names = FALSE)

##########################################
##########################################
#### latest-data
##########################################
##########################################

latest_data <- read_csv("target-data/latest-data.csv")

new_latest_data <- today_time_series %>%
  select(target_end_date, location, target, observation)

updated_latest_data <- latest_data %>%
  filter(location %in% locations$location) %>%
  rows_upsert(
    new_latest_data,
    by = c("target_end_date", "location", "target")
  )


write.csv(updated_latest_data, "target-data/latest-data.csv", row.names = FALSE)


##########################################
##########################################
#### oracle-data
##########################################
##########################################

target_end_date_list <- c(c("2026-10-24", "2026-10-31",
                            "2026-11-07", "2026-11-14", "2026-11-21", "2026-11-28",
                            "2026-12-05", "2026-12-12", "2026-12-19", "2026-12-26",
                            "2027-01-02", "2027-01-09", "2027-01-16", "2027-01-23",
                            "2027-01-30", "2027-02-06", "2027-02-13", "2027-02-20",
                            "2027-02-27", "2027-03-06", "2027-03-13", "2027-03-20",
                            "2027-03-27", "2027-04-03", "2027-04-10", "2027-04-17",
                            "2027-04-24", "2027-05-01", "2027-05-08", "2027-05-15",
                            "2027-05-22", "2027-05-29", "2027-06-05", "2027-06-12"))

oracle_output <- read_csv("target-data/oracle-output.csv")

oracle_output1 <- updated_latest_data %>%
  rename(oracle_value = observation) %>%
  filter(target_end_date %in% target_end_date_list)

new_oracle_output  <- oracle_output  %>%
  rows_upsert(oracle_output1 ,
              by = c("target_end_date", "location", "target"))

write.csv(new_oracle_output, "target-data/oracle-output.csv", row.names = FALSE)

