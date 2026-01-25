# ==============================================================================
# Raw Assessment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw assessment data from
# Ohio DOE Azure blob storage.
#
# DATA SOURCE:
#   Ohio DOE Report Card Data Download Portal (Azure Blob Storage)
#   Base URL: https://reportcardstorage.education.ohio.gov/data-download-{year}/
#   SAS Token: Valid until 2031-07-28
#
# FILES:
#   Achievement: {YY}-{YY}_Achievement_Building.xlsx
#   Gap Closing: {YY}-{YY}_Gap_Closing_Building.xlsx
#
# YEARS AVAILABLE: 2018-2025 (no 2020 due to COVID)
#
# ==============================================================================

# SAS token for Ohio DOE Azure blob storage (valid until 2031-07-28)
OH_ASSESSMENT_SAS_TOKEN <- "sv=2020-08-04&ss=b&srt=sco&sp=rlx&se=2031-07-28T05:10:18Z&st=2021-07-27T21:10:18Z&spr=https&sig=nPOvW%2Br2caitHi%2F8WhYwU7xqalHo0dFrudeJq%2B%2Bmyuo%3D"

#' Build Ohio assessment data URL
#'
#' Constructs the full URL for downloading assessment data from Ohio DOE
#' Azure blob storage, including the SAS token for authentication.
#'
#' @param end_year The end year of the school year (e.g., 2025 for 2024-25)
#' @param file_type Either "achievement" or "gap_closing"
#' @return Full URL with SAS token
#' @export
#' @examples
#' \dontrun{
#' # Get URL for 2025 achievement data
#' url <- build_assessment_url(2025, "achievement")
#'
#' # Get URL for 2023 gap closing data
#' url <- build_assessment_url(2023, "gap_closing")
#' }
build_assessment_url <- function(end_year, file_type = "achievement") {
  # Validate file_type
  if (!file_type %in% c("achievement", "gap_closing")) {
    stop("file_type must be 'achievement' or 'gap_closing'")
  }

  # Convert end_year to file name format (e.g., 2025 -> "24-25")
  start_yy <- sprintf("%02d", (end_year - 1) %% 100)
  end_yy <- sprintf("%02d", end_year %% 100)
  year_range <- paste0(start_yy, "-", end_yy)

  # Build file name
  if (file_type == "achievement") {
    file_name <- paste0(year_range, "_Achievement_Building.xlsx")
  } else {
    file_name <- paste0(year_range, "_Gap_Closing_Building.xlsx")
  }

  # Build full URL with SAS token
  base_url <- paste0("https://reportcardstorage.education.ohio.gov/data-download-", end_year, "/")
  paste0(base_url, file_name, "?", OH_ASSESSMENT_SAS_TOKEN)
}


#' Download raw achievement data from Ohio DOE
#'
#' Downloads achievement data from Ohio DOE Azure blob storage.
#' The Achievement file contains Performance Index scores and proficiency
#' level distributions for all Ohio public school buildings.
#'
#' Data includes two sheets:
#' - Performance_Index: Overall performance metrics by building
#' - Report_Only_Indicators (2021+) or Performance_Indicators (pre-2020):
#'   Subject-grade level proficiency rates
#'
#' @param end_year School year end (e.g., 2025 for 2024-25). Valid years: 2018-2025 (no 2020)
#' @param sheet Which sheet to read: "performance_index" (default) or "report_only"
#' @return Raw data frame from Ohio DOE
#' @export
#' @examples
#' \dontrun{
#' # Get 2025 achievement data (Performance Index sheet)
#' raw_2025 <- get_raw_achievement(2025)
#'
#' # Get 2025 subject-level data
#' raw_2025_subjects <- get_raw_achievement(2025, sheet = "report_only")
#'
#' # Get 2019 pre-COVID data
#' raw_2019 <- get_raw_achievement(2019)
#' }
get_raw_achievement <- function(end_year, sheet = "performance_index") {

  # Validate year
  valid_years <- list_assessment_years()
  if (!end_year %in% valid_years) {
    stop(paste(
      "end_year must be one of:", paste(valid_years, collapse = ", "),
      "\n2020 data does not exist due to COVID-19 pandemic."
    ))
  }

  # Build URL
  url <- build_assessment_url(end_year, "achievement")

  # Download file
  message(paste("  Downloading achievement data for", end_year, "..."))
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::timeout(300)
  )

  if (httr::http_error(response)) {
    stop(paste("HTTP error:", httr::status_code(response),
               "\nCould not download achievement data for", end_year))
  }

  # Check file size
  file_info <- file.info(temp_file)
  if (file_info$size < 50000) {
    stop("Downloaded file too small, likely error page")
  }

  # Determine which sheet to read
  sheets <- readxl::excel_sheets(temp_file)

  if (sheet == "performance_index") {
    sheet_name <- "Performance_Index"
  } else if (sheet == "report_only") {
    # Sheet name changed after COVID
    if ("Report_Only_Indicators" %in% sheets) {
      sheet_name <- "Report_Only_Indicators"
    } else if ("Performance_Indicators" %in% sheets) {
      sheet_name <- "Performance_Indicators"
    } else {
      stop("Could not find subject-level data sheet")
    }
  } else {
    stop("sheet must be 'performance_index' or 'report_only'")
  }

  # Read the Excel file
  df <- readxl::read_excel(temp_file, sheet = sheet_name)
  message(paste("  Read", nrow(df), "rows from", sheet_name))

  df$end_year <- end_year
  df
}


