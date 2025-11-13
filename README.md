# Flu MetroCast Hub 2025-2026 Guidelines
Run by [epiENGAGE](https://epiengage.org/)––an [Insight Net](https://www.cdc.gov/insight-net/php/about/index.html) Center for Implementation within the U.S. Centers for Disease Control and Prevention (CDC)’s Center for Forecasting and Outbreak Analytics (CFA)


*Table of Contents*

-   [Executive Summary](##Executive-Summary)
-   [Dates](###Dates)
-   [Prediction Targets](##Prediction-Targets)
-   [Model Output Data Storage](#Forecast-file-format)
-   [Target Data](##Target Data)
-   [Forecast Formatting](##Forecast Formatting)
-   [Forecast submission and Validation](##Forecast Submission and Validation)
-   [Evaluation Criteria](##Evaluation Criteria)
-   [Publication of Forecasts](##Publication of Forecasts)

## Executive Summary

The Flu MetroCast Hub is a collaborative modeling project that collects and shares weekly probabilistic forecasts of influenza activity at the metropolitan level in the United States. This modeling hub is led by the [epiENGAGE team](https://epiengage.org/) at the University of Texas at Austin and the University of Massachusetts Amherst.

Accurate predictions of key public health surveillance indicators––such as the percentage of emergency department (ED) visits due to influenza or influenza-like illness (ILI)––can shed light on seasonal trends, disease severity, and healthcare system strain. While many U.S. infectious disease forecasting hubs provide state- or national-level forecasts, the Flu MetroCast Hub fills an important gap by aggregating and evaluating forecasts at the sub-state level. 

Metro-level forecasting provides several key benefits:
* Reveals local patterns that state-level forecasts can miss, leading to more accurate and timely decisions.
* Builds modeling capacity and data infrastructure that strengthen readiness for future outbreak.
* Generates insights that are accessible and actionable for public health officials, healthcare systems, and community leaders.

From **November 19, 2025 through May 20, 2026**, participating modeling teams will submit **weekly quantile forecasts of the percentage of ED visits due to influenza (or ILI for NYC) for forecast horizons ranging from -1 to +3 weeks**. For the 2025-2026 season, all forecasts––except those for NYC––will use publicly-available data from the [CDC’s National Syndromic Surveillance Program (NSSP)](https://data.cdc.gov/Public-Health-Surveillance/NSSP-Emergency-Department-Visit-Trajectories-by-St/rdmq-nq56/about_data). These data provide weekly estimates of the percentage of influenza-related ED visits at the level of Health Service Areas (HSAs), which are single- or multi-county clusters reflecting local healthcare catchments that often align with metropolitan areas. Forecasts for NYC will use data from the [New York City Department of Health and Mental Hygiene’s EpiQuery - Syndromic Surveillance Data](https://a816-health.nyc.gov/hdi/epiquery/).  

All forecasts and observed target data will be publicly available in the Flu MetroCast GitHub repository, following Hubverse standards. Model submissions will be validated for compliance with these standards and incorporated into an ensemble forecast. Both ensemble and individual model outputs will be displayed on a [public-facing interactive dashboard](https://reichlab.io/metrocast-dashboard/). Forecasts will be evaluated in real time using metrics such as the weighted interval score (WIS), and results will be publicly reported. A pre-registered evaluation will be conducted at the end of the season.

The following guidelines provide detailed instructions for participating teams on submission deadlines, forecast targets, data sources, and standardized formatting, submission, and validation procedures. 

Anyone interested in using these data for additional research or publications should contact us at [epiengage@austin.utexas.edu](epiengage@austin.utexas.edu) for information on proper attribution of the source forecasts.

## Metro-level Forecasts of Influenza During the 2025-2026 Season
### Dates
The initial Flu MetroCast Hub submission will be due on **Wednesday, November 19, 2025**, with subsequent weekly submissions until May 20, 2026. 

> Contingency note: During the U.S. government shutdown in October and November 2025, NSSP data releases were paused. If the shutdown remains in effect on November 19th, the Hub will collect only NYC forecasts on this date. Forecasts using NSSP data will commence on the first Wednesday after NSSP data are publicly released.

Participating teams must submit weekly forecasts **by 8 PM Eastern Time each Wednesday (the Forecast Due Date)** for inclusion in the ensemble model. This deadline aligns with the early Wednesday release of NSSP data on the percentage of ED visits. Any changes to the Forecast Due Date (e.g., due to holidays) will be communicated promptly by the MetroCast organizing team.

Each weekly submission file must include the `reference date`––defined as the **Saturday following the Forecast Due Date**––in its filename, following the format: YYYY-MM-DD-team-model.csv, where YYYY-MM-DD indicates the reference date. 

### Prediction Targets
From November through May, participating teams will submit weekly probabilistic (quantile) forecasts of the percentage of ED visits due to influenza. 

The Hub will primarily collect forecasts at the city-, county-, or metro-level (typically corresponding to HSAs) and, for validation, will also collect predictions for the corresponding state-level forecasts. 

#### Jurisdictions Using NSSP HSA-Level Data
At launch, this group includes all locations except New York City. For these jurisdictions, teams should submit:
* Weekly quantile forecasts of the percentage of ED visits due to influenza at the HSA level (referred to by a representative city or county name), and
* Weekly quantile forecasts of the percentage of ED visits due to influenza at the state level.
  
A full list of local and state jurisdictions to be forecasted can be found in the [locations.csv file in the Hub repository](/auxiliary-data/locations.csv). We expect that additional jurisdictions may be added to this list based on data availability and interest as the season progresses. 
Forecasts should cover horizons –1 to +3 weeks, defined as follows:
* Horizon = -1: the previous epidemiological week (Sunday-Saturday) before the Forecast Due Date. 
* Horizon = 0: the current epidemiological week encompassing the Sunday prior to the Forecast Due Date through the upcoming Saturday. 

For more information on forecast horizons, see the horizon subsection.

**Target name, horizon, and aggregate jurisdiction for NSSP HSA-level forecasts.** The target refers to the percentage of ED visits in a given week due to influenza.

| Target name       | Horizon       | Aggregate jurisdiction                                                                                                  |
|--------------------|---------------|--------------------------------------------------------------------------------------------------------------------------|
| Flu ED visits pct  | -1 to +3 weeks | Corresponding state –– Colorado, Georgia, Indiana, Maine, Maryland, Massachusetts, Minnesota, South Carolina, Texas, Utah, Virginia |

#### New York City (NYC) Forecasts
For New York City, the Hub will collect:
* Weekly quantile forecasts of the percentage of ED visits due to influenza-like illness at the borough level (Bronx, Brooklyn, Queens, Manhattan, Staten Island), and
* Weekly quantile forecasts of the percentage of ED visits due to influenza-like illness at the citywide (NYC) level.

Forecasts for NYC should also cover horizons -1 to +3 weeks. 

**Target name, horizon, and aggregate jurisdiction for NYC forecasts.** The target refers to the percentage of ED visits in a given week due to influenza-like illness.

| Target name       | Horizon       | Aggregate jurisdiction |
|--------------------|---------------|-------------------------|
| ILI ED visits pct  | -1 to +3 weeks | New York City           |

### Model Output Data Storage
The Flu MetroCast Hub will store a live dataset in this dedicated GitHub repository, following [Hubverse file-based data storage standards](https://docs.hubverse.io/en/latest/user-guide/hub-structure.html). The repository will contain separate directories for model output and model metadata submissions from modeling teams.

Model output must follow a tabular representation where each row represents a single prediction and each column provides additional information about the prediction (see the Forecast File Format section). Model output may be submitted as CSV or Parquet files. 

## Target Data

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

