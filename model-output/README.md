# Model Output Directory 

## Table of Contents

- [Forecast Formatting](#forecast-formatting)
  - [Subdirectory](#subdirectory)
  - [Metadata](#metadata)
  - [License](#license)
  - [Forecasts](#forecasts)
  - [Forecast File Format](#forecast-file-format)
    - [reference_date](#reference_date)
    - [target](#target)
    - [horizon](#horizon)
    - [target_end_date](#target_end_date)
    - [location](#location)
    - [locations.csv](#locationscsv)
    - [output_type](#output_type)
    - [output_type_id](#output_type_id)
    - [value](#value)
  - [Forecast Submission and Validation](#forecast-submission-and-validation)
    - [Pull Request Forecast Validation](#pull-request-forecast-validation)
    - [Local Forecast Validation](#local-forecast-validation)


# Forecast Formatting

Participating modeling teams must submit weekly quantile forecasts of the percentage of influenza or influenza-like illness (*NYC only*) to the `model-output` subdirectory of a hub.  

For each model, teams must submit one model metadata file to the [`model-metadata` subdirectory](/model-metadata).

Forecasts must follow Hubverse standards, including naming conventions, required columns, and valid values for all required fields, to ensure that model output can be easily aggregated, visualized, and evaluated with downstream tools.  

All submissions must pass automated validation before being accepted.

The following sections provide detailed instructions on formatting and submission requirements.

---

## Subdirectory

All predictions should be submitted directly to the `model-output/` folder in the Flu MetroCast hub repository. Each team/model that submits forecasts will have a unique subdirectory within the `model-output/` directory.

Each subdirectory must be named:
* team-model

where:
- `team` is the team name, and  
- `model` is the name of your model.

Within each subdirectory, the only contents should be submitted forecast files.

---

## Metadata

Each submission team should have an associated metadata file in **YAML** format.  
The file should be submitted with the first projection in the [`model-metadata/` folder](/model-metadata), in a file named:
* team-model.yaml


The structure of the metadata file is documented in the [`model-metadata/` README](/model-metadata).

---

## License

If you are not using one of the [standard licenses](https://github.com/reichlab/covid19-forecast-hub/blob/master/code/validation/accepted-licenses.csv), please contact the hub organizers to request an exception.

---

## Forecasts

Each forecast file should follow the name format:
* YYYY-MM-DD-team-model.csv or .parquet

where:
- YYYY — 4-digit year  
- MM — 2-digit month  
- DD — 2-digit day  
- team — team name  
- model — model name  

The date YYYY-MM-DD is the **`reference_date`**, which is the **Saturday after the Forecast Due Date**.

---

## Forecast File Format

The output file must contain the following eight columns (in any order):

* `reference_date`
* `target` 
* `horizon` 
* `target_end_date` 
* `location` 
* `output_type` 
* `output_type_id` 
* `value` 

No additional columns are allowed.  

The value in each row of the file is a prediction at one quantile level (the level specified in the `output_type_id` field) for a particular combination of `horizon`, `location`, and `target_end_date`.

---

### reference_date

Values in the `reference_date` column must be a date in the ISO format:

* YYYY-MM-DD

This is the date from which all forecasts should be considered. This date is the **Saturday following the Forecast Due Date**, corresponding to the last day of the EW when submissions are made. The `reference_date` should be the same as the date in the filename but is included here to facilitate validation and analysis.

---

### target

Values in the `target` column must be a character (string). Currently, we only accept the following targets:

- `Flu ED visits pct`
- `ILI ED visits pct` *(NYC only)*

---

### horizon

Values in the `horizon` column indicate the number of weeks between the `reference_date` and the `target_end_date`. For both Flu ED visits pct and ILI visits pct, this should be a number **between -1 and 3**.

| Horizon | Description |
|----------|-------------|
| -1 | Week before the current week |
| 0 | Current week |
| 1 | First week after Forecast Due Date |
| 2 | Second week after Forecast Due Date |
| 3 | Third week after Forecast Due Date |

---

**Table showing horizons relative to the Forecast Due Date**

| Horizon | Sun | Mon | Tues | Wed | Thurs | Fri | Sat |
|---------|-----|-----|------|-----|-------|-----|-----|
| -1      |     |     |      |     |       |     | NSSP and NYC data available for EW ending today<br>`target_end_date` for horizon -1 |
| 0       |     |     |      | [Early release of NSSP data on GitHub](https://github.com/CDCgov/covid19-forecast-hub/tree/main/auxiliary-data/nssp-raw-data) for prior EW ending 4 days ago (Saturday)<br>NYC data has daily update<br>Forecast Due Date (8 PM ET) |     |     | `reference_date`<br>`target_end_date` for horizon 0 |
| 1       |     |     |      |     |       |     | `target_end_date` for horizon 1 |
| 2       |     |     |      |     |       |     | `target_end_date` for horizon 2 |
| 3       |     |     |      |     |       |     | `target_end_date` for horizon 3 |


---

### target_end_date

Values in the `target_end_date` column must be in the format:

* YYYY-MM-DD

This is the last date of the forecast target's week. This will be **the date of the Saturday at the end of the forecasted week**. As a reminder, the `target_end_date` is the end date of the week during which influenza activity is reported. Within each row of the submission file, the `target_end_date` should be equal to the `reference_date` + horizon*(7 days). 


---

### location

Values in the `location` column must correspond to a name from the `location` column in the [locations.csv file within the auxiliary-data directory of the Hub repository](/auxiliary-data/locations.csv). 

The location value should be written in all lowercase, with no spaces. Hyphens should be used in place of spaces. With the exception of hyphens, no other punctuation should be used. 

For local jurisdictions, the value is the name of a representative city or county.
* e.g., new-bedford, st-cloud

For aggregate jurisdictions, the location name is either the full state name or NYC. 
* e.g., south-carolina, nyc

---

### locations.csv 

The Flu MetroCast Hub uses the `location` field (column 1, below) in the [locations.csv file](/auxiliary-data/locations.csv) as a key, meaning each location as represented in column 1 must serve as a unique identifier. The value in the location column is a representative city or county of an HSA that typically includes multiple counties. The counties included for each location are listed in the `hsa_counties` column (last column). 

For NSSP data, each HSA has a single unique ID called hsa_nci_id. In the MetroCast Hub metadata, this same value appears as `original_location_code` (column 2). For NYC boroughs, this unique ID is derived from the fips code for the borough, not an hsa_nci_id.  The `location_type` column (column 7) denotes the geographic entity of the location (currently either hsa_nci_id or fips). 

For state-level locations, there is no numeric hsa_nci_id. In NSSP data, state values are uniquely identified by the geography field, which corresponds to the `state` field (column 3).

Therefore, to create a consistent one-to-one mapping between NSSP data and Flu MetroCast Hub data, we use the following two fields to match locations between the NSSP data and the data stored by the MetroCast Hub:
* {geography, hsa_nci_id} in the NSSP data
* {state, original_location_code} in the MetroCast data

This combination ensures that both HSA-level and state-level locations can be matched uniquely across the two datasets.
The `location_name` column (column 5)  provides a more formal representation of the location, which will be used for dashboard visualization. 

The `population` column lists the population of the forecast location (e.g., the population of the HSA for local jurisdictions using NSSP data) according to [5 year (2019-2023) census average estimates](https://www.census.gov/data/developers/data-sets/acs-5year.html?utm_source=chatgpt.com). 


**Sample of locations.csv file**. The `location` column uniquely identifies every location. The `original_location_code` and `state` columns map to the `hsa_nci_id` and `geography` columns in the raw NSSP data. 

| location | original_location_code | state | state_abb | location_name | population | location_type | hsa_counties |
|-----------|------------------------|--------|------------|----------------|-------------|----------------|---------------|
| denver | 688 | Colorado | CO | Denver, CO | 2,948,626 | hsa_nci_id | Adams, Arapahoe, Clear Creek, Denver, Douglas, etc. |
| colorado | All | Colorado | CO | Colorado | 5,810,774 | hsa_nci_id | — |
| nyc | 94 | New York | NY | NYC | 8,516,202 | hsa_nci_id | Bronx, Kings, New York, Queens, Richmond |

---

### output_type

The value in the `output_type` column should be “quantile”, to reflect a set of quantile values of percentage of ED visits due to influenza or ILI (latter for NYC only). 

---

### output_type_id

Values in the `output_type_id` are a quantile. This value indicates the quantile for the value in this row.

Teams should provide the following **9 quantiles**:

* 0.025, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.975


---

### value

Values in the `value` column are non-negative numbers indicating the quantile prediction for that row.

---

## Forecast Submission and Validation

### Pull Request Forecast Validation

When a [pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) is submitted, the data are validated via [GitHub Actions](https://docs.github.com/en/actions) using the [`hubValidations` package](https://github.com/hubverse-org/hubValidations).  
All tests are designed to confirm compliance with the above requirements.  

You may also optionally run validations locally.

---

### Local Forecast Validation

To validate locally:

1) [Create a fork of the Flu-MetroCast repository and then clone the fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo) to your computer.
2) Create a draft of the model submission file for your model and place it in the `model-output/<your model id>` folder of this clone.
3) Install the hubValidations package for R by running the following command from within an R session:

```
remotes::install_github("Infectious-Disease-Modeling-Hubs/hubValidations")
```

4) Validate your draft forecast submission file by running the following command in an R session:
```
`library(hubValidations)
hubValidations::validate_submission(
hub_path = "<path to your clone of the hub repository>",
file_path = "<path to your file, relative to the model-output folder>"`
```
For example, if your working directory is the root of the hub repository, you can use a command similar to the following:
```
library(hubValidations)
hubValidations::validate_submission(
    hub_path=".",
    file_path="epiENGAGE-GBQR/2025-05-24-epiENGAGE-GBQR.csv")
```

The function returns the output of each validation check.
If all is well, all checks should either be prefixed with a ✓ indicating success or ℹ indicating a check was skipped.

If there are any failed checks or execution errors, the check's output will be prefixed with a ✖ or ! and include a message describing the problem.

To get an overall assessment of whether the file has passed validation checks, you can pass the output of validate_submission() to check_for_errors()

If the file passes all validation checks, the function will return the following output:
> ✓ All validation checks have been successful.

If test failures or execution errors are detected, the function throws an error and prints the messages of checks affected. 














