# Forecast Formatting

Participating modeling teams must submit weekly quantile forecasts of the percentage of influenza or influenza-like illness (NYC only) to the `model-output` subdirectory of a hub.  
For each model, teams must submit one model metadata file to the `model-metadata` subdirectory.

Forecasts must follow **Hubverse standards**, including naming conventions, required columns, and valid values for all required fields, to ensure that model output can be easily aggregated, visualized, and evaluated with downstream tools.  
All submissions must pass automated validation before being accepted.

The following sections provide detailed instructions on formatting and submission requirements.

---

## Subdirectory

All predictions should be submitted directly to the `model-output/` folder in the Flu MetroCast hub repository.  
Each team/model that submits forecasts will have a unique subdirectory within the `model-output/` directory.

Each subdirectory must be named:
* team-model

where:
- `team` is the team name, and  
- `model` is the name of your model.

Within each subdirectory, the only contents should be submitted forecast files.

---

## Metadata

Each submission team should have an associated metadata file in **YAML** format.  
The file should be submitted with the first projection in the `model-metadata/` folder, in a file named:
* team-model.yaml


The structure of the metadata file is documented elsewhere in the Hub documentation.

---

## License

If you are not using one of the standard licenses, please contact the hub organizers to request an exception.

---

## Forecasts

Each forecast file should follow the name format:
* YYYY-MM-DD-team-model.csv

or
* YYYY-MM-DD-team-model.parquet


where:
- `YYYY` — 4-digit year  
- `MM` — 2-digit month  
- `DD` — 2-digit day  
- `team` — team name  
- `model` — model name  

The date `YYYY-MM-DD` is the **reference_date**, which is the **Saturday after the Forecast Due Date**.

---

## Forecast File Format

The output file must contain the following eight columns (in any order):

| Column | Description |
|---------|-------------|
| `reference_date` | ISO date of forecast reference (YYYY-MM-DD) |
| `target` | Forecast target |
| `horizon` | Number of weeks between `reference_date` and `target_end_date` |
| `target_end_date` | Saturday at end of forecasted week |
| `location` | Location identifier |
| `output_type` | Should be `"quantile"` |
| `output_type_id` | Quantile level |
| `value` | Predicted value |

> No additional columns are allowed.  
> Each row is a prediction for a particular quantile, horizon, location, and target_end_date.

---

### reference_date

Values must be in ISO format:

* YYYY-MM-DD


This is the date from which all forecasts are considered (the Saturday following the Forecast Due Date).  
It should match the date in the filename.

---

### target

Allowed values:
- `Flu ED visits pct`
- `ILI ED visits pct` *(NYC only)*

---

### horizon

The `horizon` column indicates the number of weeks between the `reference_date` and the `target_end_date`.  
Allowed values: **-1 to 3**

| Horizon | Description |
|----------|-------------|
| -1 | Week before the current week |
| 0 | Current week |
| 1 | First week after Forecast Due Date |
| 2 | Second week after Forecast Due Date |
| 3 | Third week after Forecast Due Date |

---

### Example Horizon Table (relative to Forecast Due Date)

| Horizon | Sun | Mon | Tues | Wed | Thurs | Fri | Sat |
|---------|-----|-----|------|-----|-------|-----|-----|
| -1      |     |     |      |     |       |     | NSSP and NYC data available for EW ending today<br>`target_end_date` for horizon -1 |
| 0       |     |     |      | Early release of NSSP data on GitHub for prior EW ending 4 days ago (Saturday)<br>NYC data has daily update<br>Forecast Due Date (8 PM ET) |     |     | `reference_date`<br>`target_end_date` for horizon 0 |
| 1       |     |     |      |     |       |     | `target_end_date` for horizon 1 |
| 2       |     |     |      |     |       |     | `target_end_date` for horizon 2 |
| 3       |     |     |      |     |       |     | `target_end_date` for horizon 3 |


---

### target_end_date

Must be formatted as:

* YYYY-MM-DD

This is the **Saturday** at the end of the forecast week.  

Within each row:

