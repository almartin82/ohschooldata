# ==============================================================================
# Enrollment Data Tidying Functions
# ==============================================================================
#
# This file contains functions for transforming enrollment data from wide
# format to long (tidy) format and identifying aggregation levels.
#
# ==============================================================================

#' Tidy enrollment data
#'
#' Transforms wide enrollment data to long format with subgroup column.
#' Each row represents a single observation (entity + grade + subgroup).
#'
#' @param df A wide data.frame of processed enrollment data
#' @return A long data.frame of tidied enrollment data
#' @export
#' @examples
#' \dontrun{
#' wide_data <- fetch_enr(2024, tidy = FALSE)
#' tidy_data <- tidy_enr(wide_data)
#' }
tidy_enr <- function(df) {

  # Invariant columns (identifiers that stay the same)
  invariants <- c(
    "end_year", "district_irn", "building_irn",
    "district_name", "building_name",
    "entity_type", "county", "district_type"
  )
  invariants <- invariants[invariants %in% names(df)]

  # Demographic subgroups to tidy
  demo_cols <- c(
    "white", "black", "hispanic", "asian",
    "native_american", "pacific_islander", "multiracial"
  )
  demo_cols <- demo_cols[demo_cols %in% names(df)]

  # Special population subgroups
  special_cols <- c(
    "economically_disadvantaged", "disability", "english_learner",
    "gifted", "migrant", "homeless"
  )
  special_cols <- special_cols[special_cols %in% names(df)]

  # Grade-level columns
  grade_cols <- grep("^grade_", names(df), value = TRUE)

  all_subgroups <- c(demo_cols, special_cols)

  # Transform demographic/special subgroups to long format
  if (length(all_subgroups) > 0) {
    tidy_subgroups <- purrr::map_df(
      all_subgroups,
      function(.x) {
        df |>
          dplyr::rename(n_students = dplyr::all_of(.x)) |>
          dplyr::select(dplyr::all_of(c(invariants, "n_students", "enrollment_total"))) |>
          dplyr::mutate(
            subgroup = .x,
            pct = n_students / enrollment_total,
            grade_level = "TOTAL"
          ) |>
          dplyr::select(dplyr::all_of(c(invariants, "grade_level", "subgroup", "n_students", "pct")))
      }
    )
  } else {
    tidy_subgroups <- NULL
  }

  # Extract total enrollment as a "subgroup"
  if ("enrollment_total" %in% names(df)) {
    tidy_total <- df |>
      dplyr::select(dplyr::all_of(c(invariants, "enrollment_total"))) |>
      dplyr::mutate(
        n_students = enrollment_total,
        subgroup = "total_enrollment",
        pct = 1.0,
        grade_level = "TOTAL"
      ) |>
      dplyr::select(dplyr::all_of(c(invariants, "grade_level", "subgroup", "n_students", "pct")))
  } else {
    tidy_total <- NULL
  }

  # Transform grade-level enrollment to long format
  if (length(grade_cols) > 0) {
    grade_level_map <- c(
      "grade_pk" = "PK",
      "grade_k" = "K",
      "grade_01" = "01",
      "grade_02" = "02",
      "grade_03" = "03",
      "grade_04" = "04",
      "grade_05" = "05",
      "grade_06" = "06",
      "grade_07" = "07",
      "grade_08" = "08",
      "grade_09" = "09",
      "grade_10" = "10",
      "grade_11" = "11",
      "grade_12" = "12"
    )

    tidy_grades <- purrr::map_df(
      grade_cols,
      function(.x) {
        gl <- grade_level_map[.x]
        if (is.na(gl)) gl <- .x

        df |>
          dplyr::rename(n_students = dplyr::all_of(.x)) |>
          dplyr::select(dplyr::all_of(c(invariants, "n_students", "enrollment_total"))) |>
          dplyr::mutate(
            subgroup = "total_enrollment",
            pct = n_students / enrollment_total,
            grade_level = gl
          ) |>
          dplyr::select(dplyr::all_of(c(invariants, "grade_level", "subgroup", "n_students", "pct")))
      }
    )
  } else {
    tidy_grades <- NULL
  }

  # Combine all tidy data
  dplyr::bind_rows(tidy_total, tidy_subgroups, tidy_grades) |>
    dplyr::filter(!is.na(n_students))
}


