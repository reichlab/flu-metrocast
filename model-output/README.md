# Model outputs folder

<mark style="background-color: #FFE331">**Below is a template of the README.md file for the model-ouput folder of your hub. Italics in brackets are placeholders for information about your hub. **</mark>

This folder contains a set of subdirectories, one for each model, that contains submitted model output files for that model. The structure of these directories and their contents follows [the model output guidelines in our documentation](https://hubverse.io/en/latest/user-guide/model-output.html). Documentation for hub submissions specifically is provided below. 

# Data submission instructions

All forecasts should be submitted directly to the [model-output/](./)
folder. Data in this directory should be added to the repository through
a pull request so that automatic data validation checks are run.

These instructions provide detail about the [data
format](#Data-formatting) as well as [validation](#Forecast-validation) that
you can do prior to this pull request. In addition, we describe
[metadata](https://github.com/hubverse-org/hubTemplate/blob/master/model-metadata/README.md)
that each model should provide in the model-metadata folder.

*Table of Contents*

-   [What is a forecast](#What-is-a-forecast)
-   [Target data](#Target-data)
-   [Data formatting](#Data-formatting)
-   [Forecast file format](#Forecast-file-format)
-   [Forecast data validation](#Forecast-validation)
-   [Weekly ensemble build](#Weekly-ensemble-build)
-   [Policy on late submissions](#policy-on-late-or-updated-submissions)

## What is a forecast 

Models are asked to make specific quantitative forecasts about data that
will be observed in the future. These forecasts are interpreted as
"unconditional" predictions about the future. That is, they are not
predictions only for a limited set of possible future scenarios in which
a certain set of conditions (e.g. vaccination uptake is strong, or new
social-distancing mandates are put in place) hold about the future --
rather, they should characterize uncertainty across all reasonable
future scenarios. In practice, all forecasting models make some
assumptions about how current trends in data may change and impact the
forecasted outcome; some teams select a "most likely" scenario or
combine predictions across multiple scenarios that may occur. Forecasts
submitted to this repository will be evaluated against observed data.

We note that other modeling efforts, such as the [Influenza Scenario
Modeling Hub](https://fluscenariomodelinghub.org/), have been
launched to collect and aggregate model outputs from "scenario
projection" models. These models create longer-term projections under a
specific set of assumptions about how the main drivers of the pandemic
(such as non-pharmaceutical intervention compliance, or vaccination
uptake) may change over time.

## Target Data 

*[insert description target data]* 


## Data formatting 

The automatic checks in place for forecast files submitted to this
repository validates both the filename and file contents to ensure the
file can be used in the visualization and ensemble forecasting.

### Subdirectory

Each model that submits forecasts for this project will have a unique subdirectory within the [model-output/](model-output/) directory in this GitHub repository where forecasts will be submitted. Each subdirectory must be named

    team-model

where

-   `team` is the team name and
-   `model` is the name of your model.

Both team and model should be less than 15 characters and not include
hyphens or other special characters, with the exception of "\_".

The combination of `team` and `model` should be unique from any other model in the project.


### Metadata

The metadata file will be saved within the model-metdata directory in the Hub's GitHub repository, and should have the following naming convention:


      team-model.yml

Details on the content and formatting of metadata files are provided in the [model-metadata README](https://github.com/hubverse-org/hubTemplate/blob/master/model-metadata/README.md).




### Forecasts

Each forecast file should have the following
format

    YYYY-MM-DD-team-model.csv

where

-   `YYYY` is the 4 digit year,
-   `MM` is the 2 digit month,
-   `DD` is the 2 digit day,
-   `team` is the team name, and
-   `model` is the name of your model.

The date YYYY-MM-DD is the [`reference_date`](#reference_date). This should be the Saturday following the submission date.

The `team` and `model` in this file must match the `team` and `model` in
the directory this file is in. Both `team` and `model` should be less
than 15 characters, alpha-numeric and underscores only, with no spaces
or hyphens. 

## Forecast file format 

The file must be a comma-separated value (csv) file with the following
columns (in any order):

-   `reference_date`
-   `target`
-   `horizon`
-   `target_end_date`
-   `location`
-   `output_type`
-   `output_type_id`
-   `value`

No additional columns are allowed.

The value in each row of the file is a quantile for a particular combination of location, date, and horizon. 

### `reference_date` 

Values in the `reference_date` column must be a date in the ISO format

    YYYY-MM-DD

This is the date from which all forecasts should be considered. This date is the Saturday following the submission Due Date, corresponding to the last day of the epiweek when submissions are made. The `reference_date` should be the same as the date in the filename but is included here to facilitate validation and analysis. 

### `target`

Values in the `target` column must be a character (string) and be one of
the following specific targets:

-   *`ILI ED visits `* 
-   *`Flu ED visits pct `*


### `horizon`
Values in the `horizon` column indicate the number of weeks  between the `reference_date` and the `target_end_date`. For ILI ED visits should be a number between 0 and 4 and for Flu ED visits pct should be a number between -1 and 3, where for example a `horizon` of 0 indicates that the prediction is a nowcast for the week of submission and a `horizon` of 1 indicates that the prediction is a forecast for the weekafter submission. 

### `target_end_date`

Values in the `target_end_date` column must be a date in the format

    YYYY-MM-DD
    
This is the last date of the forecast target's week. This will be the date of the Saturday at the end of the forecasted week. Within each row of the submission file, the `target_end_date` should be equal to the `reference_date` + `horizon`* (7 days).


### `location`

Values in the `location` column must be one of the "locations" in
this [NYC population] ([https://github.com/reichlab/flu-metrocast/blob/main/auxiliary-data/nyc_population.csv] ) which
includes five boroughs, as well as NYC (sum of five boroughs).  

### `output_type`


Values in the `output_type` column are 

-   "quantile" 

This value indicates whether that row corresponds to a quantile forecast for ILI ED visits or Flu ED visits pct. Quantile forecasts are used in visualizations and to construct the primary flu-metrocast ensemble.

### `output_type_id`
Values in the `output_type_id` column specify identifying information for the output type.

#### quantile output
When the predictions are quantiles, values in the `output_type_id` column are a quantile probability level in the format

    0.###

 This value indicates the quantile probability level for for the
`value` in this row.

Teams must provide the following 9 quantiles:

0.025, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.975

R: c(0.025, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.975)
Python: [0.025, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.975]


### `value`

Values in the `value` column are non-negative numbers indicating the "quantile" prediction for this row. For a "quantile" prediction, `value` is the inverse of the cumulative distribution function (CDF) for the target, location, and quantile associated with that row. For example, the 2.5 and 97.5 quantiles for a given target and location should capture 95% of the predicted values and correspond to the central 95% Prediction Interval. 

### Example tables

| reference_date | horizon|  target_end_date | target EW dates covered
|------------------------|------------------------|------------------------|------------------------|
|2025-01-25 | -1 | 2025-01-18 | 2025-01-12 to 2025-01-18 | 
|2025-01-25 | 0  | 2025-01-25 | 2025-01-19 to 2025-01-25 | 
|2025-01-25 | 1  | 2025-02-01 | 2025-01-26 to 2025-02-01 | 
|2025-01-25 | 2  | 2025-02-08 | 2025-02-02 to 2025-02-08 | 
|2025-01-25 | 3  | 2025-02-15 | 2025-02-09 to 2025-02-15 | 

## Forecast validation 

To ensure proper data formatting, pull requests for new data in
`model-output/` will be automatically run. Optionally, you may also run these validations locally.

### Pull request forecast validation

When a pull request is submitted, the data are validated through [Github
Actions](https://docs.github.com/en/actions) which runs the tests
present in [the hubValidations
package](https://github.com/hubverse-org/hubValidations). The
intent for these tests are to validate the requirements above. Please
[let us know]( *[Insert url to your hub's issues]*) if you are facing issues while running the tests.

### Local forecast validation

Optionally, you may validate a forecast file locally before submitting it to the hub in a pull request. Note that this is not required, since the validations will also run on the pull request. To run the validations locally, follow these steps:

 *[Add description for local forecast validation]*


## Weekly ensemble build 

Every  *[day and time]*, we will generate a  *[hub name]* ensemble  *[Insert target]* using valid forecast submissions in the current week by the *[day and time]* deadline. Some or all participant forecasts may be combined into an ensemble forecast to be published in real-time along with the participant forecasts. In addition, some or all forecasts may be displayed alongside the output of a baseline model for comparison.


## Policy on late or updated submissions 

In order to ensure that forecasting is done in real-time, all forecasts are required to be submitted to this repository by 9PM ET on Tuesdays each week. We do not accept late forecasts.

## Evaluation criteria
Forecasts will be evaluated using a variety of metrics, including *[describe how they will be evaluated]*

<mark style="background-color: #FFE331">**As an example, here is a link to the [Flusight-Forecast_Hub model-output README](https://github.com/cdcepi/FluSight-forecast-hub/blob/master/model-output/README.md).**</mark>