* target_end_date = reference_date + horizon * 7 days


---

### location

Values in the `location` column must correspond to names from the `locations.csv` file in the `auxiliary-data` directory.  
They must:
- Be all lowercase  
- Contain no spaces  
- Use hyphens instead of spaces  

**Examples:**
- Local jurisdictions: `new-bedford`, `st-cloud`  
- Aggregate jurisdictions: `south-carolina`, `nyc`

---

### locations.csv 

The Flu MetroCast Hub uses the location field (column 1, Table 6) in the locations.csv file as a key, meaning each location as represented in column 1 must serve as a unique identifier. The value in the location column is a representative city or county of an HSA that typically includes multiple counties. The counties included for each location are listed in the hsa_counties column (last column). 

For NSSP data, each HSA has a single unique ID called hsa_nci_id. In the MetroCast Hub metadata, this same value appears as original_location_code (column 2). For NYC boroughs, this unique ID is derived from the fips code for the borough, not an hsa_nci_id.  The location_type column (column 7) denotes the geographic entity of the location (currently either hsa_nci_id or fips). 

For state-level locations, there is no numeric hsa_nci_id. In NSSP data, state values are uniquely identified by the geography field, which corresponds to the state field (column 3).

Therefore, to create a consistent one-to-one mapping between NSSP data and Flu MetroCast Hub data, we use the following two fields to match locations between the NSSP data and the data stored by the MetroCast Hub:
* {geography, hsa_nci_id} in the NSSP data
* {state, original_location_code} in the MetroCast data

This combination ensures that both HSA-level and state-level locations can be matched uniquely across the two datasets.
The location_name column (column 5)  provides a more formal representation of the location, which will be used for dashboard visualization. 

The population column lists the population of the forecast location (e.g., the population of the HSA for local jurisdictions using NSSP data) according to 5 year (2019-2023) census average estimates. 


**Example:** Sample of locations.csv file. The `location` column uniquely identifies every location. The `original_location_code` and `state` columns map to the `hsa_nci_id` and `geography` columns in the raw NSSP data. 

| location | original_location_code | state | state_abb | location_name | population | location_type | hsa_counties |
|-----------|------------------------|--------|------------|----------------|-------------|----------------|---------------|
| denver | 688 | Colorado | CO | Denver, CO | 2,948,626 | hsa_nci_id | Adams, Arapahoe, Clear Creek, Denver, Douglas, etc. |
| colorado | All | Colorado | CO | Colorado | 5,810,774 | hsa_nci_id | — |
| staten-island | 36085 | New York | NY | Staten Island, NY | 492,734 | fips | Richmond |
| nyc | 94 | New York | NY | NYC | 8,516,202 | hsa_nci_id | Bronx, Kings, New York, Queens, Richmond |

---

### Matching NSSP and MetroCast Hub Data

To ensure unique mappings between datasets:

* NSSP data → { geography, hsa_nci_id }
* MetroCast data → { state, original_location_code }


---

### output_type

The only valid value is:

* quantile


This represents a set of quantile values of the percentage of ED visits due to influenza or ILI.

---

### output_type_id

Values indicate the **quantile level**.  
Teams should provide the following **9 quantiles**:

* 0.025, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.975


---

### value

Values are non-negative numbers indicating the quantile prediction for that row.

---

## Forecast Submission and Validation

### Pull Request Forecast Validation

When a pull request is submitted, the data are validated via **GitHub Actions** using the `hubValidations` package.  
All tests are designed to confirm compliance with the above requirements.  
You may also optionally run validations locally.

---

### Local Forecast Validation

To validate locally:

1. Fork the `Flu-MetroCast` repository and clone it.
2. Place your forecast file in:
* model-output/<your-model-id>/
3. Install the validation package in R:
```
remotes::install_github("Infectious-Disease-Modeling-Hubs/hubValidations")
```

4. Validate your file:
```
`library(hubValidations)
hubValidations::validate_submission(
hub_path = "<path to your clone of the hub repository>",
file_path = "<path to your file, relative to the model-output folder>"`
```
**Example:**










