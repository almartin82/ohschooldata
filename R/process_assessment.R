# ==============================================================================
# Assessment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw Ohio assessment data into a
# clean, standardized format.
#
# COLUMN NAME CHANGES BETWEEN YEARS:
# - 2019 and earlier: "Accelerated" proficiency level
# - 2021 and later: "Accomplished" proficiency level (same thing, renamed)
# - 2019: Column names use "2018-19" format
# - 2021+: Column names use "2020-2021" format
#
# ==============================================================================

#' Process raw achievement data
#'
#' Transforms raw achievement data into a standardized format with
#' consistent column names and data types.
#'
#' Handles column name differences between years:
#' - Pre-COVID (2019): "Accelerated" proficiency level, "2018-19" year format
#' - Post-COVID (2021+): "Accomplished" proficiency level, "2020-2021" year format
#'
#' @param df Raw data frame from get_raw_achievement()
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @export
#' @examples
#' \dontrun{
#' raw <- get_raw_achievement(2025)
#' processed <- process_achievement(raw, 2025)
#' }
process_achievement <- function(df, end_year) {

  cols <- names(df)

  # Helper function to find column by pattern (case-insensitive)
  find_col <- function(pattern) {
    matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
    if (length(matched) > 0) matched[1] else NULL
  }

  # Initialize result data frame
  result <- data.frame(
    end_year = rep(end_year, nrow(df)),
    stringsAsFactors = FALSE
  )

  # === IDENTIFIERS ===

  # Building IRN (6 digits)
  bldg_irn_col <- find_col("^Building IRN$")
  if (!is.null(bldg_irn_col)) {
    result$building_irn <- sprintf("%06d", as.integer(df[[bldg_irn_col]]))
  }

  # Building Name
  bldg_name_col <- find_col("^Building Name$")
  if (!is.null(bldg_name_col)) {
    result$building_name <- trimws(df[[bldg_name_col]])
  }

  # District IRN (6 digits)
  dist_irn_col <- find_col("^District IRN$")
  if (!is.null(dist_irn_col)) {
    result$district_irn <- sprintf("%06d", as.integer(df[[dist_irn_col]]))
  }

  # District Name
  dist_name_col <- find_col("^District Name$")
  if (!is.null(dist_name_col)) {
    result$district_name <- trimws(df[[dist_name_col]])
  }

  # County
  county_col <- find_col("^County$")
  if (!is.null(county_col)) {
    result$county <- trimws(df[[county_col]])
  }

  # Region
  region_col <- find_col("^Region$")
  if (!is.null(region_col)) {
    result$region <- trimws(df[[region_col]])
  }

  # === PERFORMANCE METRICS ===

  # Achievement Component Star Rating
  star_col <- find_col("^Achievement Component Star Rating$")
  if (!is.null(star_col)) {
    result$star_rating <- df[[star_col]]
  }

  # Performance Index Percent (column name includes year)
  # Try both old format (2018-19) and new format (2024-2025)
  pi_pct_col <- find_col("Performance Index Percent")
  if (!is.null(pi_pct_col)) {
    result$performance_index_pct <- safe_numeric(df[[pi_pct_col]])
  }

  # Performance Index Score
  pi_score_col <- find_col("Performance Index Score")
  if (!is.null(pi_score_col)) {
    result$performance_index_score <- safe_numeric(df[[pi_score_col]])
  }

  # === PROFICIENCY LEVELS ===
  # Note: "Accelerated" was renamed to "Accomplished" after COVID

  # Not Tested
  not_tested_col <- find_col("^Percent of Students Not Tested$")
  if (!is.null(not_tested_col)) {
    result$pct_not_tested <- safe_numeric(df[[not_tested_col]])
  }

  # Limited
  limited_col <- find_col("^Percent of Students Limited$")
  if (!is.null(limited_col)) {
    result$pct_limited <- safe_numeric(df[[limited_col]])
  }

  # Basic
  basic_col <- find_col("^Percent of Students Basic$")
  if (!is.null(basic_col)) {
    result$pct_basic <- safe_numeric(df[[basic_col]])
  }

  # Proficient
  proficient_col <- find_col("^Percent of Students Proficient$")
  if (!is.null(proficient_col)) {
    result$pct_proficient <- safe_numeric(df[[proficient_col]])
  }

  # Accomplished (post-COVID) or Accelerated (pre-COVID)
  accomplished_col <- find_col("^Percent of Students Accomplished$")
  accelerated_col <- find_col("^Percent of Students Accelerated$")
  if (!is.null(accomplished_col)) {
    result$pct_accomplished <- safe_numeric(df[[accomplished_col]])
  } else if (!is.null(accelerated_col)) {
    # Map "Accelerated" to "Accomplished" for consistency
    result$pct_accomplished <- safe_numeric(df[[accelerated_col]])
  }

  # Advanced
  advanced_col <- find_col("^Percent of Students Advanced$")
  if (!is.null(advanced_col)) {
    result$pct_advanced <- safe_numeric(df[[advanced_col]])
  }

  # Advanced Plus
  advanced_plus_col <- find_col("^Percent of Students Advanced Plus$")
  if (!is.null(advanced_plus_col)) {
    result$pct_advanced_plus <- safe_numeric(df[[advanced_plus_col]])
  }

  # === GIFTED DATA (available in some years) ===

  gifted_pi_col <- find_col("Gifted Performance Index")
  if (!is.null(gifted_pi_col)) {
    result$gifted_performance_index <- safe_numeric(df[[gifted_pi_col]])
  }

  result
}