#' Download raw gap closing data from Ohio DOE
#'
#' Downloads Gap Closing data from Ohio DOE Azure blob storage.
#' Gap Closing measures how well schools are closing achievement gaps
#' for historically underperforming student subgroups.
#'
#' Data is at the building x subgroup level (10 subgroups per building):
#' - All Students
#' - American Indian or Alaskan Native
#' - Asian or Pacific Islander
#' - Black, Non-Hispanic
#' - Hispanic
#' - Multiracial
#' - White, Non-Hispanic
#' - Economic Disadvantage
#' - English Learner
#' - Students with Disabilities
#'
#' @param end_year School year end (e.g., 2025 for 2024-25). Valid years: 2018-2025 (no 2020)
#' @return Raw data frame from Ohio DOE
#' @export
#' @examples
#' \dontrun{
#' # Get 2025 gap closing data
#' raw_2025 <- get_raw_gap_closing(2025)
#'
#' # Filter to a specific subgroup
#' library(dplyr)
#' raw_2025 %>% filter(Disaggregation == "Economic Disadvantage")
#' }
get_raw_gap_closing <- function(end_year) {

  # Validate year
  valid_years <- list_assessment_years()
  if (!end_year %in% valid_years) {
    stop(paste(
      "end_year must be one of:", paste(valid_years, collapse = ", "),
      "\n2020 data does not exist due to COVID-19 pandemic."
    ))
  }

  # Build URL
  url <- build_assessment_url(end_year, "gap_closing")

  # Download file
  message(paste("  Downloading gap closing data for", end_year, "..."))
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::timeout(300)
  )

  if (httr::http_error(response)) {
    stop(paste("HTTP error:", httr::status_code(response),
               "\nCould not download gap closing data for", end_year))
  }

  # Check file size
  file_info <- file.info(temp_file)
  if (file_info$size < 50000) {
    stop("Downloaded file too small, likely error page")
  }

  # Read the Excel file (Gap Closing sheet)
  df <- readxl::read_excel(temp_file, sheet = "Gap Closing")
  message(paste("  Read", nrow(df), "rows from Gap Closing"))

  df$end_year <- end_year
  df
}


#' List available assessment data years
#'
#' Returns a vector of years for which assessment data is available
#' from the Ohio DOE Azure blob storage.
#'
#' Note: 2020 data does not exist due to the COVID-19 pandemic.
#' Ohio cancelled state testing in spring 2020.
#'
#' @return Integer vector of available years
#' @export
#' @examples
#' list_assessment_years()
#' # Returns: 2018 2019 2021 2022 2023 2024 2025
list_assessment_years <- function() {
  # 2018 is the first year available

  # 2020 does not exist due to COVID
  # Current year depends on release schedule (mid-September)
  all_years <- 2018:2025
  # Remove 2020 (COVID year - no testing)
  all_years[all_years != 2020]
}


#' List available assessment data types
#'
#' Returns a vector of assessment data types available from Ohio DOE.
#'
#' @return Character vector of available assessment types
#' @export
#' @examples
#' list_assessment_types()
#' # Returns: c("achievement", "gap_closing")
list_assessment_types <- function() {
  c("achievement", "gap_closing")
}
