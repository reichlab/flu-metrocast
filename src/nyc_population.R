library(tidycensus)
library(dplyr)

# Get population data for NYC boroughs (ACS 1-year estimates)
# Source: U.S. Census Bureau, Population Estimates Program (Vintage 2023)

nyc_population <- get_acs(
  geography = "county",
  variables = "B01003_001", # Total population variable
  state = "NY",
  year = 2023, # Adjust the year as needed
  survey = "acs1"
) %>%
  filter(NAME %in% c("Bronx County, New York",
                     "Kings County, New York",
                     "New York County, New York",
                     "Queens County, New York",
                     "Richmond County, New York")) %>%
  mutate(Borough = case_when(
    NAME == "Bronx County, New York" ~ "Bronx",
    NAME == "Kings County, New York" ~ "Brooklyn",
    NAME == "New York County, New York" ~ "Manhattan",
    NAME == "Queens County, New York" ~ "Queens",
    NAME == "Richmond County, New York" ~ "Staten Island"
  )) %>%
  select(location = Borough, population = estimate)

# Add NYC population
nyc_population <- nyc_population %>%
  bind_rows(
    nyc_population %>%
      summarise(
        location = "NYC",
        population = sum(population, na.rm = TRUE) # Sum of all boroughs
      )
  )
# View the population data
print(nyc_population)
write.csv(nyc_population, "auxiliary-data/nyc_population.csv", row.names = FALSE)
