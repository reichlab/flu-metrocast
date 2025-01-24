# Flu MetroCast Hub

The Flu MetroCast Hub is a modeling hub with the goal of collecting city- and county-level forecasts of influenza activity. The hub is led by the epiENGAGE team from UT-Austin and UMass-Amherst, as a part of the CDC Insight Net program. Anyone interested in using these data for additional research or publications is requested to contact [Dongah Kim](mailto:donga0223@gmail.com) for information regarding attribution of the source forecasts.

The Flu MetroCast Hub makes public forecasts for New York City (NYC) and is open to adding forecasts for other jurisdictions with near real-time public-facing data. For New York City, the influenza-related data are daily Emergency Department (ED) visits due to influenza-like illness (ILI), which includes ED chief complaint mention of flu, fever, and sore throat. Other data sources, where available, could be modeled as well, such as the percentage of outpatient visits with a primary complaint of ILI or count of all hospitalizations due to influenza.

## City and county level forecasts

**Dates:** The Challenge Period will begin on January 22, 2025 and will run until May 2025. Participants are asked to submit forecasts by Wednesday evenings at 8pm ET (herein referred to as the Forecast Due Date). In the event that timelines of data availability change, Flu MetroCast may change the day of week that forecasts are due. In such an event, participants would be notified at least one week in advance. Weekly submissions will be specified in terms of the reference date, which is the Saturday following the Forecast Due Date. The reference date is the last day of the epidemiological week (EW) (Sunday to Saturday) containing the Forecast Due Date. The reference date must be included in the file name for any model submission.

**Prediction Targets:** Participating teams are asked to provide city- or county-level predictions for the target relevant to each jurisdiction.

| Jurisdiction | Target name | Target description |
|------------------------|------------------------|------------------------|
| New York City (NYC) | ILI ED visits | Weekly number of Emergency Department visits due to influenza-like illness |

For NYC, teams will submit predictions of new ED visits due to ILI for the epidemiological week (EW) ending on the reference date (horizon = 0) as well as for horizons 1 through 4. Teams can (but are not required to) submit forecasts at both citywide and borough (i.e., county) geographic resolution and for all time horizons.

The evaluation data for forecasts will be the weekly aggregate of daily ED visits for each jurisdiction. We will use the specification of EWs defined by the [CDC](https://wwwn.cdc.gov/nndss/document/MMWR_Week_overview.pdf), which run Sunday through Saturday. The target end date for a prediction is the Saturday that ends an EW of interest, and can be calculated using the expression: **target end date = reference date + horizon \* (7 days)**.

There are standard software packages to convert from dates to epidemic weeks and vice versa (e.g. [MMWRweek](https://cran.r-project.org/web/packages/MMWRweek/) and [lubridate](https://lubridate.tidyverse.org/reference/week.html) for R and [pymmwr](https://pypi.org/project/pymmwr/) and [epiweeks](https://pypi.org/project/epiweeks/) for Python).

If you have questions about this target, please reach out to [Dongah Kim](mailto:donga0223@gmail.com).

## Acknowledgments

This repository follows the guidelines and standards outlined by the [hubverse](%5Burl%5D(https://hubverse.io/en/latest/)), which provides a set of data formats and open source tools for modeling hubs.
