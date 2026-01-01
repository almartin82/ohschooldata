# ==============================================================================
# Utility Functions
# ==============================================================================

#' @importFrom rlang .data
NULL


#' Get available years for enrollment data
#'
#' Returns information about the range of school years for which enrollment
#' data is available from the Ohio Department of Education and Workforce.
#'
#' @return A list with three elements:
#'   \describe{
#'     \item{min_year}{The earliest available school year end (e.g., 2007 = 2006-07)}
#'     \item{max_year}{The most recent available school year end (e.g., 2025 = 2024-25)}
#'     \item{description}{A human-readable description of data availability}
#'   }
#' @export
#' @examples
#' years <- get_available_years()
#' years$min_year
#' years$max_year
get_available_years <- function() {
  list(
    min_year = 2007,
    max_year = 2025,
    description = "Ohio ODEW enrollment data is available from 2007 (2006-07 school year) through 2025 (2024-25 school year). Years 2007-2014 use legacy format with varying file structures. Years 2015-present use modern format with consistent ENROLLMENT_BUILDING/DISTRICT files."
  )
}