#' Process raw gap closing data
#'
#' Transforms raw gap closing data into a standardized format with
#' consistent column names and data types.
#'
#' Gap closing data is at the building x subgroup level, with 10 subgroups
#' per building representing different student populations.
#'
#' @param df Raw data frame from get_raw_gap_closing()
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @export
#' @examples
#' \dontrun{
#' raw <- get_raw_gap_closing(2025)
#' processed <- process_gap_closing(raw, 2025)
#' }
process_gap_closing <- function(df, end_year) {

  cols <- names(df)

  # Helper function to find column by pattern (case-insensitive)
  find_col <- function(pattern) {
    matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
    if (length(matched) > 0) matched[1] else NULL
  }

  # Initialize result data frame
  result <- data.frame(
    end_year = rep(end_year, nrow(df)),
    stringsAsFactors = FALSE
  )

  # === IDENTIFIERS ===

  # Building IRN
  bldg_irn_col <- find_col("^Building IRN$")
  if (!is.null(bldg_irn_col)) {
    result$building_irn <- sprintf("%06d", as.integer(df[[bldg_irn_col]]))
  }

  # Building Name
  bldg_name_col <- find_col("^Building Name$")
  if (!is.null(bldg_name_col)) {
    result$building_name <- trimws(df[[bldg_name_col]])
  }

  # District IRN
  dist_irn_col <- find_col("^District IRN$")
  if (!is.null(dist_irn_col)) {
    result$district_irn <- sprintf("%06d", as.integer(df[[dist_irn_col]]))
  }

  # District Name
  dist_name_col <- find_col("^District Name$")
  if (!is.null(dist_name_col)) {
    result$district_name <- trimws(df[[dist_name_col]])
  }

  # County
  county_col <- find_col("^County$")
  if (!is.null(county_col)) {
    result$county <- trimws(df[[county_col]])
  }

  # === SUBGROUP ===

  disagg_col <- find_col("^Disaggregation$")
  if (!is.null(disagg_col)) {
    result$subgroup <- trimws(df[[disagg_col]])
  }

  # === PERFORMANCE METRICS ===

  # ELA Performance Index
  ela_pi_col <- find_col("^ELA Performance Index$")
  if (!is.null(ela_pi_col)) {
    result$ela_performance_index <- safe_numeric(df[[ela_pi_col]])
  }

  # Math Performance Index
  math_pi_col <- find_col("^Math Performance Index$")
  if (!is.null(math_pi_col)) {
    result$math_performance_index <- safe_numeric(df[[math_pi_col]])
  }

  # Gap Closing Percent
  gap_pct_col <- find_col("^Gap Closing Percent$")
  if (!is.null(gap_pct_col)) {
    result$gap_closing_pct <- safe_numeric(df[[gap_pct_col]])
  }

  # === PARTICIPATION RATES ===

  ela_part_col <- find_col("^ELA Participation Rate$")
  if (!is.null(ela_part_col)) {
    result$ela_participation_rate <- safe_numeric(df[[ela_part_col]])
  }

  math_part_col <- find_col("^Math Participation Rate$")
  if (!is.null(math_part_col)) {
    result$math_participation_rate <- safe_numeric(df[[math_part_col]])
  }

  # === CHRONIC ABSENTEEISM (if available) ===

  chronic_col <- find_col("Chronic Absenteeism")
  if (!is.null(chronic_col)) {
    result$chronic_absenteeism <- safe_numeric(df[[chronic_col]])
  }

  # === GRADUATION RATE (if available) ===

  grad_col <- find_col("Graduation Rate")
  if (!is.null(grad_col)) {
    result$graduation_rate <- safe_numeric(df[[grad_col]])
  }

  result
}


#' Standardize subgroup names
#'
#' Converts Ohio DOE subgroup names to a standardized format for
#' cross-year and cross-state comparisons.
#'
#' @param subgroup Character vector of subgroup names from Ohio data
#' @return Character vector of standardized subgroup names
#' @keywords internal
standardize_subgroup <- function(subgroup) {
  # Map Ohio DOE names to standardized names
  subgroup_map <- c(
    "All Students" = "all_students",
    "American Indian or Alaskan Native" = "native_american",
    "Asian or Pacific Islander" = "asian_pacific",
    "Black, Non-Hispanic" = "black",
    "Hispanic" = "hispanic",
    "Multiracial" = "multiracial",
    "White, Non-Hispanic" = "white",
    "Economic Disadvantage" = "economically_disadvantaged",
    "English Learner" = "english_learner",
    "Students with Disabilities" = "disability"
  )

  # Apply mapping, keeping original if not found
  result <- subgroup_map[subgroup]
  result[is.na(result)] <- tolower(gsub("[^a-zA-Z0-9]", "_", subgroup[is.na(result)]))
  result
}
