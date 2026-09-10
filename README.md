# Flu MetroCast Hub 2026-2027 Guidelines
Run by [epiENGAGE](https://epiengage.org/)––an [Insight Net](https://www.cdc.gov/insight-net/php/about/index.html) Center for Implementation within the U.S. Centers for Disease Control and Prevention (CDC)’s Center for Forecasting and Outbreak Analytics (CFA)


**Table of Contents**

-   [Executive summary](#executive-summary)
-   [Metro-level Forecasts of Influenza During the 2026-2027 Season](#metro-level-forecasts-of-influenza-during-the-2026-2027-season)
    -   [Dates](#dates)
    -   [Prediction targets](#prediction-targets)
        -   [Locations and horizons](#locations-and-horizons)
    -   [Model output data storage](#model-output-data-storage)
-   [Target data](#target-data)
-   [Forecast formatting](#forecast-formatting)
-   [Forecast submission and validation](#forecast-submission-and-validation)
-   [Evaluation criteria](#evaluation-criteria)
-   [Publication of forecasts](#publication-of-forecasts)

## Executive summary

The Flu MetroCast Hub is a collaborative modeling project that collects and shares weekly probabilistic forecasts of influenza activity at the metropolitan level in the United States. This modeling hub is led by the [epiENGAGE team](https://epiengage.org/) at the University of Texas at Austin and the University of Massachusetts Amherst.

Accurate predictions of key public health surveillance indicators––such as the percentage of emergency department (ED) visits due to influenza––can shed light on seasonal trends, disease severity, and healthcare system strain. While many U.S. infectious disease forecasting hubs provide state- or national-level forecasts, the Flu MetroCast Hub fills an important gap by aggregating and evaluating forecasts at the sub-state level. 

Metro-level forecasting provides several key benefits:
* Reveals local patterns that state-level forecasts can miss, leading to more accurate and timely decisions.
* Builds modeling capacity and data infrastructure that strengthen readiness for future outbreak.
* Generates insights that are accessible and actionable for public health officials, healthcare systems, and community leaders.

From **November 4, 2026 through May 19, 2027**, participating modeling teams must submit **weekly sample forecasts of the percentage of ED visits due to influenza for forecast horizons ranging from 0 to +3 weeks** and may optionally submit **full-season trajectories covering the remainder of the influenza season**. For the 2026-2027 season, all forecasts––except those for NYC and North Carolina––will use publicly-available data from the [CDC’s National Syndromic Surveillance Program (NSSP)](https://healthdata.gov/CDC/NSSP-Emergency-Department-Visit-Trajectories-by-St/hr4c-e7p6/about_data). These data provide weekly estimates of the percentage of influenza-related ED visits at the level of Health Service Areas (HSAs), which are single- or multi-county clusters reflecting local healthcare catchments that often align with metropolitan areas. Forecasts for NYC will use data from the [New York City Department of Health and Mental Hygiene’s EpiQuery - Syndromic Surveillance Data](https://a816-health.nyc.gov/hdi/epiquery/). Forecasts for North Carolina will use data from the  [North Carolina Division of Public Health's (NC DPH) statewide syndromic surveillance system](https://publichealth.nc.gov/index.htm).

All forecasts and observed target data will be publicly available in the Flu MetroCast GitHub repository, following Hubverse standards. Model submissions will be validated for compliance with these standards and incorporated into an ensemble forecast. Both ensemble and individual model outputs will be displayed on a [public-facing interactive dashboard](https://reichlab.io/metrocast-dashboard/). Forecasts will be evaluated in real time using metrics such as the weighted interval score (WIS), and results will be publicly reported. A [pre-registered evaluation](https://osf.io/rc9dt/overview) will be conducted at the end of the season.

The following guidelines provide detailed instructions for participating teams on submission deadlines, forecast targets, data sources, and standardized formatting, submission, and validation procedures. 

Anyone interested in using these data for additional research or publications should contact us at [epiengage@austin.utexas.edu](mailto:epiengage@austin.utexas.edu) for information on proper attribution of the source forecasts.

---

## Metro-level Forecasts of Influenza During the 2026-2027 Season
### Dates
The initial Flu MetroCast Hub submission will be due on **Wednesday, November 4, 2026**, with subsequent weekly submissions until May 19, 2027. 

Participating teams must submit weekly forecasts **by 8 PM Eastern Time each Wednesday (the Forecast Due Date)** for inclusion in the ensemble model. This deadline aligns with the early Wednesday release of NSSP data on the percentage of ED visits. Any changes to the Forecast Due Date (e.g., due to holidays) will be communicated promptly by the MetroCast organizing team.

Each weekly submission file must include the `reference date`––defined as the **Saturday following the Forecast Due Date**––in its filename, following the format: YYYY-MM-DD-team-model.csv, where YYYY-MM-DD indicates the reference date. 

---

### Prediction targets
From November through May, participating teams will submit weekly probabilistic **sample** forecasts of the percentage of ED visits due to influenza. Beginning with the 2026-2027 season **we will no longer accept quantiles**. The following sample requirements will be enforced:
* each sample represents a trajectory for a given location and target. This is, in hubverse terminology, saying that the [compound_taskid_set](https://docs.hubverse.io/en/latest/user-guide/sample-output-type.html#compound-modeling-tasks) will include location and target. Thinking statistically, this means that the forecast distribution is required to be sampled with dependence across horizons for a given location. Models could also submit samples that are joint across locations and horizons.
* 100 samples will be required for each target-location-horizon.

Please see [hubverse documentation for additional information on sample output type](https://docs.hubverse.io/en/latest/user-guide/sample-output-type.html).

The Hub will primarily collect forecasts at the city-, county-, region-, or metro-level (typically corresponding to HSAs) and, for validation, will also collect predictions for the corresponding state-level forecasts. 

---

#### Locations and horizons
This season, teams should submit:
* Weekly sample forecasts of the percentage of ED visits due to influenza at the sub-state location
* Weekly sample forecasts of the percentage of ED visits due to influenza at the corresponding state level.
  
A full list of local and state jurisdictions to be forecasted can be found in the [locations.csv file in the Hub repository](/auxiliary-data/locations.csv). This file currently includes 64 sub-state locations (56 HSAs, NYC, and 7 North Carolina DHHS regions) and 13 states. **We expect that additional jurisdictions may be added to this list based on data availability and interest as the season progresses.** 

Forecasts are required to cover horizons 0 to +3 weeks, defined as follows using horizon 0 as a starting point:
* Horizon = 0: the current epidemiological week encompassing the Sunday prior to the Forecast Due Date through the upcoming Saturday.
For more information on forecast horizons, see the [horizon subsection in the `model-output` README](/model-output#horizon).

Modelers may also submit full-season trajectories. If modelers elect to submit full-season trajectories, they must submit them every week for the remainder of the season. 


**Target name, horizon, and aggregate jurisdiction for sub-state forecasts.** The target refers to the percentage of ED visits in a given week due to influenza.

| Target name       | Horizon       | Aggregate jurisdiction                                                                                                  |
|--------------------|---------------|--------------------------------------------------------------------------------------------------------------------------|
| Flu ED visits pct  | 0 to +3 weeks (**required**), full-season trajectory for remainder of season (optional) | Corresponding state –– Colorado, Georgia, Indiana, Maine, Maryland, Massachusetts, Minnesota, New York, North Carolina, South Carolina, Oregon, Texas, Utah, Virginia |

---

### Model output data storage
The Flu MetroCast Hub will store a live dataset in this dedicated GitHub repository, following [Hubverse file-based data storage standards](https://docs.hubverse.io/en/latest/user-guide/hub-structure.html). The repository will contain separate directories for model output and model metadata submissions from modeling teams.

Model output must follow a tabular representation where each row represents a single prediction and each column provides additional information about the prediction (see the Forecast File Format section). **Model output must be submitted as Parquet files**. Beginning with the 2026-2027 season, file sizes will be larger due to the option to submit for additional horizons and the change to sample output type. The change to Parquet will help keep file sizes smaller.

---

## Target data

Target data are the “ground truth” observed data being modeled as the prediction target. You can find the raw and target data in the [`raw-data`](/raw-data) and [`target-data`](/target-data) folders of the MetroCast GitHub repository. Raw data represent ground truth data in its raw or native form. Target data are specially formatted raw data that can be used for model fitting, visualization, or evaluation purposes. 

The target data for forecasts of locations with NSSP data available from the [CDC’s National Syndromic Surveillance Program (NSSP)](https://healthdata.gov/CDC/NSSP-Emergency-Department-Visit-Trajectories-by-St/hr4c-e7p6/about_data).  

The target data for NYC forecasts are available from the [New York City Department of Health and Mental Hygiene’s EpiQuery - Syndromic Surveillance Data](https://a816-health.nyc.gov/hdi/epiquery/). 

The target data for North Carolina (NC) forecasts are provided by The North Carolina Disease Event Tracking and Epidemiologic Collection Tool (NC DETECT) is North Carolina’s statewide syndromic surveillance system. NC DETECT was created by the [North Carolina Division of Public Health (NC DPH)](https://publichealth.nc.gov/index.htm) in 2004 in collaboration with the Carolina Center for Health Informatics (CCHI) in the UNC Department of Emergency Medicine to address the need for early event detection and timely public health surveillance in North Carolina using a variety of secondary data sources.  

Time-series target data for the most recent complete epidemiological week (EW) (i.e., Sunday through Saturday of the previous week) will be updated by midday Wednesday for NSSP, NYC, and NC data. Since NYC data updates daily, more recent data for NYC are available for the current incomplete EW that modelers can access on their own and use in their model. NC data are only updated on a weekly basis.

Please see the [`target-data` README](/target-data#readme) for more information on target data formats. 

---

## Forecast formatting

Participating modeling teams must submit weekly sample forecasts of the percentage of influenza or influenza-like illness (*NYC only*) to the [`model-output` subdirectory](/model-output) of a hub. 

For each model, teams must submit one model metadata file to the [`model-metadata` subdirectory](/model-metadata). Beginning with the 2026-2027 season, teams must include an additional metadata field to indicate whether they are submitting full-season forecast trajectories every week:
* long_term_forecasts: true | false

Forecasts must follow Hubverse standards, including naming conventions, required columns, and valid values for all required fields, to ensure that model output can be easily aggregated, visualized, and evaluated with downstream tools. All submissions must pass automated validation before being accepted. 

Please see the [`model-output` README](/model-output#readme) for detailed instructions on formatting and submission requirements. 

---

## Forecast submission and validation

To ensure proper data formatting, pull requests for new data in `model-output/` will be automatically run. Optionally, you may also run these validations locally. Please see the [`model-output` README](/model-output) for detailed instructions on formatting and submission requirements. 

---

## Evaluation criteria

Forecasts will be evaluated using a variety of metrics, including weighted interval score (WIS) and its components and prediction interval coverage. Evaluation will use official data reported by the CDC and New York Department of Health and Mental Hygiene. 

Our [evaluation plan](https://osf.io/rc9dt/overview) focuses on two main questions:
1) **When and where do local forecasts provide the greatest benefit?**
We will compare local- and state-level forecasts to determine where local forecasts yield more accurate predictions of community-level influenza trends. We will also examine whether their utility is associated with jurisdictional characteristics such as population density, geographic size, and the number or distribution of population centers.

3) **Which forecasting models perform best, and why?**
We will identify the models that perform most reliably for each location and evaluate how performance varies across jurisdictions and spatial scales. We will also assess which modeling approaches perform best overall and explore factors that may explain differences in performance.

---

## Publication of forecasts

All participants provide consent for their forecasts and evaluation thereof to be published in real-time on the [Flu MetroCast dashboard](https://reichlab.io/metrocast-dashboard/), the Flu Metrocast Hub repository, and potentially in a scientific journal describing the results of the forecasting challenge. 

