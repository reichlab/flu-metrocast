# Target Data Directory

## Table of Contents

- [Target Data](#target-data)
  - [Target data format](#target-data-format)
    - [time-series](#time-series)
    - [oracle-output](#oracle-output)
    - [latest-data](#latest-data)

# Target Data

Target data are the “ground truth” observed data being modeled as the prediction target. You can find the raw and target data in the `raw-data` and `target-data` folders of the MetroCast GitHub repository. Raw data represent ground truth data in its raw or native form. Target data are specially formatted raw data that can be used for model fitting, visualization or evaluation purposes. 

The target data for forecasts of locations with NSSP data are based on the weekly percentage of total ED visits associated with influenza, available from the [CDC’s National Syndromic Surveillance Program (NSSP)](https://data.cdc.gov/Public-Health-Surveillance/NSSP-Emergency-Department-Visit-Trajectories-by-St/rdmq-nq56/about_data). The target data for NYC forecasts are based on the weekly percentage of total ED visits associated with influenza-like illness, available from the [New York City Department of Health and Mental Hygiene’s EpiQuery - Syndromic Surveillance Data](https://a816-health.nyc.gov/hdi/epiquery/). Forecasts for North Carolina will use data from the [North Carolina Division of Public Health's (NC DPH) statewide syndromic surveillance system](https://publichealth.nc.gov/index.htm).

Time-series target data for the most recent complete epidemiological week (EW) (i.e., Sunday through Saturday of the previous week) will be updated by midday Wednesday for both NSSP and NYC data. Since NYC data updates daily, more recent data for NYC are available for the current incomplete EW that modelers can access on their own and use in their model. 

---

## Target data format

The following sections discuss the target data formats available in the `target-data` directory of the Flu MetroCast Hub ([time-series.csv](#time-series), [oracle-output.csv](#oracle-output), and [latest-data.csv](#latest-data)). Please note the [latest-data format](#latest-data), which is presented last, may be the most relevant for modelers. 

---

### time-series

In time-series data, each row of the data set corresponds to one unit of observation. For example, if the percentage of ED visits due to influenza per week is being reported for each of several local jurisdictions, the unit of observation would be a location and week. 

The data set consists of:
* Columns that provide additional information about the prediction, with one column representing a date or `as_of` date.
* An `observation` column with the observed value.

The `as_of` date indicates what target data were available at a specific point in time, and is used when target data is initially represented by one value that may be revised in subsequent versions of the data due to reporting delays. When filtering or querying by a given `as_of` date, only that season’s data are included. The complete cross-season historical record is available only in [latest_data](#latest-data).

**Example of time-series target data from the pilot season of the Flu MetroCast Hub**

| as_of      | location    | target            | target_end_date | observation |
|-------------|-------------|-------------------|-----------------|--------------|
| 2025-05-20 | san-antonio | Flu ED visits pct | 2025-05-10      | 0.25         |
| 2025-05-20 | dallas      | Flu ED visits pct | 2025-05-10      | 0.31         |
| 2025-05-20 | el-paso     | Flu ED visits pct | 2025-05-10      | 1.11         |
| 2025-05-20 | houston     | Flu ED visits pct | 2025-05-10      | 0.52         |
| 2025-05-20 | austin      | Flu ED visits pct | 2025-05-10      | 0.56         |

---

### oracle-output

Time-series target data can be transformed to [oracle-output data](https://docs.hubverse.io/en/latest/user-guide/target-data.html) for use with evaluation tools. Oracle-output is formatted as a CSV file and represents model output that would have been generated if a model knew the target data values in advance. Oracle-output columns therefore contain a subset of model-output columns, with just those columns needed to align oracle_value with the corresponding model-output value. 

Oracle-output data provides modelers with a single version of the most recent observations, eliminating the need to filter by `as_of` dates for all `target_end_dates` in time-series data. However, oracle-output data are limited to the combinations of `location`, `target`, and `target_end_date` for which forecasts were generated, and do not include past seasons that were not part of the forecasting effort. 

**Example of oracle-output target data from the pilot season of the Flu MetroCast Hub**

| target_end_date | location    | target            | oracle_value |
|-----------------|------------|-----------------|--------------|
| 2025-05-10      | san-antonio | Flu ED visits pct | 0.25         |
| 2025-05-10      | dallas      | Flu ED visits pct | 0.31         |
| 2025-05-10      | el-paso     | Flu ED visits pct | 1.11         |
| 2025-05-10      | houston     | Flu ED visits pct | 0.52         |
| 2025-05-10      | austin      | Flu ED visits pct | 0.56         |

---

### latest-data

Latest-data is much like oracle-output data, but it includes the most up-to-date values for all dates for which target data is available, not just dates corresponding to the subset of `target_end_dates` for which the Hub provides forecasts. 

Latest-data is the best source for modelers to get a single version of the target data with only the most recent observations, and including all historical data available from past seasons. 



