# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from ODEW.
# Ohio uses EMIS (Education Management Information System) for data collection.
#
# Data is available from the Ohio School Report Cards download portal at
# reportcardstorage.education.ohio.gov
#
# ==============================================================================

#' Download raw enrollment data from ODEW
#'
#' Downloads enrollment data from the Ohio School Report Cards data download
#' portal. Data includes district and building level enrollment by grade,
#' demographics, and special populations.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return Raw data frame from ODEW
#' @keywords internal
get_raw_enr <- function(end_year) {

 # Ohio Report Card data is available from ~2015 onwards in consistent format
  # Earlier years have different formats and locations

  if (end_year >= 2015) {
    get_raw_enr_modern(end_year)
  } else {
    get_raw_enr_legacy(end_year)
  }
}


#' Download modern format ODEW enrollment data
#'
#' Downloads enrollment data from the Ohio School Report Cards portal.
#' Modern format (2015+) uses Excel files with consistent naming.
#'
#' @param end_year School year end
#' @return Raw data frame with district and building enrollment
#' @keywords internal
get_raw_enr_modern <- function(end_year) {

  # Build URLs for Ohio Report Card data
  # Format: https://reportcardstorage.education.ohio.gov/data-download-YYYY/
  # Files: YY-YY_Enrollment_Building.xlsx, YY-YY_Enrollment_District.xlsx

  # Calculate school year string (e.g., 2024 -> "23-24")
  start_year <- end_year - 1
  yy_start <- substr(start_year, 3, 4)
  yy_end <- substr(end_year, 3, 4)
  year_str <- paste0(yy_start, "-", yy_end)

  # Base URL for report card storage
  base_url <- paste0(
    "https://reportcardstorage.education.ohio.gov/data-download-",
    end_year, "/"
  )

  # Try to download building-level enrollment data
  building_file <- paste0(year_str, "_ENROLLMENT_BUILDING.xlsx")
  building_url <- paste0(base_url, building_file)

  district_file <- paste0(year_str, "_ENROLLMENT_DISTRICT.xlsx")
  district_url <- paste0(base_url, district_file)

  # Download building data
  building_df <- download_ohio_excel(building_url, "building", end_year)

  # Download district data
  district_df <- download_ohio_excel(district_url, "district", end_year)

  # Combine district and building data
  # Add entity_type to distinguish
  if (!is.null(building_df)) {
    building_df$entity_type <- "Building"
  }
  if (!is.null(district_df)) {
    district_df$entity_type <- "District"
  }

  # Combine datasets
  if (!is.null(district_df) && !is.null(building_df)) {
    result <- dplyr::bind_rows(district_df, building_df)
  } else if (!is.null(district_df)) {
    result <- district_df
  } else if (!is.null(building_df)) {
    result <- building_df
  } else {
    stop(paste("Could not download enrollment data for year", end_year))
  }

  result$end_year <- end_year
  result
}


