# Flu MetroCast Hub

The Flu MetroCast Hub is a modeling hub with the goal of collecting city- and county-level forecasts of influenza activity. The hub is led by the epiENGAGE team from UT-Austin and UMass-Amherst, as a part of the CDC Insight Net program. Anyone interested in using these data for additional research or publications is requested to contact [Dongah Kim](mailto:donga0223@gmail.com) for information regarding attribution of the source forecasts.

The Flu MetroCast Hub makes public forecasts for New York City (NYC) and is open to adding forecasts for other jurisdictions with near real-time public-facing data. For NYC, the influenza-related data are daily emergency department (ED) visits due to influenza-like illness (ILI), which includes ED chief complaint mention of flu, fever, and sore throat. Other data sources, where available, could be modeled as well, such as the percentage of outpatient visits with a primary complaint of ILI or count of all hospitalizations due to influenza.

## City- or county- level forecasts

**Dates:** The Challenge Period will begin on January 21, 2025 and will run until May 27, 2025. Participants are asked to submit forecasts by Tuesday evenings at 8pm ET (herein referred to as the Forecast Due Date). In the event that timelines of data availability change, Flu MetroCast may change the day of week that forecasts are due. In such an event, participants would be notified at least one week in advance. Weekly submissions will be specified in terms of the reference date, which is the Saturday following the Forecast Due Date. The reference date is the last day of the epidemiological week (EW), which runs from Sunday to Saturday, containing the Forecast Due Date. We will use the EW specification defined by the CDC. The reference date must also be included in the file name for any model submission.

**Prediction Targets:** Participating teams are asked to provide city- or county-level predictions for the target relevant to each jurisdiction.

| Target name | Jurisdictions |  Target description |
|------------------------|------------------------|------------------------|
| ILI ED visits | New York City (NYC), Bronx, Brooklyn, Queens, Manhattan, and Staten Island | Weekly number of emergency department visits due to influenza-like illness. |
| Flu ED visits pct | Austin, Houston, Dallas, El Paso, San Antonio | Weekly percentage of emergency department visits due to influenza. |


Teams can submit forecasts for any combination of location(s) and horizon(s).  
For NYC, teams can submit predictions of new ED visits due to ILI for the epidemiological week (EW) ending on the reference date (horizon = 0) as well as for horizons 1 through 4. 
For Texas cities, teams can submit predictions of the percentage of new ED visits due to influenza for horizons -1 to 4.

## Target Data
We will use the specification of EWs defined by the [CDC](https://wwwn.cdc.gov/nndss/document/MMWR_Week_overview.pdf), which run Sunday through Saturday. The target end date for a prediction is the Saturday that ends an EW of interest, and can be calculated using the expression: **target end date = reference date + horizon \* (7 days)**. 

There are standard software packages to convert from dates to epidemic weeks and vice versa (e.g. [MMWRweek](https://cran.r-project.org/web/packages/MMWRweek/) and [lubridate](https://lubridate.tidyverse.org/reference/week.html) for R and [pymmwr](https://pypi.org/project/pymmwr/) and [epiweeks](https://pypi.org/project/epiweeks/) for Python).

You can find the raw and target data in the [raw-data](https://github.com/reichlab/flu-metrocast/tree/main/raw-data) and [target-data](https://github.com/reichlab/flu-metrocast/tree/main/target-data) folders. Typically we update the data in this repository by noon Eastern Time every Tuesday. 


### NYC Data
The evaluation data for NYC forecasts will be the weekly aggregate of daily ED visits for each jurisdiction. We download the data from the [New York City Department of Health and Mental Hygiene’s EpiQuery - Syndromic Surveillance Data](https://nyc.gov/health/epiquery) every Monday and aggregate it by epidemiological week (EW). 

### Texas Data
The evaluation data for TX forecasts is based on the weekly percentage of total emergency department (ED) visits associated with influenza. The data is downloaded using the epidatr R package; detailed code can be found in the [src](https://github.com/reichlab/flu-metrocast/tree/main/src) folder. We focus on five regions: Austin, Dallas, Houston, El Paso, and San Antonio. Note that these region names do not refer solely to the named city—they also encompass several surrounding counties. Specifically:
- Austin: Bastrop, Burnet, Lee, Llano, Travis, Williamson
- Houston: Austin, Chambers, Fort Bend, Harris, Liberty, Montgomery, San Jacinto, Waller
- Dallas: Collin, Dallas, Ellis, Hopkins, Hunt, Kaufman, Rains, Rockwall
- El Paso: Culberson, El Paso, Hudspeth, Loving
- San Antonio: Atascosa, Bandera, Bexar, Frio, Gonzales, Guadalupe, Kendall, La Salle, McMullen, Medina, Wilson, Zavala

## Acknowledgments

This repository follows the guidelines and standards outlined by the [hubverse](https://hubverse.io/en/latest/), which provides a set of data formats and open source tools for modeling hubs.

New York City Department of Health and Mental Hygiene. EpiQuery - Syndromic Surveillance Data. Initial access on 2025-01-21, and weekly thereafter. https://nyc.gov/health/epiquery

If you have questions about this hub, please reach out to [Dongah Kim](mailto:donga0223@gmail.com).

