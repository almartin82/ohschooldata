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
#' Data availability by year:
#' - 2007-2014: Legacy format with different file naming conventions
#' - 2015-present: Modern format with consistent ENROLLMENT_BUILDING/DISTRICT files
#'
#' Note: Ohio Report Card data access may require manual download from
#' \url{https://reportcard.education.ohio.gov/download} if direct downloads
#' fail. The download portal uses dynamic tokens that may prevent automated
#' access.
#'
#' @param end_year School year end (2023-24 = 2024). Valid range is 2007 to current year.
#' @return Raw data frame from ODEW
#' @export
#' @examples
#' \dontrun{
#' # Get raw 2024 data
#' raw_2024 <- get_raw_enr(2024)
#'
#' # Get historical 2010 data
#' raw_2010 <- get_raw_enr(2010)
#' }
get_raw_enr <- function(end_year) {

  # Validate year range
  if (end_year < 2007) {
    stop(paste(
      "end_year must be 2007 or later.",
      "Earlier data requires EMIS direct access or archived sources."
    ))
  }

  # Ohio Report Card data format differs by era:
  # - 2007-2014: Legacy format with various file naming patterns
  # - 2015+: Modern format with consistent ENROLLMENT_BUILDING/DISTRICT naming

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
#' Note: Ohio uses dynamic tokens for file access which may cause downloads
#' to fail. If automated download fails, you may need to:
#' 1. Visit https://reportcard.education.ohio.gov/download
#' 2. Select year and download Enrollment files manually
#' 3. Use import_local_enrollment() to load the downloaded files
#'
#' @param end_year School year end
#' @return Raw data frame with district and building enrollment
#' @keywords internal
get_raw_enr_modern <- function(end_year) {

  # Build URLs for Ohio Report Card data
  # Ohio uses various URL patterns depending on the year
  # Format: https://reportcardstorage.education.ohio.gov/data-download-YYYY/

  # Calculate school year string (e.g., 2024 -> "23-24")
  start_year <- end_year - 1
  yy_start <- substr(start_year, 3, 4)
  yy_end <- substr(end_year, 3, 4)
  year_str <- paste0(yy_start, "-", yy_end)

  # Try multiple base URL patterns
  base_urls <- c(
    paste0("https://reportcardstorage.education.ohio.gov/data-download-", end_year, "/"),
    paste0("https://reportcardstorage.education.ohio.gov/", end_year, "/"),
    paste0("https://reportcardstorage.education.ohio.gov/downloads/", end_year, "/")
  )

  # Try multiple file naming patterns
  building_patterns <- c(
    paste0(year_str, "_ENROLLMENT_BUILDING.xlsx"),
    paste0(year_str, "_Enrollment_Building.xlsx"),
    paste0(year_str, "-ENROLLMENT-BUILDING.xlsx"),
    "ENROLLMENT_BUILDING.xlsx",
    "Enrollment_Building.xlsx"
  )

  district_patterns <- c(
    paste0(year_str, "_ENROLLMENT_DISTRICT.xlsx"),
    paste0(year_str, "_Enrollment_District.xlsx"),
    paste0(year_str, "-ENROLLMENT-DISTRICT.xlsx"),
    "ENROLLMENT_DISTRICT.xlsx",
    "Enrollment_District.xlsx"
  )

  # Try to download building-level enrollment data
  building_df <- NULL
  for (base_url in base_urls) {
    for (pattern in building_patterns) {
      building_url <- paste0(base_url, pattern)
      building_df <- download_ohio_excel(building_url, "building", end_year)
      if (!is.null(building_df)) break
    }
    if (!is.null(building_df)) break
  }

  # Try to download district-level enrollment data
  district_df <- NULL
  for (base_url in base_urls) {
    for (pattern in district_patterns) {
      district_url <- paste0(base_url, pattern)
      district_df <- download_ohio_excel(district_url, "district", end_year)
      if (!is.null(district_df)) break
    }
    if (!is.null(district_df)) break
  }

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
    stop(paste(
      "Could not download enrollment data for year", end_year, "\n",
      "Ohio Report Card data may require manual download.\n",
      "Please visit: https://reportcard.education.ohio.gov/download\n",
      "Download the Enrollment files and use import_local_enrollment() to load them."
    ))
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
#' Downloads enrollment data for years 2007-2014 when data formats
#' and file naming conventions were different from modern years.
#'
#' Legacy data file patterns discovered through research:
#' - 2014: "SCHOOL ENROLLMENT BY GRADE.xls", "DISTRICT ENROLLMENT BY GRADE.xls"
#' - 2007-2013: Various patterns including "ENROLLMENT_BUILDING.xls", grade-level files
#'
#' @param end_year School year end (2007-2014)
#' @return Raw data frame with enrollment data
#' @keywords internal
get_raw_enr_legacy <- function(end_year) {

  start_year <- end_year - 1
  yy_start <- substr(start_year, 3, 4)
  yy_end <- substr(end_year, 3, 4)

  # Base URL for legacy data downloads
 base_url <- paste0(
    "https://reportcardstorage.education.ohio.gov/data-download-",
    end_year, "/"
  )

  # Legacy file patterns vary significantly by year
 # Based on research, here are the known patterns:
  building_patterns <- c(
    # 2014 pattern (confirmed via search)
    "SCHOOL%20ENROLLMENT%20BY%20GRADE.xls",
    "SCHOOL ENROLLMENT BY GRADE.xls",
    # Other legacy patterns
    paste0(yy_start, "-", yy_end, "_Enrollment_Building.xlsx"),
    paste0(yy_start, "-", yy_end, "_ENROLLMENT_BUILDING.xlsx"),
    paste0(yy_start, yy_end, "_Enrollment_Building.xlsx"),
    paste0(yy_start, yy_end, "_ENROLLMENT_BUILDING.xlsx"),
    "ENROLLMENT_BUILDING.xls",
    "ENROLLMENT_BUILDING.xlsx",
    "Enrollment_Building.xls",
    "Enrollment_Building.xlsx",
    paste0("Enrollment_Building_", end_year, ".xlsx"),
    paste0(yy_start, "-", yy_end, "_Building_Enrollment.xlsx"),
    paste0("Building_Enrollment_", yy_start, "-", yy_end, ".xlsx"),
    paste0("FY", yy_end, "_Enrollment_Building.xlsx"),
    paste0("FY", end_year, "_Enrollment_Building.xlsx")
  )

  district_patterns <- c(
    # 2014 pattern
    "DISTRICT%20ENROLLMENT%20BY%20GRADE.xls",
    "DISTRICT ENROLLMENT BY GRADE.xls",
    # Other legacy patterns
    paste0(yy_start, "-", yy_end, "_Enrollment_District.xlsx"),
    paste0(yy_start, "-", yy_end, "_ENROLLMENT_DISTRICT.xlsx"),
    paste0(yy_start, yy_end, "_Enrollment_District.xlsx"),
    paste0(yy_start, yy_end, "_ENROLLMENT_DISTRICT.xlsx"),
    "ENROLLMENT_DISTRICT.xls",
    "ENROLLMENT_DISTRICT.xlsx",
    "Enrollment_District.xls",
    "Enrollment_District.xlsx",
    paste0("Enrollment_District_", end_year, ".xlsx"),
    paste0(yy_start, "-", yy_end, "_District_Enrollment.xlsx"),
    paste0("District_Enrollment_", yy_start, "-", yy_end, ".xlsx"),
    paste0("FY", yy_end, "_Enrollment_District.xlsx"),
    paste0("FY", end_year, "_Enrollment_District.xlsx")
  )

  # Try to download building-level data
  building_df <- NULL
  tname <- tempfile(pattern = "ohio_legacy_building", tmpdir = tempdir(), fileext = ".xlsx")

  for (pattern in building_patterns) {
    url <- paste0(base_url, pattern)
    building_df <- tryCatch({
      downloader::download(url, dest = tname, mode = "wb", quiet = TRUE)
      file_info <- file.info(tname)
      if (file_info$size < 5000) {
        NULL
      } else {
        # Try both xls and xlsx readers
        df <- tryCatch(
          readxl::read_excel(tname, sheet = 1),
          error = function(e) NULL
        )
        if (!is.null(df)) {
          message(paste("Found legacy building data at:", url))
        }
        df
      }
    }, error = function(e) {
      NULL
    })
    if (!is.null(building_df)) break
  }
  if (file.exists(tname)) unlink(tname)

  # Try to download district-level data
  district_df <- NULL
  tname <- tempfile(pattern = "ohio_legacy_district", tmpdir = tempdir(), fileext = ".xlsx")

  for (pattern in district_patterns) {
    url <- paste0(base_url, pattern)
    district_df <- tryCatch({
      downloader::download(url, dest = tname, mode = "wb", quiet = TRUE)
      file_info <- file.info(tname)
      if (file_info$size < 5000) {
        NULL
      } else {
        df <- tryCatch(
          readxl::read_excel(tname, sheet = 1),
          error = function(e) NULL
        )
        if (!is.null(df)) {
          message(paste("Found legacy district data at:", url))
        }
        df
      }
    }, error = function(e) {
      NULL
    })
    if (!is.null(district_df)) break
  }
  if (file.exists(tname)) unlink(tname)

  # Add entity type markers
  if (!is.null(building_df)) {
    building_df$entity_type <- "Building"
  }
  if (!is.null(district_df)) {
    district_df$entity_type <- "District"
  }

  # Combine results
  if (!is.null(district_df) && !is.null(building_df)) {
    result <- dplyr::bind_rows(district_df, building_df)
  } else if (!is.null(district_df)) {
    result <- district_df
  } else if (!is.null(building_df)) {
    result <- building_df
  } else {
    stop(paste(
      "Could not find enrollment data for year", end_year, "\n",
      "Legacy data (2007-2014) uses varying file formats.\n",
      "Please try downloading manually from: https://reportcard.education.ohio.gov/download\n",
      "Then use import_local_enrollment() to load the files."
    ))
  }

  result$end_year <- end_year
  result
}


#' List available enrollment data years
#'
#' Returns a vector of years for which enrollment data is likely available
#' from the Ohio School Report Cards portal.
#'
#' Ohio Report Card data availability:
#' - 2007-2014: Legacy format data (data-download-YYYY folders with varying file names)
#' - 2015-present: Modern format with consistent ENROLLMENT_BUILDING/DISTRICT files
#'
#' Note: EMIS historical data extends back to the 1990s but requires different
#' access methods. This package focuses on the Report Card download portal data.
#'
#' @return Integer vector of available years
#' @export
#' @examples
#' \dontrun{
#' available_years <- list_enr_years()
#' }
list_enr_years <- function() {
  # Ohio Report Card data is available from 2007 onwards in the data-download folders
  # Legacy data (2007-2014) uses different file naming conventions
  # Modern data (2015+) uses consistent ENROLLMENT_BUILDING/DISTRICT naming
  # Current year data typically becomes available in fall (September)
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  current_month <- as.integer(format(Sys.Date(), "%m"))

  # If we're past September, current year data should be available
  # Ohio releases report cards in mid-September

  max_year <- if (current_month >= 10) current_year else current_year - 1

  # Return available range - data goes back to 2007
  2007:max_year
}


#' Import local enrollment Excel files
#'
#' Imports enrollment data from locally downloaded Excel files.
#' Use this when automatic downloads fail and you need to manually
#' download files from \url{https://reportcard.education.ohio.gov/download}.
#'
#' @param district_file Path to district-level enrollment Excel file
#' @param building_file Path to building-level enrollment Excel file (optional)
#' @param end_year School year end (e.g., 2024 for 2023-24)
#' @return Raw data frame with enrollment data
#' @export
#' @examples
#' \dontrun{
#' # After downloading files from Ohio Report Card portal:
#' enr_raw <- import_local_enrollment(
#'   district_file = "~/Downloads/23-24_ENROLLMENT_DISTRICT.xlsx",
#'   building_file = "~/Downloads/23-24_ENROLLMENT_BUILDING.xlsx",
#'   end_year = 2024
#' )
#' }
import_local_enrollment <- function(district_file = NULL, building_file = NULL, end_year) {

  if (is.null(district_file) && is.null(building_file)) {
    stop("At least one of district_file or building_file must be provided")
  }

  district_df <- NULL
  building_df <- NULL

  if (!is.null(district_file)) {
    if (!file.exists(district_file)) {
      stop(paste("District file not found:", district_file))
    }
    district_df <- readxl::read_excel(district_file, sheet = 1)
    district_df$entity_type <- "District"
    message(paste("Loaded district data:", nrow(district_df), "rows"))
  }

  if (!is.null(building_file)) {
    if (!file.exists(building_file)) {
      stop(paste("Building file not found:", building_file))
    }
    building_df <- readxl::read_excel(building_file, sheet = 1)
    building_df$entity_type <- "Building"
    message(paste("Loaded building data:", nrow(building_df), "rows"))
  }

  # Combine datasets
  if (!is.null(district_df) && !is.null(building_df)) {
    result <- dplyr::bind_rows(district_df, building_df)
  } else if (!is.null(district_df)) {
    result <- district_df
  } else {
    result <- building_df
  }

  result$end_year <- end_year
  result
}
