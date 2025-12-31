# ==============================================================================
# Tests for Ohio Enrollment Data Functions
# ==============================================================================

# --- IRN Functions ---

test_that("is_valid_irn validates correctly", {
  # Valid IRNs
  expect_true(is_valid_irn("043752"))
  expect_true(is_valid_irn("000001"))
  expect_true(is_valid_irn("999999"))

  # Invalid IRNs
  expect_false(is_valid_irn("12345"))    # Only 5 digits
  expect_false(is_valid_irn("1234567"))  # 7 digits
  expect_false(is_valid_irn("12345a"))   # Contains letter
  expect_false(is_valid_irn(""))         # Empty
  expect_false(is_valid_irn(NA))         # NA
})

test_that("format_irn pads with zeros", {
  expect_equal(format_irn(43752), "043752")
  expect_equal(format_irn("43752"), "043752")
  expect_equal(format_irn(1), "000001")
  expect_equal(format_irn(999999), "999999")
})


# --- Safe Numeric Conversion ---

test_that("safe_numeric handles various inputs", {
  # Normal numbers
  expect_equal(safe_numeric("123"), 123)
  expect_equal(safe_numeric("1,234"), 1234)
  expect_equal(safe_numeric("  456  "), 456)

  # Suppression markers should return NA
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric("NC")))
  expect_true(is.na(safe_numeric("<10")))
  expect_true(is.na(safe_numeric("N/A")))
  expect_true(is.na(safe_numeric("-")))
})


# --- Year Availability ---

test_that("list_enr_years returns valid range", {
  years <- list_enr_years()

  expect_true(is.integer(years) || is.numeric(years))
  # Data goes back to 2007
  expect_true(min(years) >= 2007)
  expect_equal(min(years), 2007)
  expect_true(max(years) <= as.integer(format(Sys.Date(), "%Y")) + 1)
  expect_true(length(years) > 0)
  # Should have at least 15+ years of data available
  expect_true(length(years) >= 15)
})


# --- Cache Functions ---

test_that("cache directory is created correctly", {
  cache_dir <- get_cache_dir()

  expect_true(is.character(cache_dir))
  expect_true(grepl("ohschooldata", cache_dir))
})

test_that("cache path is generated correctly", {
  path <- get_cache_path(2024, "tidy")

  expect_true(grepl("enr_tidy_2024\\.rds$", path))
})


# --- Data Processing Tests ---
# These tests use mock data to test processing logic without network calls

test_that("process_enr_modern handles basic data frame", {
  # Create mock raw data
  mock_data <- data.frame(
    `District IRN` = c(43752, 43786),
    `District Name` = c("Columbus City", "Westerville City"),
    `Building IRN` = c(NA, NA),
    `Building Name` = c(NA, NA),
    County = c("Franklin", "Franklin"),
    `Total Enrollment` = c(50000, 15000),
    entity_type = c("District", "District"),
    end_year = c(2024, 2024),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  result <- process_enr_modern(mock_data, 2024)

  expect_true(is.data.frame(result))
  expect_true("district_irn" %in% names(result))
  expect_true("enrollment_total" %in% names(result))
  expect_equal(nrow(result), 2)
})

test_that("tidy_enr converts wide to long format", {
  # Create mock processed data
  mock_processed <- data.frame(
    end_year = 2024,
    district_irn = "043752",
    building_irn = NA_character_,
    district_name = "Columbus City",
    building_name = NA_character_,
    entity_type = "District",
    county = "Franklin",
    enrollment_total = 50000,
    white = 15000,
    black = 20000,
    hispanic = 10000,
    stringsAsFactors = FALSE
  )

  result <- tidy_enr(mock_processed)

  expect_true(is.data.frame(result))
  expect_true("subgroup" %in% names(result))
  expect_true("n_students" %in% names(result))
  expect_true("grade_level" %in% names(result))

  # Should have total_enrollment and demographic subgroups
  expect_true("total_enrollment" %in% result$subgroup)
  expect_true("white" %in% result$subgroup)
  expect_true("black" %in% result$subgroup)
  expect_true("hispanic" %in% result$subgroup)
})

test_that("id_enr_aggs adds correct flags", {
  # Create mock tidy data
  mock_tidy <- data.frame(
    end_year = c(2024, 2024, 2024),
    district_irn = c("043752", "043752", NA),
    building_irn = c(NA, "043001", NA),
    district_name = c("Columbus City", "Columbus City", NA),
    building_name = c(NA, "Test School", NA),
    entity_type = c("District", "Building", "State"),
    county = c("Franklin", "Franklin", NA),
    district_type = c("City", "City", NA),
    grade_level = c("TOTAL", "TOTAL", "TOTAL"),
    subgroup = c("total_enrollment", "total_enrollment", "total_enrollment"),
    n_students = c(50000, 500, 1700000),
    pct = c(1.0, 1.0, 1.0),
    stringsAsFactors = FALSE
  )

  result <- id_enr_aggs(mock_tidy)

  expect_true("is_state" %in% names(result))
  expect_true("is_district" %in% names(result))
  expect_true("is_building" %in% names(result))
  expect_true("is_community_school" %in% names(result))
  expect_true("is_jvsd" %in% names(result))

  # Check correct classification
  expect_true(result$is_district[result$entity_type == "District"])
  expect_true(result$is_building[result$entity_type == "Building"])
})


# --- Integration Tests (require network) ---
# These are wrapped in skip_on_cran() and skip_if_offline()

test_that("fetch_enr returns valid data", {
  skip_on_cran()
  skip_if_offline()

  # Try to fetch a recent year
  result <- tryCatch(
    fetch_enr(2023, use_cache = FALSE),
    error = function(e) NULL
  )

  # Skip if we couldn't download
  skip_if(is.null(result), "Could not download enrollment data")

  expect_true(is.data.frame(result))
  expect_true(nrow(result) > 0)
  expect_true("district_irn" %in% names(result))
  expect_true("n_students" %in% names(result))
})

test_that("fetch_enr validates year parameter", {
  # Year must be 2007 or later (minimum supported year)
  expect_error(fetch_enr(2000), "2007 or later")
  expect_error(fetch_enr(2006), "2007 or later")
})

# --- Legacy data processing tests ---

test_that("process_enr_legacy handles basic data frame", {
  # Create mock legacy raw data (simulating 2014 format)
  mock_data <- data.frame(
    `School IRN` = c(43001, 43002),
    `School Name` = c("Elementary School", "High School"),
    `District IRN` = c(43752, 43752),
    `District Name` = c("Columbus City", "Columbus City"),
    County = c("Franklin", "Franklin"),
    K = c(100, NA),
    `1` = c(95, NA),
    `2` = c(90, NA),
    `9` = c(NA, 200),
    `10` = c(NA, 195),
    `11` = c(NA, 190),
    `12` = c(NA, 180),
    Total = c(500, 800),
    entity_type = c("Building", "Building"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  result <- process_enr_legacy(mock_data, 2014)

  expect_true(is.data.frame(result))
  expect_true("building_irn" %in% names(result))
  expect_true("district_irn" %in% names(result))
  expect_true("enrollment_total" %in% names(result))
  expect_equal(nrow(result), 2)
  # Check grade parsing
  expect_true("grade_k" %in% names(result) || "grade_09" %in% names(result))
})
