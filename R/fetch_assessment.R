# ==============================================================================
# Assessment Data Fetching Functions
# ==============================================================================
#
# This file contains the main user-facing functions for fetching Ohio
# assessment data.
#
# DATA TYPES:
# - achievement: Performance Index scores and proficiency distributions
# - gap_closing: Achievement gap metrics by subgroup
#
# ==============================================================================

#' Fetch Ohio assessment data
#'
#' Downloads and processes assessment data from the Ohio Department of
#' Education. Supports both Achievement (Performance Index) and Gap Closing
#' data types.
#'
#' Data availability:
#' - Years: 2018-2025 (no 2020 due to COVID)
#' - Types: "achievement" (default), "gap_closing"
#'
#' Achievement data includes:
#' - Performance Index scores (0-120 scale)
#' - Star ratings (1-5)
#' - Proficiency level distributions (7 levels)
#'
#' Gap Closing data includes:
#' - ELA and Math Performance Index by subgroup
#' - Gap Closing percentage
#' - Participation rates
#'
#' @param end_year A school year end (e.g., 2025 for 2024-25). Valid values: 2018-2025 (no 2020)
#' @param type Data type: "achievement" (default) or "gap_closing"
#' @param tidy If TRUE (default), returns data in long format. If FALSE, returns processed wide format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Data frame with assessment data
#' @export
#' @examples
#' \dontrun{
#' # Get 2025 achievement data (tidy format)
#' achieve_2025 <- fetch_assessment(2025)
#'
#' # Get 2025 gap closing data
#' gap_2025 <- fetch_assessment(2025, type = "gap_closing")
#'
#' # Get wide format (one row per building)
#' achieve_wide <- fetch_assessment(2025, tidy = FALSE)
#'
#' # Force fresh download
#' achieve_fresh <- fetch_assessment(2025, use_cache = FALSE)
#' }
fetch_assessment <- function(end_year, type = "achievement", tidy = TRUE, use_cache = TRUE) {

  # Validate year
  valid_years <- list_assessment_years()
  if (!end_year %in% valid_years) {
    stop(paste(
      "end_year must be one of:", paste(valid_years, collapse = ", "),
      "\n2020 data does not exist due to COVID-19 pandemic."
    ))
  }

  # Validate type
  valid_types <- list_assessment_types()
  if (!type %in% valid_types) {
    stop(paste("type must be one of:", paste(valid_types, collapse = ", ")))
  }

  # Determine cache type
  cache_suffix <- if (tidy) "tidy" else "wide"
  cache_type <- paste0("assessment_", type, "_", cache_suffix)

  # Check cache first
  if (use_cache && assessment_cache_exists(end_year, cache_type)) {
    message(paste("Using cached", type, "data for", end_year))
    return(read_assessment_cache(end_year, cache_type))
  }

  # Fetch and process data based on type
  message(paste("Downloading", type, "data for", end_year, "..."))

  if (type == "achievement") {
    raw <- get_raw_achievement(end_year)
    processed <- process_achievement(raw, end_year)

    if (tidy) {
      processed <- tidy_achievement(processed)
    }
  } else if (type == "gap_closing") {
    raw <- get_raw_gap_closing(end_year)
    processed <- process_gap_closing(raw, end_year)

    if (tidy) {
      processed <- tidy_gap_closing(processed)
    }
  }

  # Cache the result
  if (use_cache) {
    write_assessment_cache(processed, end_year, cache_type)
    message(paste("Cached", type, "data for", end_year))
  }

  processed
}


