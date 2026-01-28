# ==============================================================================
# TDD Tests for Ohio Assessment Data Functions
# ==============================================================================
#
# These tests verify EACH STEP of the assessment data pipeline using LIVE network
# calls to the Ohio DOE Azure blob storage.
#
# Data Source:
#   Base URL: https://reportcardstorage.education.ohio.gov/data-download-{year}/
#   SAS Token: Valid until 2031
#   Files: {YY}-{YY}_Achievement_Building.xlsx, {YY}-{YY}_Gap_Closing_Building.xlsx
#
# Test Categories (following CLAUDE.md 8-category framework):
# 1. URL Availability - HTTP 200 checks with SAS token
# 2. File Download - Verify actual Excel file (not HTML error)
# 3. File Parsing - readxl succeeds with correct sheets
# 4. Column Structure - Expected columns exist per year format
# 5. fetch_assessment() - Main function works
# 6. Data Quality - No Inf/NaN, valid ranges
# 7. Value Verification - EXACT values from raw data
# 8. Output Fidelity - tidy=TRUE matches raw
#
# ==============================================================================

library(testthat)
library(httr)

# ==============================================================================
# Constants - SAS Token and URL Construction
# ==============================================================================

# SAS token valid until 2031-07-28
OH_SAS_TOKEN <- "sv=2020-08-04&ss=b&srt=sco&sp=rlx&se=2031-07-28T05:10:18Z&st=2021-07-27T21:10:18Z&spr=https&sig=nPOvW%2Br2caitHi%2F8WhYwU7xqalHo0dFrudeJq%2B%2Bmyuo%3D"

# Base URL pattern: https://reportcardstorage.education.ohio.gov/data-download-{year}/
# File pattern: {YY}-{YY}_Achievement_Building.xlsx (e.g., 24-25_Achievement_Building.xlsx)

#' Build Ohio assessment data URL
#'
#' @param end_year The end year (e.g., 2025 for 2024-25 school year)
#' @param file_type Either "achievement" or "gap_closing"
#' @return Full URL with SAS token
build_assessment_url <- function(end_year, file_type = "achievement") {
  # Convert end_year to file name format (e.g., 2025 -> "24-25")
  start_yy <- sprintf("%02d", (end_year - 1) %% 100)
  end_yy <- sprintf("%02d", end_year %% 100)
  year_range <- paste0(start_yy, "-", end_yy)

  # Build file name
  if (file_type == "achievement") {
    file_name <- paste0(year_range, "_Achievement_Building.xlsx")
  } else if (file_type == "gap_closing") {
    file_name <- paste0(year_range, "_Gap_Closing_Building.xlsx")
  } else {
    stop("file_type must be 'achievement' or 'gap_closing'")
  }

  # Build full URL
  base_url <- paste0("https://reportcardstorage.education.ohio.gov/data-download-", end_year, "/")
  paste0(base_url, file_name, "?", OH_SAS_TOKEN)
}

# ==============================================================================
# Known Entity IRNs (for testing)
# ==============================================================================

# District IRNs (verified from 2025 data)
IRN_COLUMBUS_CITY <- "043802"
IRN_CLEVELAND_MUNICIPAL <- "043786"
IRN_DUBLIN_CITY <- "047027"
IRN_CINCINNATI_PUBLIC <- "043752"

# Building IRNs (verified from 2025 data)
IRN_EASTGATE_ELEMENTARY <- "000435"       # Columbus City Schools District
IRN_STEVENSON_SCHOOL <- "000224"          # Cleveland Municipal
IRN_GLACIER_RIDGE_ELEMENTARY <- "008257"  # Dublin City
IRN_BOND_HILL_ACADEMY <- "003152"         # Cincinnati Public Schools

# ==============================================================================
# STEP 1: URL Construction Tests
# ==============================================================================

