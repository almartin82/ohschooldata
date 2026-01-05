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
    expect_true(col %in% names(result),
                info = paste("Missing required column:", col))
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

  expect_gt(supt_count, 500,
            info = paste("Only", supt_count, "districts have superintendent names"))

  # At least some should have email
  supt_email_count <- sum(!is.na(districts$superintendent_email))
  expect_gt(supt_email_count, 400,
            info = paste("Only", supt_email_count, "districts have superintendent emails"))
})


test_that("fetch_directory has principal contact data", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # Should have principal data for schools
  schools <- result[result$org_category == "School", ]
  prin_count <- sum(!is.na(schools$principal_name))

  expect_gt(prin_count, 1000,
            info = paste("Only", prin_count, "schools have principal names"))

  # At least some should have email
  prin_email_count <- sum(!is.na(schools$principal_email))
  expect_gt(prin_email_count, 500,
            info = paste("Only", prin_email_count, "schools have principal emails"))
})


test_that("IRN format is valid", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # All IRNs should be 6 characters
  irn_lengths <- nchar(result$irn)
  expect_true(all(irn_lengths == 6, na.rm = TRUE),
              info = paste("Found IRNs with length:",
                          paste(unique(irn_lengths), collapse = ", ")))

  # IRNs should be character, not numeric (preserve leading zeros)
  expect_type(result$irn, "character")
  expect_type(result$state_school_id, "character")
  expect_type(result$state_district_id, "character")

  # Check for leading zeros (should exist for some IRNs)
  has_leading_zero <- grepl("^0", result$irn)
  expect_gt(sum(has_leading_zero), 50,
            info = "Expected some IRNs to have leading zeros")
})


test_that("Major districts are present in directory", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # Major Ohio districts with known IRNs
  major_districts <- c(
    "043802",  # Columbus City
    "043786",  # Cleveland Municipal
    "043752",  # Cincinnati City
    "043489",  # Akron City
    "044792"   # Toledo City
  )

  for (irn in major_districts) {
    district <- result[result$irn == irn, ]
    expect_equal(nrow(district), 1,
                 info = paste("District", irn, "not found or duplicated"))
    expect_equal(district$org_category, "District",
                 info = paste("IRN", irn, "is not categorized as District"))
  }

  # Columbus City should have superintendent data
  columbus <- result[result$irn == "043802", ]
  expect_true(!is.na(columbus$superintendent_name) ||
              !is.na(columbus$superintendent_email),
              info = "Columbus City should have superintendent contact info")
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

  expect_gt(district_count, 600,
            info = paste("Expected 600+ districts, found", district_count))
  expect_gt(school_count, 3000,
            info = paste("Expected 3000+ schools, found", school_count))
})


test_that("fetch_directory tidy=FALSE returns raw data", {
  skip_on_cran()
  skip_if_offline()

  raw <- fetch_directory(tidy = FALSE, use_cache = TRUE)

  expect_s3_class(raw, "data.frame")

  # Raw data should have OEDS column names (all caps)
  expect_true("IRN" %in% names(raw) ||
              "ORGANIZATION NAME" %in% names(raw),
              info = "Raw data should have OEDS-style column names")
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
  expect_true(all(rowSums(!is.na(result)) > 5),
              info = "Found rows with too many missing values")

  # School names should not be empty for active organizations
  active_orgs <- result[result$status == "Open", ]
  expect_true(all(!is.na(active_orgs$school_name)),
              info = "Found active organizations without names")

  # ZIP codes should be 5 digits (where present)
  valid_zips <- grepl("^\\d{5}$", result$zip[!is.na(result$zip)])
  expect_gt(sum(valid_zips), nrow(result) * 0.8,
            info = "Most ZIP codes should be 5-digit format")

  # Phone numbers should exist for most organizations
  phone_count <- sum(!is.na(result$phone))
  expect_gt(phone_count, nrow(result) * 0.7,
            info = paste("Only", phone_count, "of", nrow(result),
                        "organizations have phone numbers"))
})


test_that("Grade span data is present", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # Schools should have grade span data
  schools <- result[result$org_category == "School", ]
  has_grades <- sum(!is.na(schools$grades_served))

  expect_gt(has_grades, nrow(schools) * 0.5,
            info = paste("Only", has_grades, "of", nrow(schools),
                        "schools have grade span data"))
})


test_that("School types are categorized", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # Schools should have school type classification
  schools <- result[result$org_category == "School" & result$status == "Open", ]
  has_type <- sum(!is.na(schools$school_type))

  expect_gt(has_type, nrow(schools) * 0.3,
            info = paste("Only", has_type, "of", nrow(schools),
                        "schools have school type classification"))

  # Should have various school types
  types <- unique(schools$school_type[!is.na(schools$school_type)])
  expect_gt(length(types), 3,
            info = paste("Expected multiple school types, found:",
                        paste(types, collapse = ", ")))
})


test_that("County data is present", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(tidy = TRUE, use_cache = TRUE)

  # Should have county data for most records
  has_county <- sum(!is.na(result$county))
  expect_gt(has_county, nrow(result) * 0.9,
            info = paste("Only", has_county, "records have county data"))

  # Should have all 88 Ohio counties represented
  counties <- unique(result$county[!is.na(result$county)])
  expect_gt(length(counties), 80,
            info = paste("Expected ~88 counties, found", length(counties)))
})
