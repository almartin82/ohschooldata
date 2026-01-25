# ==============================================================================
# Assessment Data Tidying Functions
# ==============================================================================
#
# This file contains functions for transforming assessment data from wide
# format to long (tidy) format.
#
# ==============================================================================

#' Tidy achievement data
#'
#' Transforms wide achievement data to long format with proficiency_level column.
#' Each row represents a single observation (building + proficiency level).
#'
#' @param df A processed data.frame from process_achievement()
#' @return A long data.frame of tidied achievement data
#' @export
#' @examples
#' \dontrun{
#' raw <- get_raw_achievement(2025)
#' processed <- process_achievement(raw, 2025)
#' tidy <- tidy_achievement(processed)
#' }
tidy_achievement <- function(df) {

  # Invariant columns (identifiers that stay the same)
  invariants <- c(
    "end_year", "building_irn", "building_name",
    "district_irn", "district_name",
    "county", "region",
    "star_rating", "performance_index_pct", "performance_index_score"
  )
  invariants <- invariants[invariants %in% names(df)]

  # Proficiency level columns to pivot
  prof_cols <- c(
    "pct_not_tested", "pct_limited", "pct_basic",
    "pct_proficient", "pct_accomplished", "pct_advanced", "pct_advanced_plus"
  )
  prof_cols <- prof_cols[prof_cols %in% names(df)]

  if (length(prof_cols) == 0) {
    warning("No proficiency level columns found")
    return(df)
  }

  # Map column names to proficiency level names
  prof_level_map <- c(
    "pct_not_tested" = "Not Tested",
    "pct_limited" = "Limited",
    "pct_basic" = "Basic",
    "pct_proficient" = "Proficient",
    "pct_accomplished" = "Accomplished",
    "pct_advanced" = "Advanced",
    "pct_advanced_plus" = "Advanced Plus"
  )

  # Pivot to long format
  tidy_df <- df |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(prof_cols),
      names_to = "proficiency_level",
      values_to = "pct"
    ) |>
    dplyr::mutate(
      proficiency_level = prof_level_map[proficiency_level]
    ) |>
    dplyr::filter(!is.na(pct))

  # Order proficiency levels
  prof_order <- c("Not Tested", "Limited", "Basic", "Proficient",
                  "Accomplished", "Advanced", "Advanced Plus")
  tidy_df$proficiency_level <- factor(
    tidy_df$proficiency_level,
    levels = prof_order
  )

  tidy_df
}


#' Tidy gap closing data
#'
#' Transforms gap closing data to ensure consistent format.
#' Gap closing data is already at the subgroup level, so this function
#' primarily standardizes column names and formats.
#'
#' @param df A processed data.frame from process_gap_closing()
#' @return A tidied data.frame with standardized format
#' @export
#' @examples
#' \dontrun{
#' raw <- get_raw_gap_closing(2025)
#' processed <- process_gap_closing(raw, 2025)
#' tidy <- tidy_gap_closing(processed)
#' }
tidy_gap_closing <- function(df) {

  # Gap closing data is already in long format (building x subgroup)

  # Just standardize and ensure consistent format

  # Standardize subgroup names if present
  if ("subgroup" %in% names(df)) {
    df$subgroup_std <- standardize_subgroup(df$subgroup)
  }

  # Add derived metrics

  # Proficient or Above (combined ELA and Math)
  if ("ela_performance_index" %in% names(df) && "math_performance_index" %in% names(df)) {
    df$combined_performance_index <- (
      dplyr::coalesce(df$ela_performance_index, 0) +
        dplyr::coalesce(df$math_performance_index, 0)
    ) / 2
  }

  # Met Gap Closing target (>= 50%)
  if ("gap_closing_pct" %in% names(df)) {
    df$met_gap_closing <- !is.na(df$gap_closing_pct) & df$gap_closing_pct >= 50
  }

  # Filter out rows with no data
  df |>
    dplyr::filter(
      !is.na(ela_performance_index) | !is.na(math_performance_index)
    )
}


#' Calculate proficiency rates from proficiency distribution
#'
#' Calculates the percentage of students at or above proficient level
#' from the proficiency level distribution.
#'
#' Proficient or Above includes: Proficient, Accomplished, Advanced, Advanced Plus
#'
#' @param df A processed achievement data.frame
#' @return Data frame with pct_proficient_or_above column added
#' @export
#' @examples
#' \dontrun{
#' raw <- get_raw_achievement(2025)
#' processed <- process_achievement(raw, 2025)
#' with_proficiency <- calculate_proficiency_rate(processed)
#' }
calculate_proficiency_rate <- function(df) {

  # Proficient or Above = Proficient + Accomplished + Advanced + Advanced Plus
  prof_cols <- c("pct_proficient", "pct_accomplished", "pct_advanced", "pct_advanced_plus")
  available_cols <- prof_cols[prof_cols %in% names(df)]

  if (length(available_cols) > 0) {
    df$pct_proficient_or_above <- rowSums(
      df[, available_cols, drop = FALSE],
      na.rm = TRUE
    )
    # Set to NA if all source columns are NA
    all_na <- apply(df[, available_cols, drop = FALSE], 1, function(x) all(is.na(x)))
    df$pct_proficient_or_above[all_na] <- NA
  }

  df
}


#' Add aggregation flags to assessment data
#'
#' Adds boolean flags to identify building-level records and
#' district characteristics.
#'
#' @param df Assessment dataframe
#' @return data.frame with boolean aggregation flags
#' @export
#' @examples
#' \dontrun{
#' data <- fetch_assessment(2025)
#' with_flags <- id_assessment_aggs(data)
#' }
id_assessment_aggs <- function(df) {

  # All assessment data is building-level (no district or state aggregates in raw data)
  df |>
    dplyr::mutate(
      # All records are building-level
      is_building = TRUE,
      is_district = FALSE,
      is_state = FALSE,

      # Entity type
      entity_type = "Building",

      # Aggregation flag
      aggregation_flag = "campus"
    )
}