test_that("build_assessment_url constructs correct URLs", {
  # Test 2025 achievement URL
  url_2025 <- build_assessment_url(2025, "achievement")
  expect_true(grepl("data-download-2025", url_2025))
  expect_true(grepl("24-25_Achievement_Building.xlsx", url_2025))
  expect_true(grepl("sv=2020-08-04", url_2025))  # SAS token present

  # Test 2023 achievement URL
  url_2023 <- build_assessment_url(2023, "achievement")
  expect_true(grepl("data-download-2023", url_2023))
  expect_true(grepl("22-23_Achievement_Building.xlsx", url_2023))

  # Test 2019 achievement URL
  url_2019 <- build_assessment_url(2019, "achievement")
  expect_true(grepl("data-download-2019", url_2019))
  expect_true(grepl("18-19_Achievement_Building.xlsx", url_2019))

  # Test gap closing URL
  url_gap <- build_assessment_url(2025, "gap_closing")
  expect_true(grepl("24-25_Gap_Closing_Building.xlsx", url_gap))
})

test_that("build_assessment_url handles edge cases", {
  # 2020 data should not exist (COVID year)
  url_2020 <- build_assessment_url(2020, "achievement")
  expect_true(grepl("19-20_Achievement_Building.xlsx", url_2020))

  # 2018 is the first year available
  url_2018 <- build_assessment_url(2018, "achievement")
  expect_true(grepl("17-18_Achievement_Building.xlsx", url_2018))

  # Invalid file type should error
  expect_error(build_assessment_url(2025, "invalid"), "must be 'achievement' or 'gap_closing'")
})

# ==============================================================================
# STEP 2: URL Availability Tests (LIVE)
# ==============================================================================

test_that("Ohio DOE Azure blob storage is accessible with SAS token", {
  skip_if_offline()

  # Test 2025 achievement file URL
  url <- build_assessment_url(2025, "achievement")
  response <- HEAD(url, timeout(30))

  expect_equal(status_code(response), 200,
               info = "Ohio achievement data URL should return HTTP 200")

  # Verify content type is Excel
  content_type <- headers(response)$`content-type`
  expect_true(
    grepl("spreadsheet|excel|octet-stream", content_type, ignore.case = TRUE),
    info = paste("Expected Excel content type, got:", content_type)
  )
})

test_that("Gap Closing data URL is accessible", {
  skip_if_offline()

  url <- build_assessment_url(2025, "gap_closing")
  response <- HEAD(url, timeout(30))

  expect_equal(status_code(response), 200,
               info = "Ohio Gap Closing data URL should return HTTP 200")
})

test_that("Multiple years are accessible", {
  skip_if_offline()

  # Test a few representative years (not 2020 - COVID)
  test_years <- c(2025, 2023, 2019)

  for (year in test_years) {
    url <- build_assessment_url(year, "achievement")
    response <- HEAD(url, timeout(30))

    expect_equal(status_code(response), 200,
                 info = paste("Year", year, "should be accessible"))
  }
})

test_that("2020 COVID year returns 404 as expected", {
  skip_if_offline()

  url <- build_assessment_url(2020, "achievement")
  response <- HEAD(url, timeout(30))

  # 2020 data doesn't exist due to COVID - should return 404
  expect_equal(status_code(response), 404,
               info = "2020 COVID year should not have assessment data")
})

# ==============================================================================
# STEP 3: File Download Tests (LIVE)
# ==============================================================================

test_that("Can download achievement data file", {
  skip_if_offline()

  url <- build_assessment_url(2025, "achievement")

  # Download to temp file
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))

  expect_equal(status_code(response), 200)
  expect_true(file.exists(temp_file))
  # File should be > 100KB (not an error page)
  expect_gt(file.size(temp_file), 100000)

  # Verify it's a valid Excel file (check magic bytes)
  con <- file(temp_file, "rb")
  magic <- readBin(con, "raw", 4)
  close(con)

  # ZIP/XLSX files start with PK (50 4B)
  expect_equal(magic[1:2], as.raw(c(0x50, 0x4B)),
               info = "File should be a valid XLSX (ZIP) file")
})