#' Download Ohio Excel file
#'
#' Helper function to download and read an Excel file from ODEW.
#' Handles multiple potential URL patterns since Ohio's file naming
#' varies slightly year to year.
#'
#' @param url Primary URL to try
#' @param type "building" or "district"
#' @param end_year School year end
#' @return Data frame or NULL if download fails
#' @keywords internal
download_ohio_excel <- function(url, type, end_year) {

  # Create temp file
  tname <- tempfile(
    pattern = paste0("ohio_enr_", type),
    tmpdir = tempdir(),
    fileext = ".xlsx"
  )

  # Try primary URL
  result <- tryCatch({
    downloader::download(url, dest = tname, mode = "wb", quiet = TRUE)

    # Check if file is valid (not an error page)
    file_info <- file.info(tname)
    if (file_info$size < 5000) {
      warning(paste("Downloaded file too small, likely error page:", url))
      return(NULL)
    }

    # Read Excel file
    df <- readxl::read_excel(tname, sheet = 1)
    df
  }, error = function(e) {
    NULL
  })

  # If primary URL failed, try alternate URL patterns
  if (is.null(result)) {
    # Ohio sometimes uses different naming conventions
    start_year <- end_year - 1
    yy_start <- substr(start_year, 3, 4)
    yy_end <- substr(end_year, 3, 4)

    alt_patterns <- c(
      # Lowercase
      paste0(yy_start, "-", yy_end, "_Enrollment_", stringr::str_to_title(type), ".xlsx"),
      # Different separator
      paste0(yy_start, yy_end, "_ENROLLMENT_", toupper(type), ".xlsx"),
      # Full year
      paste0(start_year, "-", end_year, "_ENROLLMENT_", toupper(type), ".xlsx")
    )

    base_url <- paste0(
      "https://reportcardstorage.education.ohio.gov/data-download-",
      end_year, "/"
    )

    for (pattern in alt_patterns) {
      alt_url <- paste0(base_url, pattern)
      result <- tryCatch({
        downloader::download(alt_url, dest = tname, mode = "wb", quiet = TRUE)
        file_info <- file.info(tname)
        if (file_info$size < 5000) next
        df <- readxl::read_excel(tname, sheet = 1)
        message(paste("Found data at:", alt_url))
        df
      }, error = function(e) {
        NULL
      })
      if (!is.null(result)) break
    }
  }

  # Clean up temp file
  if (file.exists(tname)) {
    unlink(tname)
  }

  result
}


#' Download legacy format ODEW enrollment data
#'
#' Downloads enrollment data for years prior to 2015 when data formats
#' and locations were different.
#'
#' @param end_year School year end
#' @return Raw data frame
#' @keywords internal
get_raw_enr_legacy <- function(end_year) {

  # Legacy Ohio data is harder to access consistently
 # Try the enrollment data page on education.ohio.gov

  start_year <- end_year - 1
  yy_start <- substr(start_year, 3, 4)
  yy_end <- substr(end_year, 3, 4)

  # Try older report card storage format
  base_url <- paste0(
    "https://reportcardstorage.education.ohio.gov/data-download-",
    end_year, "/"
  )

  # Try several potential file patterns
  file_patterns <- c(
    paste0(yy_start, "-", yy_end, "_Enrollment_Building.xlsx"),
    paste0(yy_start, yy_end, "_Enrollment_Building.xlsx"),
    paste0("Enrollment_Building_", end_year, ".xlsx"),
    paste0(yy_start, "-", yy_end, "_ENROLLMENT_BUILDING.xlsx")
  )

  tname <- tempfile(pattern = "ohio_legacy", tmpdir = tempdir(), fileext = ".xlsx")

  for (pattern in file_patterns) {
    url <- paste0(base_url, pattern)
    result <- tryCatch({
      downloader::download(url, dest = tname, mode = "wb", quiet = TRUE)
      file_info <- file.info(tname)
      if (file_info$size < 5000) next
      df <- readxl::read_excel(tname, sheet = 1)
      df$end_year <- end_year
      df$entity_type <- "Building"
      message(paste("Found legacy data at:", url))
      df
    }, error = function(e) {
      NULL
    })
    if (!is.null(result)) {
      if (file.exists(tname)) unlink(tname)
      return(result)
    }
  }

  # Clean up
  if (file.exists(tname)) unlink(tname)

  stop(paste(
    "Could not find enrollment data for year", end_year,
    "- legacy data may not be available through the standard download portal"
  ))
}


#' List available enrollment data years
#'
#' Returns a vector of years for which enrollment data is likely available
#' from the Ohio School Report Cards portal.
#'
#' @return Integer vector of available years
#' @export
#' @examples
#' \dontrun{
#' available_years <- list_enr_years()
#' }
list_enr_years <- function() {
  # Ohio Report Card data is generally available from 2015 onwards
  # Current year data typically becomes available in fall
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  current_month <- as.integer(format(Sys.Date(), "%m"))

  # If we're past October, current year data should be available
  max_year <- if (current_month >= 10) current_year else current_year - 1

  # Return available range
  2015:max_year
}
