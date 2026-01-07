# ==============================================================================
# School Directory Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading school directory data from the
# Ohio Department of Education and Workforce (ODEW) OEDS system.
#
# Data source: https://oeds.ode.state.oh.us/DataExtract
#
# ==============================================================================

#' Fetch Ohio school directory data
#'
#' Downloads and processes school directory data from the Ohio Department of
#' Education and Workforce OEDS (Ohio Educational Directory System). This
#' includes all public schools and districts with contact information and
#' administrator names.
#'
#' @param end_year Currently unused. The directory data represents current
#'   schools and is not year-specific. Included for API consistency with
#'   other fetch functions.
#' @param tidy If TRUE (default), returns data in a standardized format with
#'   consistent column names. If FALSE, returns raw column names from OEDS.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from ODEW.
#' @return A tibble with school directory data. Columns include:
#'   \itemize{
#'     \item \code{irn}: 6-digit IRN (Information Retrieval Number)
#'     \item \code{state_school_id}: IRN (same as irn, for schema consistency)
#'     \item \code{state_district_id}: Parent IRN (district IRN for schools)
#'     \item \code{school_name}: Name of the school or district
#'     \item \code{district_name}: Parent organization name
#'     \item \code{school_type}: Grade-level category (Elementary, High School, etc.)
#'     \item \code{org_type}: Organization type (Public School, Public District, etc.)
#'     \item \code{org_category}: Category (School, District, etc.)
#'     \item \code{grades_served}: Grade span served
#'     \item \code{status}: Organization status (Open, Closed, etc.)
#'     \item \code{county}: Ohio county name
#'     \item \code{address}: Full mailing address
#'     \item \code{city}: City (parsed from address)
#'     \item \code{state}: State (always "Ohio")
#'     \item \code{zip}: ZIP code (parsed from address)
#'     \item \code{phone}: Phone number
#'     \item \code{fax}: Fax number
#'     \item \code{website}: Organization website URL
#'     \item \code{email}: Organization email address
#'     \item \code{superintendent_name}: Superintendent name
#'     \item \code{superintendent_email}: Superintendent email
#'     \item \code{superintendent_phone}: Superintendent phone
#'     \item \code{treasurer_name}: Treasurer name
#'     \item \code{treasurer_email}: Treasurer email
#'     \item \code{principal_name}: Principal name
#'     \item \code{principal_email}: Principal email
#'     \item \code{principal_phone}: Principal phone
#'   }
#' @details
#' The directory data is downloaded from the OEDS Data Extract API. This data
#' represents the current state of Ohio schools and districts and is updated
#' regularly by ODEW.
#'
#' @export
#' @examples
#' \dontrun{
#' # Get school directory data
#' dir_data <- fetch_directory()
#'
#' # Get raw format (original OEDS column names)
#' dir_raw <- fetch_directory(tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' dir_fresh <- fetch_directory(use_cache = FALSE)
#'
#' # Filter to active schools only
#' library(dplyr)
#' active_schools <- dir_data |>
#'   filter(org_category == "School", status == "Open")
#'
#' # Find all schools in a district
#' columbus_schools <- dir_data |>
#'   filter(state_district_id == "043802", org_category == "School")
#' }
fetch_directory <- function(end_year = NULL, tidy = TRUE, use_cache = TRUE) {

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "directory_tidy" else "directory_raw"

  # Check cache first
  if (use_cache && cache_exists_directory(cache_type)) {
    message("Using cached school directory data")
    return(read_cache_directory(cache_type))
  }

  # Get raw data from OEDS
  raw <- get_raw_directory()

  # Process to standard schema
  if (tidy) {
    result <- process_directory(raw)
  } else {
    result <- raw
  }

  # Cache the result
  if (use_cache) {
    write_cache_directory(result, cache_type)
  }

  result
}