# ==============================================================================
# STEP 4: File Parsing Tests (LIVE)
# ==============================================================================

test_that("Can parse 2025 achievement Excel file", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  # Download
  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  # Parse with readxl
  library(readxl)
  sheets <- excel_sheets(temp_file)

  # 2025 should have these sheets
  expect_true("Performance_Index" %in% sheets)
  expect_true("Report_Only_Indicators" %in% sheets)

  # Read Performance_Index
  data <- read_excel(temp_file, sheet = "Performance_Index")
  expect_true(is.data.frame(data))
  # Should have > 3000 buildings
  expect_gt(nrow(data), 3000)
})

test_that("Can parse 2019 achievement Excel file (pre-COVID format)", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2019, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  sheets <- excel_sheets(temp_file)

  # 2019 uses different sheet names
  expect_true("Performance_Index" %in% sheets)
  # 2019 uses 'Performance_Indicators' not 'Report_Only_Indicators'
  expect_true("Performance_Indicators" %in% sheets)

  data <- read_excel(temp_file, sheet = "Performance_Index")
  # Should have > 3000 buildings
  expect_gt(nrow(data), 3000)
})

test_that("Can parse Gap Closing Excel file", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "gap_closing")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  sheets <- excel_sheets(temp_file)

  # Should have 'Gap Closing' sheet (with space)
  expect_true("Gap Closing" %in% sheets)

  data <- read_excel(temp_file, sheet = "Gap Closing")
  # Gap Closing should have > 30000 rows (buildings x subgroups)
  expect_gt(nrow(data), 30000)
})

# ==============================================================================
# STEP 5: Column Structure Tests (LIVE)
# ==============================================================================

test_that("2025 Performance_Index has expected columns", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  data <- read_excel(temp_file, sheet = "Performance_Index")

  # Required identification columns
  expect_true("Building IRN" %in% names(data))
  expect_true("Building Name" %in% names(data))
  expect_true("District IRN" %in% names(data))
  expect_true("District Name" %in% names(data))
  expect_true("County" %in% names(data))
  expect_true("Region" %in% names(data))

  # Performance metrics
  expect_true("Achievement Component Star Rating" %in% names(data))
  expect_true("Performance Index Percent 2024-2025" %in% names(data))
  expect_true("Performance Index Score 2024-2025" %in% names(data))

  # Proficiency level columns
  expect_true("Percent of Students Not Tested" %in% names(data))
  expect_true("Percent of Students Limited" %in% names(data))
  expect_true("Percent of Students Basic" %in% names(data))
  expect_true("Percent of Students Proficient" %in% names(data))
  expect_true("Percent of Students Accomplished" %in% names(data))  # New name in 2025
  expect_true("Percent of Students Advanced" %in% names(data))
  expect_true("Percent of Students Advanced Plus" %in% names(data))
})

test_that("2019 Performance_Index has pre-COVID column names", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2019, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  data <- read_excel(temp_file, sheet = "Performance_Index")

  # 2019 used "Accelerated" not "Accomplished"
  expect_true("Percent of Students Accelerated" %in% names(data))
  # 2019 should NOT have 'Accomplished' (that's post-COVID)
  expect_false("Percent of Students Accomplished" %in% names(data))

  # 2019 uses different year format in column names
  expect_true("Performance Index Score 2018-19" %in% names(data))
  expect_true("Performance Index Percent 2018-19" %in% names(data))

  # 2019 has Gifted data (not present in newer years in Performance_Index)
  expect_true("Gifted Performance Index Score 2018-19" %in% names(data))
})

