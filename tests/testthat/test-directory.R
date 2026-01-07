# ==============================================================================
# School Directory Tests
# ==============================================================================

test_that("fetch_directory returns valid data structure", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # Basic structure
  expect_s3_class(result, "data.frame")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 3000)  # Ohio has 3000+ schools/districts

  # Required columns
  required_cols <- c(
    "irn", "state_school_id", "state_district_id",
    "school_name", "district_name", "school_type",
    "org_type", "org_category", "grades_served",
    "status", "county", "address", "city", "state", "zip",
    "phone", "superintendent_name", "principal_name"
  )

  for (col in required_cols) {
    expect_true(col %in% names(result))
  }

  # State should always be "OH"
  expect_true(all(result$state == "OH", na.rm = TRUE))
})


test_that("fetch_directory has superintendent contact data", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # Should have superintendent data for districts
  districts <- result[result$org_category == "District", ]
  supt_count <- sum(!is.na(districts$superintendent_name))

  expect_gt(supt_count, 500)

  # At least some should have email
  supt_email_count <- sum(!is.na(districts$superintendent_email))
  expect_gt(supt_email_count, 400)
})


test_that("fetch_directory has principal contact data", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # Should have principal data for schools
  schools <- result[result$org_category == "School", ]
  prin_count <- sum(!is.na(schools$principal_name))

  expect_gt(prin_count, 1000)

  # At least some should have email
  prin_email_count <- sum(!is.na(schools$principal_email))
  expect_gt(prin_email_count, 500)
})


test_that("IRN format is valid", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # All IRNs should be 7 characters (6-digit IRN with = prefix)
  irn_lengths <- nchar(result$irn)
  expect_true(all(irn_lengths == 7, na.rm = TRUE))

  # IRNs should be character, not numeric (preserve leading zeros)
  expect_type(result$irn, "character")
  expect_type(result$state_school_id, "character")
  expect_type(result$state_district_id, "character")

  # Check for leading zeros after the = prefix (should exist for some IRNs)
  has_leading_zero <- grepl("^=0", result$irn)
  expect_gt(sum(has_leading_zero), 50)
})


test_that("Major districts are present in directory", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # Major Ohio districts with known IRNs
  major_districts <- c(
    "=043802",  # Columbus City Schools
    "=043786",  # Cleveland Municipal
    "=043752",  # Cincinnati Public Schools
    "=043489",  # Akron City
    "=044909"   # Toledo City
  )

  for (irn in major_districts) {
    district <- result[result$irn == irn, ]
    expect_equal(nrow(district), 1)
    expect_equal(district$org_category, "District")
  }

  # Columbus City should have superintendent data
  columbus <- result[result$irn == "=043802", ]
  expect_true(!is.na(columbus$superintendent_name) ||
              !is.na(columbus$superintendent_email))
})


test_that("Organization categories are valid", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # Should have multiple organization categories
  categories <- unique(result$org_category)
  expect_true("District" %in% categories)
  expect_true("School" %in% categories)
  expect_gt(length(categories), 2)

  # Count major categories
  district_count <- sum(result$org_category == "District", na.rm = TRUE)
  school_count <- sum(result$org_category == "School", na.rm = TRUE)

  expect_gt(district_count, 600)
  expect_gt(school_count, 3000)
})


test_that("fetch_directory tidy=FALSE returns raw data", {
  skip_on_cran()
  skip_if_offline()

  raw <- fetch_directory(tidy = FALSE, use_cache = TRUE)

  expect_s3_class(raw, "data.frame")

  # Raw data should have OEDS column names (all caps)
  expect_true("IRN" %in% names(raw) ||
              "ORGANIZATION NAME" %in% names(raw))
})


test_that("Cache functions work correctly", {
  skip_on_cran()
  skip_if_offline()

  # Clear cache first
  clear_directory_cache()

  # First call should download
  result1 <- fetch_directory(use_cache = TRUE)

  # Second call should use cache (faster)
  result2 <- fetch_directory(use_cache = TRUE)

  # Results should be identical
  expect_equal(nrow(result1), nrow(result2))
  expect_equal(names(result1), names(result2))

  # Clear cache again
  clear_directory_cache()
})


test_that("Data quality checks pass", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # No completely empty rows
  expect_true(all(rowSums(!is.na(result)) > 5))

  # School names should not be empty for active organizations
  active_orgs <- result[result$status == "Open", ]
  expect_true(all(!is.na(active_orgs$school_name)))

  # ZIP codes should be 5 digits (where present)
  valid_zips <- grepl("^\\d{5}$", result$zip[!is.na(result$zip)])
  expect_gt(sum(valid_zips), nrow(result) * 0.8)

  # Phone numbers should exist for most organizations
  phone_count <- sum(!is.na(result$phone))
  expect_gt(phone_count, nrow(result) * 0.7)
})


test_that("Grade span data is present", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # Schools should have grade span data
  schools <- result[result$org_category == "School", ]
  has_grades <- sum(!is.na(schools$grades_served))

  expect_gt(has_grades, nrow(schools) * 0.5)
})


test_that("School types are categorized", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # Schools should have school type classification
  schools <- result[result$org_category == "School" & result$status == "Open", ]
  has_type <- sum(!is.na(schools$school_type))

  expect_gt(has_type, nrow(schools) * 0.3)

  # Should have various school types
  types <- unique(schools$school_type[!is.na(schools$school_type)])
  expect_gt(length(types), 3)
})


test_that("County data is present", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # Should have county data for most records
  has_county <- sum(!is.na(result$county))
  expect_gt(has_county, nrow(result) * 0.9)

  # Should have all 88 Ohio counties represented
  counties <- unique(result$county[!is.na(result$county)])
  expect_gt(length(counties), 80)
})