#' Fetch assessment data for multiple years
#'
#' Downloads and combines assessment data for multiple school years.
#'
#' @param end_years Vector of school year ends (e.g., c(2023, 2024, 2025))
#' @param type Data type: "achievement" (default) or "gap_closing"
#' @param tidy If TRUE (default), returns tidy format
#' @param use_cache If TRUE (default), uses cached data when available
#' @return Combined data frame with assessment data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get 3 years of achievement data
#' achieve_multi <- fetch_assessment_multi(2023:2025)
#'
#' # Get 5 years of gap closing data (excluding 2020)
#' gap_multi <- fetch_assessment_multi(c(2019, 2021, 2022, 2023, 2024), type = "gap_closing")
#' }
fetch_assessment_multi <- function(end_years, type = "achievement", tidy = TRUE, use_cache = TRUE) {

  # Validate years
  valid_years <- list_assessment_years()
  invalid_years <- end_years[!end_years %in% valid_years]
  if (length(invalid_years) > 0) {
    stop(paste(
      "Invalid years:", paste(invalid_years, collapse = ", "),
      "\nValid years are:", paste(valid_years, collapse = ", "),
      "\n2020 data does not exist due to COVID-19 pandemic."
    ))
  }

  # Fetch each year
  results <- purrr::map(
    end_years,
    function(yr) {
      message(paste("Fetching", type, "data for", yr, "..."))
      fetch_assessment(yr, type = type, tidy = tidy, use_cache = use_cache)
    }
  )

  # Combine
  dplyr::bind_rows(results)
}


#' Get available years for assessment data
#'
#' Wrapper for list_assessment_years() for consistency with enrollment API.
#'
#' @return Integer vector of available years
#' @export
#' @examples
#' get_assessment_years()
get_assessment_years <- function() {
  list_assessment_years()
}


# ==============================================================================
# Cache Functions for Assessment Data
# ==============================================================================

#' Get cache path for assessment data
#'
#' @param end_year School year end
#' @param cache_type Cache type identifier
#' @return Path to cached file
#' @keywords internal
get_assessment_cache_path <- function(end_year, cache_type) {
  cache_dir <- get_cache_dir()
  file.path(cache_dir, paste0(cache_type, "_", end_year, ".rds"))
}


#' Check if assessment cache exists
#'
#' @param end_year School year end
#' @param cache_type Cache type identifier
#' @param max_age Maximum age in days (default 30)
#' @return TRUE if valid cache exists
#' @keywords internal
assessment_cache_exists <- function(end_year, cache_type, max_age = 30) {
  cache_path <- get_assessment_cache_path(end_year, cache_type)

  if (!file.exists(cache_path)) {
    return(FALSE)
  }

  # Check age
  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days <= max_age
}


#' Read assessment data from cache
#'
#' @param end_year School year end
#' @param cache_type Cache type identifier
#' @return Cached data frame
#' @keywords internal
read_assessment_cache <- function(end_year, cache_type) {
  cache_path <- get_assessment_cache_path(end_year, cache_type)
  readRDS(cache_path)
}


#' Write assessment data to cache
#'
#' @param data Data frame to cache
#' @param end_year School year end
#' @param cache_type Cache type identifier
#' @keywords internal
write_assessment_cache <- function(data, end_year, cache_type) {
  cache_path <- get_assessment_cache_path(end_year, cache_type)
  saveRDS(data, cache_path)
  invisible(cache_path)
}


#' Clear assessment data cache
#'
#' Removes cached assessment data files.
#'
#' @param years Optional vector of years to clear. If NULL, clears all assessment cache.
#' @param type Optional assessment type to clear ("achievement" or "gap_closing"). If NULL, clears both.
#' @return Invisibly returns the number of files removed
#' @export
#' @examples
#' \dontrun{
#' # Clear all assessment cache
#' clear_assessment_cache()
#'
#' # Clear only 2025 data
#' clear_assessment_cache(2025)
#'
#' # Clear only achievement cache
#' clear_assessment_cache(type = "achievement")
#' }
clear_assessment_cache <- function(years = NULL, type = NULL) {
  cache_dir <- get_cache_dir()

  # Build pattern
  if (!is.null(type)) {
    type_pattern <- paste0("assessment_", type)
  } else {
    type_pattern <- "assessment_"
  }

  if (is.null(years)) {
    pattern <- paste0(type_pattern, ".*\\.rds$")
    files <- list.files(cache_dir, pattern = pattern, full.names = TRUE)
  } else {
    files <- unlist(lapply(years, function(yr) {
      pattern <- paste0(type_pattern, ".*_", yr, "\\.rds$")
      list.files(cache_dir, pattern = pattern, full.names = TRUE)
    }))
  }

  if (length(files) > 0) {
    unlink(files, recursive = FALSE, force = TRUE)
    message(paste("Removed", length(files), "cached assessment file(s)"))
  } else {
    message("No cached assessment files to remove")
  }

  invisible(length(files))
}