test_that("2025 Report_Only_Indicators has subject-level data", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  data <- read_excel(temp_file, sheet = "Report_Only_Indicators")

  # Identification columns
  expect_true("Building IRN" %in% names(data))
  expect_true("District Name" %in% names(data))

  # Subject-grade columns (ELA and Math for grades 3-8)
  expect_true("3rd Grade English Language Arts 2024-2025 Percent Proficient or above - Building" %in% names(data))
  expect_true("3rd Grade Math 2024-2025 Percent Proficient or above - Building" %in% names(data))
  expect_true("8th Grade English Language Arts 2024-2025 Percent Proficient or above - Building" %in% names(data))
  expect_true("8th Grade Math 2024-2025 Percent Proficient or above - Building" %in% names(data))

  # High school subjects
  expect_true("High School Algebra I 2024-2025 Percent Proficient or above - Building" %in% names(data))
  expect_true("High School Biology 2024-2025 Percent Proficient or above - Building" %in% names(data))

  # State reference values
  expect_true("3rd Grade English Language Arts 2024-2025 Percent Proficient or above - State" %in% names(data))
})

test_that("Gap Closing has expected columns", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "gap_closing")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  data <- read_excel(temp_file, sheet = "Gap Closing")

  # Required columns
  expect_true("Building IRN" %in% names(data))
  expect_true("Building Name" %in% names(data))
  expect_true("Disaggregation" %in% names(data))

  # Performance metrics
  expect_true("ELA Performance Index" %in% names(data))
  expect_true("Math Performance Index" %in% names(data))
  expect_true("Gap Closing Percent" %in% names(data))

  # Participation data
  expect_true("ELA Participation Rate" %in% names(data))
  expect_true("Math Participation Rate" %in% names(data))
})

# ==============================================================================
# STEP 6: Data Quality Tests (LIVE)
# ==============================================================================

test_that("Performance Index values are in valid range", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  data <- read_excel(temp_file, sheet = "Performance_Index")

  # Convert to numeric (they're stored as text)
  pi_pct <- suppressWarnings(as.numeric(data$`Performance Index Percent 2024-2025`))
  pi_pct <- pi_pct[!is.na(pi_pct)]

  # Performance Index Percent can exceed 100% (high-performing schools)
  # Based on 2025 data: min=14.7, max=105
  expect_true(all(pi_pct >= 0 & pi_pct <= 110, na.rm = TRUE))

  # No Inf or NaN
  expect_false(any(is.infinite(pi_pct)))
  expect_false(any(is.nan(pi_pct)))
})

test_that("Proficiency percentages sum to approximately 100", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  library(dplyr)

  data <- read_excel(temp_file, sheet = "Performance_Index")

  # Convert proficiency columns to numeric
  prof_cols <- c("Percent of Students Not Tested", "Percent of Students Limited",
                 "Percent of Students Basic", "Percent of Students Proficient",
                 "Percent of Students Accomplished", "Percent of Students Advanced",
                 "Percent of Students Advanced Plus")

  # Calculate sum for each row
  prof_data <- data %>%
    select(all_of(prof_cols)) %>%
    mutate(across(everything(), ~suppressWarnings(as.numeric(.)))) %>%
    rowwise() %>%
    mutate(total = sum(c_across(everything()), na.rm = TRUE)) %>%
    ungroup() %>%
    filter(total > 0)  # Exclude rows with no data

  # Should sum close to 100 (allowing for rounding)
  # Proficiency levels should sum to ~100%
  expect_true(all(prof_data$total >= 99 & prof_data$total <= 101, na.rm = TRUE))
})

# ==============================================================================
# STEP 7: EXACT Value Verification Tests (LIVE)
# ==============================================================================
# These values were extracted directly from the raw Ohio data files

