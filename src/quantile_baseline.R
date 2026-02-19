#' Check if object is of class quantile_baseline
#'
#' @param object an object that may be a quantile_baseline object
#'
#' @return boolean; whether object is inherits quantile_baseline class
#'
#' @export
is.quantile_baseline <- function(object) {
  return(inherits(object, "quantile_baseline"))
}


#' Create a quantile_baseline object
#'
#' @param inc_diffs historical first differences in incidence
#' @param symmetrize logical. if TRUE (the default), we collect the first
#' differences of incidence and their negatives; the resulting distribution on
#' differences is symmetric. If FALSE, we use only the observed differences.
#'
#' @return quantile_baseline fit object
#'
#' @export
new_quantile_baseline <- function(inc_diffs, symmetrize = TRUE) {
  if(symmetrize) {
    quantile_baseline <- structure(
      c(inc_diffs, -inc_diffs),
      symmetrize = symmetrize,
      class = 'quantile_baseline'
    )
  } else {
    quantile_baseline <- structure(
      inc_diffs,
      symmetrize = symmetrize,
      class = 'quantile_baseline'
    )
  }
  
  return(quantile_baseline)
}


#' Fit a quantile baseline model to historical disease incidence
#'
#' @param incidence numeric vector of disease incidence in past time points
#' @param symmetrize logical. if TRUE (the default), we collect the first
#' differences of incidence and their negatives; the resulting distribution on
#' differences is symmetric. If FALSE, we use only the observed differences.
#' @param window_size integer optional number of past time points to use for
#'   finding first differences.  If not provided, all past first differences
#'   will be used.
#' @param ... other arguments are ignored
#'
#' @return quantile_baseline fit object
#'
#' @export
fit_quantile_baseline <- function(
    incidence,
    symmetrize = TRUE,
    window_size = length(incidence) - 1,
    ...) {
  if(is.na(window_size)) {
    window_size <- length(incidence) - 1
  }
  if(window_size >= length(incidence)) {
    window_size <- length(incidence) - 1
  }
  diffs <- tail(diff(incidence), window_size)
  diffs <- diffs[!is.na(diffs)]
  return(new_quantile_baseline(
    inc_diffs=diffs,
    symmetrize=symmetrize))
}


#' Predict future disease incidence by resampling one-step-ahead forecasts
#'
#' @param quantile_baseline a quantile_baseline fit object
#' @param inc_data numeric vector of length at least one with incident counts
#' @param cum_data numeric vector of length at least one with cumulative counts
#' @param quantiles quantile levels for which  to generate predictions
#' @param horizon number of time steps forward to predict
#' @param num_samples number of samples to use for generating predictions at
#' horizons greater than 1
#'
#' @return data frame with columns target, quantile, and value with forecasts
#' of incident and cumulative deaths
#'
#' @export
predict.quantile_baseline <- function(
  quantile_baseline,
  inc_data,
  cum_data=NULL,
  quantiles,
  horizon,
  num_samples) {
  symmetrize <- attr(quantile_baseline, "symmetrize")
  
  last_inc <- tail(inc_data, 1)
  last_cum <- tail(cum_data, 1)
  
  # Case for horizon 1 is different because sampling is not necessary; we can
  # extract exact quantiles
  
  ## sample incidence, then correct it:
  ## - enforce median difference is 0
  ## - enforce incidence is non-negative
  sampled_inc_diffs <- quantile(
    quantile_baseline,
    probs = seq(from = 0, to = 1.0, length = num_samples))
  sampled_inc_raw <- last_inc + sampled_inc_diffs
  
  # force non-negative incidence
  sampled_inc_corrected <- pmax(sampled_inc_raw, 0)
  
  ## obtain cumulative counts as last_cum + sampled incidence
  sampled_cum <- last_cum + sampled_inc_corrected
  
  ## save as a data frame
  results <- bind_rows(
    data.frame(
      horizon = 1,
      type = 'inc',
      quantile = quantiles,
      value = quantile(sampled_inc_corrected, probs = quantiles),
      stringsAsFactors = FALSE
    ),
    data.frame(
      horizon = 1,
      type = 'cum',
      quantile = quantiles,
      value = quantile(sampled_cum, probs = quantiles),
      stringsAsFactors = FALSE
    )
  )
  
  # add incidence to update cumulative counts
  sampled_cum <- last_cum + sampled_inc_corrected
  
  for(h in (1 + seq_len(horizon - 1))) {
    sampled_inc_diffs <- sample(sampled_inc_diffs, size = num_samples, replace = FALSE)
    sampled_inc_raw <- sampled_inc_raw + sampled_inc_diffs
    
    # force median difference = 0
    if (symmetrize) {
      sampled_inc_corrected <- sampled_inc_raw - (median(sampled_inc_raw) - last_inc)
    } else {
      sampled_inc_corrected <- sampled_inc_raw
    }
    
    # force non-negative incidence
    sampled_inc_corrected <- pmax(sampled_inc_corrected, 0)
    
    # add incidence to update cumulative counts
    sampled_cum <- sampled_cum + sampled_inc_corrected
    
    # get data frame of results
    results <- bind_rows(
      results,
      data.frame(
        horizon = h,
        type = 'inc',
        quantile = quantiles,
        value = quantile(sampled_inc_corrected, probs = quantiles),
        stringsAsFactors = FALSE
      ),
      data.frame(
        horizon = h,
        type = 'cum',
        quantile = quantiles,
        value = quantile(sampled_cum, probs = quantiles),
        stringsAsFactors = FALSE
      )
    )
  }
  
  return(results)
}


#' Predict future disease incidence by resampling one-step-ahead forecasts
#'
#' @param quantile_baseline a quantile_baseline fit object
#' @param newdata numeric vector of length at least one with incident counts
#' @param horizon number of time steps forward to predict
#' @param nsim number of samples to use for generating predictions at
#' horizons greater than 1
#' @param ... mop up unused arguments
#'
#' @return matrix of simulated incidence with nsim rows and horizon columns
#'
#' @export
new_predict.quantile_baseline <- function(
  quantile_baseline,
  newdata,
  horizon,
  nsim,
  ...) {
  # storage space for result
  result <- matrix(NA_real_, nrow = nsim, ncol = horizon)
  
  # initialize at most recent observed incidence
  last_inc <- sampled_inc_raw <- tail(newdata, 1)
  
  # quantiles of past differences in incidence
  sampled_inc_diffs <- quantile(
    quantile_baseline,
    probs = seq(from = 0, to = 1.0, length = nsim))
  
  for(h in seq_len(horizon)) {
    sampled_inc_diffs <- sample(sampled_inc_diffs, size = nsim, replace = FALSE)
    sampled_inc_raw <- sampled_inc_raw + sampled_inc_diffs
    
    # if fit was done with symmetrize=TRUE, force median difference = 0
    if(attr(quantile_baseline, 'symmetrize')) {
      sampled_inc_corrected <- sampled_inc_raw - (median(sampled_inc_raw) - last_inc)
    } else {
      sampled_inc_corrected <- sampled_inc_raw
    }
    
    # save results
    result[, h] <- sampled_inc_corrected
  }
  
  return(result)
}
