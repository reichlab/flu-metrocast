

library(dplyr)
library(ISOweek)
library(tidycensus)
library(here)

library(epidatr)
library(tidyr)

NYC_ts <- read.csv("target-data/time-series-ili-ed-visits.csv")

## format change
NYC_ts_tmp <- NYC_ts %>%
  rename(as_of = as_of_date) %>%
  mutate(target = "ILI ED visits") %>%
  select(as_of, location, target, target_end_date, observation)


new_ts <- function(df){
  as_of_list <- df %>%
    select(as_of) %>%
    distinct()
  for(i in 1:length(as_of_list$as_of)){
    assign(paste0("df-", as_of_list$as_of[i]), df %>% filter(as_of == as_of_list$as_of[i]))
  }
  for(i in 1:length(as_of_list$as_of)){
    print(as_of_list$as_of[i])
    if(as_of_list$as_of[i] == min(as_of_list$as_of)){
      assign(paste0("df-new-", as_of_list$as_of[i]), get(paste0("df-", as_of_list$as_of[i])))
    }else{
      assign(paste0("df-new-", as_of_list$as_of[i]), 
             `df-2025-01-03` %>%
               filter(target_end_date < '2024-10-05') %>%
               mutate(as_of = as_of_list$as_of[i]) %>%
               bind_rows(get(paste0("df-", as_of_list$as_of[i]))))
    }
  }
  
  
  all_ts <- get(paste0("df-new-", as_of_list$as_of[1]))
  for(i in 2:length(as_of_list$as_of)){
    all_ts <- all_ts %>%
      bind_rows(get(paste0("df-new-", as_of_list$as_of[i])))
  }
  return(all_ts)
  
}

NYC_ts_new <- new_ts(NYC_ts_tmp)
 

TX_ts <- read.csv("target-data/time-series-flu-ed-visits-pct.csv")
TX_ts_tmp <- TX_ts %>%
  rename(as_of = as_of_date) %>%
  mutate(target = "Flu ED visits pct") %>%
  select(as_of, location, target, target_end_date, observation)

TX_ts_new <- new_ts(TX_ts_tmp)

combine_ts <- NYC_ts_new %>%
  bind_rows(TX_ts_new) %>%
  arrange(as_of, target_end_date)
write.csv(combine_ts, "target-data/time-series.csv", row.names = FALSE)




ts_to_oracle <- function(df_ts, as_of){
  target_list <- unique(df_ts$target)
  for(i in 1:length(target_list)){
    assign(paste0("target-", i),
           df_ts %>% 
             filter(target == target_list[i]) %>%
             group_by(location, target, target_end_date) %>%
             filter(as_of == max(as_of)) %>% # filtering with recent as_of_date
             ungroup()
    )
  }
  for_oracle <- `target-1` %>%
    bind_rows(`target-2`)
    
  oracle_output <- for_oracle %>%
    select(-as_of) %>%
    rename(oracle_value = observation) %>%
    arrange(target_end_date) %>%
    filter(target_end_date <= as_of) %>%
    select(target_end_date, location, target, oracle_value)
  
  return(oracle_output)
}
 
new_oracle <- ts_to_oracle(combine_ts, max(combine_ts$as_of)) 
dim(new_oracle)


ts_to_oracle <- function(df_weekly, as_of){
  for_oracle <- df_weekly %>%
    group_by(location, target, target_end_date) %>%
    filter(as_of == max(as_of)) %>% # filtering with recent as_of_date
    ungroup() %>%
    distinct(location, target, target_end_date, .keep_all = TRUE)  
  
  oracle_output <- for_oracle %>%
    select(-as_of) %>%
    rename(oracle_value = observation) %>%
    arrange(target_end_date) %>%
    filter(target_end_date <= as_of) %>%
    select(target_end_date, location, target, oracle_value)
  
  return(oracle_output)
}

new_oracle <- ts_to_oracle(combine_ts, max(combine_ts$as_of)) 
dim(new_oracle)


new_oracle %>% filter(target_end_date == "2023-02-18")

write.csv(new_oracle, "target-data/new_oracle.csv", row.names = FALSE)