test_that("Glacier Ridge Elementary (Dublin City) has correct 2025 values", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  library(dplyr)

  data <- read_excel(temp_file, sheet = "Performance_Index")

  # Find Glacier Ridge Elementary (Building IRN 008257)
  glacier <- data %>%
    filter(`Building IRN` == IRN_GLACIER_RIDGE_ELEMENTARY)

  # Should find exactly one Glacier Ridge Elementary
  expect_equal(nrow(glacier), 1)

  # Verify exact values from raw data (extracted 2025-01-24)
  # Source: 24-25_Achievement_Building.xlsx, Performance_Index sheet
  expect_equal(glacier$`Building Name`, "Glacier Ridge Elementary")
  expect_equal(glacier$`District IRN`, IRN_DUBLIN_CITY)
  expect_equal(glacier$`District Name`, "Dublin City")
  expect_equal(glacier$`Performance Index Percent 2024-2025`, "94.3")
  expect_equal(glacier$`Performance Index Score 2024-2025`, "104.9")
  expect_equal(glacier$`Percent of Students Proficient`, "14.4")
  expect_equal(glacier$`Percent of Students Advanced`, "47.3")
})

test_that("Eastgate Elementary (Columbus City) has correct 2025 values", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  library(dplyr)

  data <- read_excel(temp_file, sheet = "Performance_Index")

  eastgate <- data %>%
    filter(`Building IRN` == IRN_EASTGATE_ELEMENTARY)

  expect_equal(nrow(eastgate), 1)

  # Verify exact values from raw data
  # Source: 24-25_Achievement_Building.xlsx, Performance_Index sheet
  expect_equal(eastgate$`Building Name`, "Eastgate Elementary School")
  expect_equal(eastgate$`District IRN`, IRN_COLUMBUS_CITY)
  expect_equal(eastgate$`District Name`, "Columbus City Schools District")
  expect_equal(eastgate$`Performance Index Percent 2024-2025`, "37.2")
  expect_equal(eastgate$`Performance Index Score 2024-2025`, "41.4")
  expect_equal(eastgate$`Percent of Students Proficient`, "4.5")
  expect_equal(eastgate$`Percent of Students Advanced`, "1.7")
})

test_that("Bond Hill Academy (Cincinnati Public) has correct 2025 values", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  library(dplyr)

  data <- read_excel(temp_file, sheet = "Performance_Index")

  bondhill <- data %>%
    filter(`Building IRN` == IRN_BOND_HILL_ACADEMY)

  expect_equal(nrow(bondhill), 1)

  # Verify exact values from raw data
  expect_equal(bondhill$`Building Name`, "Bond Hill Academy")
  expect_equal(bondhill$`District IRN`, IRN_CINCINNATI_PUBLIC)
  expect_equal(bondhill$`District Name`, "Cincinnati Public Schools")
  expect_equal(bondhill$`Performance Index Percent 2024-2025`, "51.2")
  expect_equal(bondhill$`Performance Index Score 2024-2025`, "57.0")
  expect_equal(bondhill$`Percent of Students Proficient`, "16.7")
  expect_equal(bondhill$`Percent of Students Advanced`, "4.6")
})

test_that("Adlai Stevenson School (Cleveland Municipal) has correct 2025 values", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  library(dplyr)

  data <- read_excel(temp_file, sheet = "Performance_Index")

  stevenson <- data %>%
    filter(`Building IRN` == IRN_STEVENSON_SCHOOL)

  expect_equal(nrow(stevenson), 1)

  # Verify exact values from raw data
  expect_equal(stevenson$`Building Name`, "Adlai Stevenson School")
  expect_equal(stevenson$`District IRN`, IRN_CLEVELAND_MUNICIPAL)
  expect_equal(stevenson$`District Name`, "Cleveland Municipal")
  expect_equal(stevenson$`Performance Index Percent 2024-2025`, "46.0")
  expect_equal(stevenson$`Performance Index Score 2024-2025`, "51.2")
  expect_equal(stevenson$`Percent of Students Proficient`, "13.2")
  expect_equal(stevenson$`Percent of Students Advanced`, "1.1")
})

