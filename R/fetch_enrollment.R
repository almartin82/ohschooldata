# ==============================================================================
# Enrollment Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading enrollment data from the
# Ohio Department of Education and Workforce (ODEW).
#
# ==============================================================================

#' Fetch Ohio enrollment data
#'
#' Downloads and processes enrollment data from the Ohio Department of
#' Education and Workforce EMIS data files. Data is available from the
#' Ohio School Report Cards data download portal.
#'
#' Data availability spans from 2007 to the current school year:
#' - 2007-2014: Legacy format data with varying file structures
#' - 2015-present: Modern format with consistent ENROLLMENT_BUILDING/DISTRICT files
#'
#' @param end_year A school year. Year is the end of the academic year - eg 2023-24
#'   school year is year '2024'. Valid values are 2007 onwards.
#' @param tidy If TRUE (default), returns data in long (tidy) format with subgroup
#'   column. If FALSE, returns wide format with one row per entity.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from ODEW.
#' @return Data frame with enrollment data. Tidy format includes columns:
#'   \itemize{
#'     \item end_year: School year end (e.g., 2024 for 2023-24)
#'     \item district_irn: 6-digit district IRN
#'     \item building_irn: 6-digit building IRN (NA for district-level)
#'     \item district_name: Name of the district
#'     \item building_name: Name of the building (NA for district-level)
#'     \item entity_type: "District" or "Building"
#'     \item county: Ohio county name
#'     \item grade_level: Grade level or "TOTAL"
#'     \item subgroup: Demographic or population subgroup
#'     \item n_students: Student count
#'     \item pct: Percentage of total enrollment
#'   }
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 enrollment data (2023-24 school year)
#' enr_2024 <- fetch_enr(2024)
#'
#' # Get 2025 data (2024-25 school year, released September 2025)
#' enr_2025 <- fetch_enr(2025)
#'
#' # Get historical data from 2010 (2009-10 school year)
#' enr_2010 <- fetch_enr(2010)
#'
#' # Get wide format (one row per entity)
#' enr_wide <- fetch_enr(2024, tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' enr_fresh <- fetch_enr(2024, use_cache = FALSE)
#'
#' # Get multiple years - full available range
#' enr_all <- purrr::map_df(2007:2025, fetch_enr)
#'
#' # Get recent 5 years
#' enr_recent <- purrr::map_df(2020:2024, fetch_enr)
#' }
fetch_enr <- function(end_year, tidy = TRUE, use_cache = TRUE) {

  # Validate year
  available_years <- list_enr_years()
  if (end_year < min(available_years)) {
    stop(paste(
      "end_year must be", min(available_years), "or later.",
      "Earlier data may not be available through the standard download portal."
    ))
  }
  if (end_year > max(available_years)) {
    warning(paste(
      "Data for", end_year, "may not be available yet.",
      "The most recent confirmed year is", max(available_years)
    ))
  }

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "tidy" else "wide"

  # Check cache first
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached data for", end_year))
    return(read_cache(end_year, cache_type))
  }

  # Get raw data
  message(paste("Downloading enrollment data for", end_year, "..."))
  raw <- get_raw_enr(end_year)

  # Process to standard schema
  processed <- process_enr(raw, end_year)

  # Optionally tidy
  if (tidy) {
    processed <- tidy_enr(processed) |>
      id_enr_aggs()
  }

  # Cache the result
  if (use_cache) {
    write_cache(processed, end_year, cache_type)
    message(paste("Cached data for", end_year))
  }

  processed
}


#' Fetch enrollment data for multiple years
#'
#' Downloads and combines enrollment data for multiple school years.
#'
#' @param end_years Vector of school year ends (e.g., c(2022, 2023, 2024))
#' @param tidy If TRUE (default), returns data in long (tidy) format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Combined data frame with enrollment data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get 3 years of data
#' enr_multi <- fetch_enr_multi(2022:2024)
#' }
fetch_enr_multi <- function(end_years, tidy = TRUE, use_cache = TRUE) {

  # Validate years
  available_years <- list_enr_years()
  invalid_years <- end_years[end_years < min(available_years)]
  if (length(invalid_years) > 0) {
    stop(paste("Invalid years:", paste(invalid_years, collapse = ", "),
               "\nend_year must be", min(available_years), "or later."))
  }

  # Fetch each year
  results <- purrr::map(
    end_years,
    function(yr) {
      message(paste("Fetching", yr, "..."))
      fetch_enr(yr, tidy = tidy, use_cache = use_cache)
    }
  )

  # Combine
  dplyr::bind_rows(results)
}


#' Fetch enrollment data for a range of years
#'
#' Convenience function to download enrollment data for a range of years.
#' Results are combined into a single data frame.
#'
#' Data is available from 2007 onwards. Note that legacy years (2007-2014)
#' may have different column availability compared to modern years (2015+).
#'
#' @param start_year First year to fetch (minimum 2007)
#' @param end_year Last year to fetch
#' @param tidy If TRUE (default), returns tidy format
#' @param use_cache If TRUE (default), uses cached data when available
#' @return Combined data frame with enrollment data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get 5 years of recent enrollment data
#' enr_history <- fetch_enr_range(2020, 2024)
#'
#' # Get all available historical data
#' enr_all <- fetch_enr_range(2007, 2025)
#'
#' # Get legacy data only
#' enr_legacy <- fetch_enr_range(2007, 2014)
#' }
fetch_enr_range <- function(start_year, end_year, tidy = TRUE, use_cache = TRUE) {
  years <- start_year:end_year
  purrr::map_df(years, function(y) {
    tryCatch(
      fetch_enr(y, tidy = tidy, use_cache = use_cache),
      error = function(e) {
        warning(paste("Could not fetch data for", y, ":", e$message))
        NULL
      }
    )
  })
}


#' Get Ohio statewide enrollment summary
#'
#' Returns a summary of statewide enrollment totals by year.
#'
#' @param end_year School year end (or vector of years)
#' @param use_cache If TRUE (default), uses cached data
#' @return Data frame with statewide enrollment by year
#' @export
#' @examples
#' \dontrun{
#' # Get statewide summary for 2024
#' state_summary <- get_state_enrollment(2024)
#'
#' # Get 5-year trend
#' state_trend <- get_state_enrollment(2020:2024)
#' }
get_state_enrollment <- function(end_year, use_cache = TRUE) {
  purrr::map_df(end_year, function(y) {
    df <- fetch_enr(y, tidy = TRUE, use_cache = use_cache)

    # Aggregate to state level
    df |>
      dplyr::filter(
        entity_type == "District",
        subgroup == "total_enrollment",
        grade_level == "TOTAL"
      ) |>
      dplyr::summarize(
        end_year = y,
        n_districts = dplyr::n_distinct(district_irn),
        total_enrollment = sum(n_students, na.rm = TRUE),
        .groups = "drop"
      )
  })
}