#' Get raw school directory data from OEDS
#'
#' Downloads the raw school directory data from the Ohio Department of
#' Education and Workforce OEDS Data Extract API.
#'
#' @return Raw data frame as downloaded from OEDS
#' @keywords internal
get_raw_directory <- function() {

  message("Downloading school directory data from OEDS...")

  # OEDS organization type keys:
  # 1 = Public District
  # 2 = Nonpublic District
  # 3 = Career Technical Planning District
  # 4 = Joint Vocational School District
  # 5 = Nonpublic School
  # 6 = Community School
  # 7 = Public School
  # 23 = Educational Service Center
  # 45 = Vocational School
  # 60 = STEM School

  # Get all educational organizations
  org_types <- c(1, 2, 3, 4, 5, 6, 7, 23, 45, 60)

  url <- "https://oeds.ode.state.oh.us/DataExtract/GetRequestOrgExtract"

  # Build JSON payload
  json_data <- paste0('{"OrgTypes":[', paste(org_types, collapse = ","), '],"OrgCats":[],"Selected":[]}')

  # Download to temp file
  tname <- tempfile(pattern = "oeds_directory", tmpdir = tempdir(), fileext = ".csv")

  # Set longer timeout for large files (10 minutes)
  old_timeout <- getOption("timeout")
  options(timeout = 600)

  tryCatch({
    response <- httr::POST(
      url,
      body = list(jsonData = json_data),
      encode = "form",
      httr::write_disk(tname, overwrite = TRUE),
      httr::timeout(600),
      httr::user_agent("ohschooldata R package"),
      httr::config(ssl_verifypeer = TRUE)
    )

    if (httr::http_error(response)) {
      stop(paste("HTTP error:", httr::status_code(response)))
    }
  }, error = function(e) {
    options(timeout = old_timeout)
    stop(paste("Failed to download school directory data from OEDS:", e$message))
  })

  options(timeout = old_timeout)

  # Check if download was successful
  file_info <- file.info(tname)
  if (file_info$size < 1000) {
    stop("Download failed - file too small, may be error page")
  }

  message(paste("Downloaded", round(file_info$size / 1024, 1), "KB file"))

  # Read CSV file - skip the first line which contains the generation timestamp
  df <- utils::read.csv(
    tname,
    skip = 1,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = c("", "N/A", "NA")
  )

  message(paste("Loaded", nrow(df), "records"))

  # Convert to tibble for consistency
  dplyr::as_tibble(df)
}


#' Process raw school directory data to standard schema
#'
#' Takes raw school directory data from OEDS and standardizes column names,
#' types, and adds derived columns.
#'
#' @param raw_data Raw data frame from get_raw_directory()
#' @return Processed data frame with standard schema
#' @keywords internal
process_directory <- function(raw_data) {

  # Clean up IRN columns - remove Excel formula markers like ="043489"
  clean_irn <- function(x) {
    x <- gsub('^="', '', x)
    x <- gsub('"$', '', x)
    # Ensure 6-digit format with leading zeros
    x <- sprintf("%06s", x)
    x <- gsub(" ", "0", x)
    x
  }

  # Parse address into components
  parse_address <- function(address_str) {
    if (is.na(address_str) || address_str == "") {
      return(list(street = NA_character_, city = NA_character_,
                  state = NA_character_, zip = NA_character_))
    }

    # Ohio addresses typically: "123 Main St, City, Ohio, 12345"
    parts <- strsplit(address_str, ",\\s*")[[1]]

    if (length(parts) >= 4) {
      list(
        street = trimws(parts[1]),
        city = trimws(parts[2]),
        state = trimws(parts[3]),
        zip = trimws(parts[4])
      )
    } else if (length(parts) >= 2) {
      list(
        street = trimws(parts[1]),
        city = trimws(parts[2]),
        state = "Ohio",
        zip = NA_character_
      )
    } else {
      list(
        street = trimws(address_str),
        city = NA_character_,
        state = "Ohio",
        zip = NA_character_
      )
    }
  }

  # Build standardized result
  result <- dplyr::tibble(
    irn = clean_irn(raw_data[["IRN"]]),
    state_school_id = clean_irn(raw_data[["IRN"]]),
    state_district_id = clean_irn(raw_data[["PARENT IRN"]]),
    school_name = trimws(raw_data[["ORGANIZATION NAME"]]),
    district_name = trimws(raw_data[["PARENT ORGANIZATION NAME"]]),
    school_type = trimws(raw_data[["SCHOOL TYPE"]]),
    org_type = trimws(raw_data[["ORGANIZATION TYPE"]]),
    org_category = trimws(raw_data[["ORGANIZATION CATEGORY"]]),
    grades_served = clean_irn(raw_data[["GRADE SPAN"]]),  # Also uses ="X" format
    status = trimws(raw_data[["STATUS"]]),
    county = trimws(raw_data[["DESIGNATED COUNTY"]]),
    address = trimws(raw_data[["ORG MAILING ADDRESS"]]),
    phone = trimws(raw_data[["ORG PHONE"]]),
    fax = trimws(raw_data[["ORG FAX"]]),
    website = trimws(raw_data[["WEB URL"]]),
    email = trimws(raw_data[["ORG EMAIL ADDRESS"]]),
    superintendent_name = trimws(raw_data[["SUPERINTENDENT"]]),
    superintendent_email = trimws(raw_data[["SUPERINTENDENT EMAIL"]]),
    superintendent_phone = trimws(raw_data[["SUPERINTENDENT PHONE"]]),
    treasurer_name = trimws(raw_data[["TREASURER"]]),
    treasurer_email = trimws(raw_data[["TREASURER EMAIL"]]),
    treasurer_phone = trimws(raw_data[["TREASURER PHONE"]]),
    principal_name = trimws(raw_data[["PRINCIPAL"]]),
    principal_email = trimws(raw_data[["PRINCIPAL EMAIL"]]),
    principal_phone = trimws(raw_data[["PRINCIPAL PHONE"]])
  )

  # Clean grades_served - remove quotes and Excel formatting
  result$grades_served <- gsub('^="', '', result$grades_served)
  result$grades_served <- gsub('"$', '', result$grades_served)
  result$grades_served <- gsub("^0+", "", result$grades_served)  # Remove leading zeros from grades
  result$grades_served <- ifelse(result$grades_served == "", NA_character_, result$grades_served)

  # Parse addresses to get city, state, zip
  parsed_addresses <- lapply(result$address, parse_address)
  result$city <- sapply(parsed_addresses, function(x) x$city)
  result$city <- as.character(result$city)
  result$state <- "OH"
  result$zip <- sapply(parsed_addresses, function(x) x$zip)
  result$zip <- as.character(result$zip)

  # Reorder columns for consistency
  preferred_order <- c(
    "irn", "state_school_id", "state_district_id",
    "school_name", "district_name",
    "school_type", "org_type", "org_category",
    "grades_served", "status", "county",
    "address", "city", "state", "zip",
    "phone", "fax", "website", "email",
    "superintendent_name", "superintendent_email", "superintendent_phone",
    "treasurer_name", "treasurer_email", "treasurer_phone",
    "principal_name", "principal_email", "principal_phone"
  )

  existing_cols <- preferred_order[preferred_order %in% names(result)]
  result <- result |>
    dplyr::select(dplyr::all_of(existing_cols))

  result
}