test_that("Subject-level data has correct 2025 state values", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)

  data <- read_excel(temp_file, sheet = "Report_Only_Indicators")

  # State values are repeated in every row, get from first row
  first_row <- data[1, ]

  # Verify exact state-level values from raw data
  # Source: 24-25_Achievement_Building.xlsx, Report_Only_Indicators sheet
  # State 3rd Grade ELA proficiency should be 61.3%
  expect_equal(
    first_row$`3rd Grade English Language Arts 2024-2025 Percent Proficient or above - State`,
    "61.3"
  )
  # State 3rd Grade Math proficiency should be 64.4%
  expect_equal(
    first_row$`3rd Grade Math 2024-2025 Percent Proficient or above - State`,
    "64.4"
  )
  # State 4th Grade ELA proficiency should be 61.9%
  expect_equal(
    first_row$`4th Grade English Language Arts 2024-2025 Percent Proficient or above - State`,
    "61.9"
  )
  # State 4th Grade Math proficiency should be 69.1%
  expect_equal(
    first_row$`4th Grade Math 2024-2025 Percent Proficient or above - State`,
    "69.1"
  )
})

test_that("Eastgate Elementary has correct subject-level 2025 values", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  library(dplyr)

  data <- read_excel(temp_file, sheet = "Report_Only_Indicators")

  eastgate <- data %>%
    filter(`Building IRN` == IRN_EASTGATE_ELEMENTARY)

  expect_equal(nrow(eastgate), 1)

  # Verify exact subject-level values from raw data
  # Source: 24-25_Achievement_Building.xlsx, Report_Only_Indicators sheet
  expect_equal(
    eastgate$`3rd Grade English Language Arts 2024-2025 Percent Proficient or above - Building`,
    "9.7"
  )
  expect_equal(
    eastgate$`3rd Grade Math 2024-2025 Percent Proficient or above - Building`,
    "10.0"
  )
  expect_equal(
    eastgate$`4th Grade English Language Arts 2024-2025 Percent Proficient or above - Building`,
    "14.3"
  )
  expect_equal(
    eastgate$`4th Grade Math 2024-2025 Percent Proficient or above - Building`,
    "13.0"
  )
})

test_that("Glacier Ridge Elementary has correct subject-level 2025 values", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  library(dplyr)

  data <- read_excel(temp_file, sheet = "Report_Only_Indicators")

  glacier <- data %>%
    filter(`Building IRN` == IRN_GLACIER_RIDGE_ELEMENTARY)

  expect_equal(nrow(glacier), 1)

  # Verify exact subject-level values from raw data
  # Source: 24-25_Achievement_Building.xlsx, Report_Only_Indicators sheet
  expect_equal(
    glacier$`3rd Grade English Language Arts 2024-2025 Percent Proficient or above - Building`,
    "78.4"
  )
  expect_equal(
    glacier$`3rd Grade Math 2024-2025 Percent Proficient or above - Building`,
    "83.5"
  )
  expect_equal(
    glacier$`4th Grade English Language Arts 2024-2025 Percent Proficient or above - Building`,
    "92.2"
  )
  expect_equal(
    glacier$`4th Grade Math 2024-2025 Percent Proficient or above - Building`,
    "95.6"
  )
})

test_that("Gap Closing data has correct 2025 values", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "gap_closing")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  library(dplyr)

  data <- read_excel(temp_file, sheet = "Gap Closing")

  # Check Glacier Ridge All Students
  glacier_gap <- data %>%
    filter(`Building IRN` == IRN_GLACIER_RIDGE_ELEMENTARY,
           Disaggregation == "All Students")

  expect_equal(nrow(glacier_gap), 1)

  # Verify exact values from raw data
  # Source: 24-25_Gap_Closing_Building.xlsx, Gap Closing sheet
  expect_equal(glacier_gap$`ELA Performance Index`, "105")
  expect_equal(glacier_gap$`Math Performance Index`, "106.036")
  expect_equal(glacier_gap$`Gap Closing Percent`, "69.4")

  # Check Eastgate All Students
  eastgate_gap <- data %>%
    filter(`Building IRN` == IRN_EASTGATE_ELEMENTARY,
           Disaggregation == "All Students")

  expect_equal(nrow(eastgate_gap), 1)
  expect_equal(eastgate_gap$`ELA Performance Index`, "44.416")
  expect_equal(eastgate_gap$`Math Performance Index`, "38.701")
  expect_equal(eastgate_gap$`Gap Closing Percent`, "0")
})

