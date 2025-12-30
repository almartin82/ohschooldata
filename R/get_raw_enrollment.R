# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from ODEW.
# Ohio uses EMIS (Education Management Information System) for data collection.
#
# ==============================================================================

#' Download raw enrollment data from ODEW
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return Raw data frame from ODEW
#' @keywords internal
get_raw_enr <- function(end_year) {

  # TODO: Determine the correct URL pattern for Ohio data
  # Ohio data portal: https://education.ohio.gov/Topics/Data
  # EMIS data may be available in different formats by year

  # TODO: Handle modern format (recent years)

  # TODO: Handle legacy format (older years)

  stop("Not yet implemented - see docs/PRD.md for specifications")
}


#' Download modern format ODEW enrollment data
#'
#' @param end_year School year end
#' @return Raw data frame
#' @keywords internal
get_raw_enr_modern <- function(end_year) {

  # TODO: Build URL for Ohio data
  # Example: https://education.ohio.gov/Topics/Data/Frequently-Requested-Data/Enrollment-Data

  # TODO: Download to temp file

  # TODO: Read the data file (Excel, CSV, or other format)

  # TODO: Add end_year column

  stop("Not yet implemented")
}


#' Download legacy format ODEW enrollment data
#'
#' @param end_year School year end
#' @return Raw data frame
#' @keywords internal
get_raw_enr_legacy <- function(end_year) {

  # TODO: Handle older data formats from Ohio

  stop("Not yet implemented")
}