# ==============================================================================
# Directory-specific cache functions
# ==============================================================================

#' Build cache file path for directory data
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return File path string
#' @keywords internal
build_cache_path_directory <- function(cache_type) {
  cache_dir <- get_cache_dir()
  file.path(cache_dir, paste0(cache_type, ".rds"))
}


#' Check if cached directory data exists
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @param max_age Maximum age in days (default 30). Set to Inf to ignore age.
#' @return Logical indicating if valid cache exists
#' @keywords internal
cache_exists_directory <- function(cache_type, max_age = 30) {
  cache_path <- build_cache_path_directory(cache_type)

  if (!file.exists(cache_path)) {
    return(FALSE)
  }

  # Check age
  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days <= max_age
}


#' Read directory data from cache
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return Cached data frame
#' @keywords internal
read_cache_directory <- function(cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  readRDS(cache_path)
}


#' Write directory data to cache
#'
#' @param data Data frame to cache
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return Invisibly returns the cache path
#' @keywords internal
write_cache_directory <- function(data, cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  cache_dir <- dirname(cache_path)

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  saveRDS(data, cache_path)
  invisible(cache_path)
}


#' Clear school directory cache
#'
#' Removes cached school directory data files.
#'
#' @return Invisibly returns the number of files removed
#' @export
#' @examples
#' \dontrun{
#' # Clear cached directory data
#' clear_directory_cache()
#' }
clear_directory_cache <- function() {
  cache_dir <- get_cache_dir()

  if (!dir.exists(cache_dir)) {
    message("Cache directory does not exist")
    return(invisible(0))
  }

  files <- list.files(cache_dir, pattern = "^directory_", full.names = TRUE)

  if (length(files) > 0) {
    # Use unlink() instead of file.remove() for better Windows compatibility
    unlink(files, recursive = FALSE, force = TRUE)
    message(paste("Removed", length(files), "cached directory file(s)"))
  } else {
    message("No cached directory files to remove")
  }

  invisible(length(files))
}