test_that("Gap Closing has correct subgroup disaggregations", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "gap_closing")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)
  library(dplyr)

  data <- read_excel(temp_file, sheet = "Gap Closing")

  # Check all subgroups for Eastgate
  eastgate_subgroups <- data %>%
    filter(`Building IRN` == IRN_EASTGATE_ELEMENTARY) %>%
    pull(Disaggregation)

  # Expected 10 subgroups
  expected_subgroups <- c(
    "All Students",
    "American Indian or Alaskan Native",
    "Asian or Pacific Islander",
    "Black, Non-Hispanic",
    "Economic Disadvantage",
    "English Learner",
    "Hispanic",
    "Multiracial",
    "Students with Disabilities",
    "White, Non-Hispanic"
  )

  expect_setequal(eastgate_subgroups, expected_subgroups)
  expect_equal(length(eastgate_subgroups), 10)
})

# ==============================================================================
# STEP 8: Cross-Year Consistency Tests (LIVE)
# ==============================================================================

test_that("Glacier Ridge data is consistent across years", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  library(readxl)
  library(dplyr)

  results <- list()

  for (year in c(2025, 2023, 2019)) {
    url <- build_assessment_url(year, "achievement")
    temp_file <- tempfile(fileext = ".xlsx")

    response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
    if (status_code(response) != 200) next

    data <- read_excel(temp_file, sheet = "Performance_Index")
    glacier <- data %>% filter(`Building IRN` == IRN_GLACIER_RIDGE_ELEMENTARY)

    if (nrow(glacier) == 1) {
      results[[as.character(year)]] <- glacier
    }

    unlink(temp_file)
  }

  # Should have Glacier Ridge data for at least 2 years
  expect_gte(length(results), 2)

  # Building name should be consistent
  if (length(results) >= 2) {
    names_match <- sapply(results, function(x) x$`Building Name`)
    # Building name should be consistent across years
    expect_true(all(names_match == "Glacier Ridge Elementary"))
  }

  # Verify 2023 exact value (from raw data)
  if ("2023" %in% names(results)) {
    expect_equal(results[["2023"]]$`Performance Index Percent 2022-2023`, "96.3")
    expect_equal(results[["2023"]]$`Performance Index Score 2022-2023`, "106.2")
  }

  # Verify 2019 exact value (from raw data)
  if ("2019" %in% names(results)) {
    expect_equal(results[["2019"]]$`Performance Index Percent 2018-19`, "90.5")
    expect_equal(results[["2019"]]$`Performance Index Score 2018-19`, "108.638")
  }
})

test_that("Eastgate Elementary data is consistent across years", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  library(readxl)
  library(dplyr)

  results <- list()

  for (year in c(2025, 2019)) {
    url <- build_assessment_url(year, "achievement")
    temp_file <- tempfile(fileext = ".xlsx")

    response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
    if (status_code(response) != 200) next

    data <- read_excel(temp_file, sheet = "Performance_Index")
    eastgate <- data %>% filter(`Building IRN` == IRN_EASTGATE_ELEMENTARY)

    if (nrow(eastgate) == 1) {
      results[[as.character(year)]] <- eastgate
    }

    unlink(temp_file)
  }

  expect_gte(length(results), 1)

  # Verify 2019 exact values (pre-COVID, from raw data)
  if ("2019" %in% names(results)) {
    # Note: District name was slightly different in 2019 (singular 'School')
    expect_equal(results[["2019"]]$`District Name`, "Columbus City School District")
    expect_equal(results[["2019"]]$`Performance Index Percent 2018-19`, "46")
    expect_equal(results[["2019"]]$`Performance Index Score 2018-19`, "55.188")
    expect_equal(results[["2019"]]$`Percent of Students Proficient`, "14.3")
    expect_equal(results[["2019"]]$`Percent of Students Advanced`, "4.1")
  }
})