#' Identify enrollment aggregation levels
#'
#' Adds boolean flags to identify state, district, and school level records,
#' as well as Ohio-specific entity types like community schools (charters)
#' and joint vocational school districts (JVSDs).
#'
#' @param df Enrollment dataframe, output of tidy_enr
#' @return data.frame with boolean aggregation flags
#' @export
#' @examples
#' \dontrun{
#' tidy_data <- fetch_enr(2024)
#' with_flags <- id_enr_aggs(tidy_data)
#' }
id_enr_aggs <- function(df) {
  df |>
    dplyr::mutate(
      # State level: entity_type == "State" or all IRNs are NA/empty
      is_state = entity_type == "State" |
        (is.na(district_irn) & is.na(building_irn)),

      # District level: entity_type == "District"
      is_district = entity_type == "District" & !is_state,

      # Building/School level: entity_type == "Building"
      is_building = entity_type == "Building",

      # Community schools (charter schools in Ohio)
      # Community schools are identified by district type
      is_community_school = !is.na(district_type) &
        grepl("Community|Charter", district_type, ignore.case = TRUE),

      # Joint Vocational School Districts (JVSDs)
      # Career-technical education centers
      is_jvsd = !is.na(district_type) &
        grepl("JVS|Vocational|Career", district_type, ignore.case = TRUE),

      # STEM schools
      is_stem = !is.na(district_type) &
        grepl("STEM", district_type, ignore.case = TRUE),

      # Traditional public school districts
      is_traditional = !is_community_school & !is_jvsd & !is_stem & !is_state
    )
}


#' Custom Enrollment Grade Level Aggregates
#'
#' Creates aggregations for common grade groupings: K-8, 9-12 (HS), K-12.
#' Useful for comparing elementary and secondary enrollment patterns.
#'
#' @param df A tidy enrollment df from tidy_enr
#' @return df of aggregated enrollment data with K8, HS, K12 grade levels
#' @export
#' @examples
#' \dontrun{
#' tidy_data <- fetch_enr(2024)
#' grade_aggregates <- enr_grade_aggs(tidy_data)
#' }
enr_grade_aggs <- function(df) {

  # Group by invariants (everything except grade_level and counts)
  group_vars <- c(
    "end_year", "district_irn", "building_irn",
    "district_name", "building_name",
    "entity_type", "county", "district_type",
    "subgroup",
    "is_state", "is_district", "is_building",
    "is_community_school", "is_jvsd", "is_stem", "is_traditional"
  )
  group_vars <- group_vars[group_vars %in% names(df)]

  # K-8 aggregate
  k8_agg <- df |>
    dplyr::filter(
      subgroup == "total_enrollment",
      grade_level %in% c("K", "01", "02", "03", "04", "05", "06", "07", "08")
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) |>
    dplyr::summarize(
      n_students = sum(n_students, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      grade_level = "K8",
      pct = NA_real_
    )

  # High school (9-12) aggregate
  hs_agg <- df |>
    dplyr::filter(
      subgroup == "total_enrollment",
      grade_level %in% c("09", "10", "11", "12")
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) |>
    dplyr::summarize(
      n_students = sum(n_students, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      grade_level = "HS",
      pct = NA_real_
    )

  # K-12 aggregate (excludes PK)
  k12_agg <- df |>
    dplyr::filter(
      subgroup == "total_enrollment",
      grade_level %in% c("K", "01", "02", "03", "04", "05", "06", "07", "08",
                         "09", "10", "11", "12")
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) |>
    dplyr::summarize(
      n_students = sum(n_students, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      grade_level = "K12",
      pct = NA_real_
    )

  dplyr::bind_rows(k8_agg, hs_agg, k12_agg)
}


#' Filter enrollment data by district
#'
#' Convenience function to filter enrollment data to a specific district
#' using the IRN.
#'
#' @param df Enrollment dataframe
#' @param irn District IRN (6-digit identifier)
#' @param include_buildings If TRUE (default), include building-level data.
#'   If FALSE, only return district-level aggregates.
#' @return Filtered data frame
#' @export
#' @examples
#' \dontrun{
#' # Get Columbus City Schools (IRN 043752)
#' columbus <- fetch_enr(2024) |> filter_district("043752")
#' }
filter_district <- function(df, irn, include_buildings = TRUE) {
  # Ensure IRN is properly formatted
  irn <- format_irn(irn)

  if (include_buildings) {
    df |>
      dplyr::filter(district_irn == irn)
  } else {
    df |>
      dplyr::filter(district_irn == irn, entity_type == "District")
  }
}


#' Filter enrollment data by county
#'
#' Convenience function to filter enrollment data to a specific Ohio county.
#'
#' @param df Enrollment dataframe
#' @param county_name Name of Ohio county (case-insensitive)
#' @return Filtered data frame
#' @export
#' @examples
#' \dontrun{
#' # Get Franklin County schools
#' franklin <- fetch_enr(2024) |> filter_county("Franklin")
#' }
filter_county <- function(df, county_name) {
  df |>
    dplyr::filter(grepl(county_name, county, ignore.case = TRUE))
}