# ==============================================================================
# STEP 9: Aggregate Statistics Tests (LIVE)
# ==============================================================================

test_that("2025 data has expected building count", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)

  data <- read_excel(temp_file, sheet = "Performance_Index")

  # Should have over 3000 buildings
  expect_gt(nrow(data), 3000)
  # 2025 data should have exactly 3318 buildings (verified count)
  expect_equal(nrow(data), 3318)
})

test_that("2025 data has expected district count", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "achievement")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)

  data <- read_excel(temp_file, sheet = "Performance_Index")

  unique_districts <- length(unique(data$`District IRN`))

  # Should have around 941 unique districts (verified from raw data)
  expect_gt(unique_districts, 900)
  # 2025 data should have 941 unique districts
  expect_equal(unique_districts, 941)
})

test_that("Gap Closing has expected row count (buildings x subgroups)", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- build_assessment_url(2025, "gap_closing")
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- GET(url, write_disk(temp_file, overwrite = TRUE), timeout(120))
  skip_if(status_code(response) != 200, "Could not download file")

  library(readxl)

  data <- read_excel(temp_file, sheet = "Gap Closing")

  # 3318 buildings x 10 subgroups = 33180 rows
  expect_gt(nrow(data), 30000)
  # Gap Closing should have 33180 rows (3318 buildings x 10 subgroups)
  expect_equal(nrow(data), 33180)
})

# ==============================================================================
# Placeholder for fetch_assessment() function tests
# ==============================================================================
# These tests will be enabled once the fetch_assessment() function is implemented

test_that("fetch_assessment returns data", {
  skip_if_offline()

  # Test achievement data (tidy format)
  achieve <- fetch_assessment(2025, type = "achievement", tidy = TRUE, use_cache = FALSE)

  expect_true(is.data.frame(achieve))
  expect_gt(nrow(achieve), 0)
  expect_true("end_year" %in% names(achieve))
  expect_true("building_irn" %in% names(achieve))
  expect_true("proficiency_level" %in% names(achieve))
  expect_true("pct" %in% names(achieve))

  # Test wide format
  achieve_wide <- fetch_assessment(2025, type = "achievement", tidy = FALSE, use_cache = FALSE)
  expect_true(is.data.frame(achieve_wide))
  expect_true("pct_proficient" %in% names(achieve_wide))

  # Test gap closing data
  gap <- fetch_assessment(2025, type = "gap_closing", tidy = TRUE, use_cache = FALSE)
  expect_true(is.data.frame(gap))
  expect_true("subgroup" %in% names(gap))
  expect_true("gap_closing_pct" %in% names(gap))
})

test_that("list_assessment_years returns valid range", {
  years <- list_assessment_years()

  # Returns integer vector

  expect_true(is.numeric(years))

  # 2020 is NOT included (COVID year)
  expect_false(2020 %in% years)

  # 2018 is the minimum year
  expect_equal(min(years), 2018)

  # 2025 is the current maximum
  expect_equal(max(years), 2025)

  # All expected years are present (except 2020)
  expected <- c(2018, 2019, 2021, 2022, 2023, 2024, 2025)
  expect_setequal(years, expected)
})

test_that("list_assessment_types returns valid types", {
  types <- list_assessment_types()

  expect_equal(length(types), 2)
  expect_true("achievement" %in% types)
  expect_true("gap_closing" %in% types)
})

test_that("build_assessment_url is exported and works", {
  # Test that the package exports build_assessment_url
  url <- ohschooldata::build_assessment_url(2025, "achievement")

  expect_true(grepl("data-download-2025", url))
  expect_true(grepl("24-25_Achievement_Building.xlsx", url))
  expect_true(grepl("sv=2020-08-04", url))  # SAS token present
})
