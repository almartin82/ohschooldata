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
#'
#' @param df A wide data.frame of processed enrollment data
#' @return A long data.frame of tidied enrollment data
#' @export
tidy_enr <- function(df) {

  # TODO: Define invariant columns (identifiers that stay the same)

  # TODO: Define demographic subgroups to tidy

  # TODO: Define special population subgroups

  # TODO: Define grade-level columns

  # TODO: Transform demographic/special subgroups to long format

  # TODO: Extract total enrollment as a "subgroup"

  # TODO: Transform grade-level enrollment to long format

  # TODO: Combine all tidy data

  stop("Not yet implemented - see docs/PRD.md for specifications")
}


#' Identify enrollment aggregation levels
#'
#' Adds boolean flags to identify state, district, and school level records.
#'
#' @param df Enrollment dataframe, output of tidy_enr
#' @return data.frame with boolean aggregation flags
#' @export
id_enr_aggs <- function(df) {

  # TODO: Add is_state flag

  # TODO: Add is_district flag

  # TODO: Add is_school flag

  # TODO: Add is_community_school (charter) flag

  # TODO: Add is_jvsd (joint vocational) flag

  stop("Not yet implemented")
}


#' Custom Enrollment Grade Level Aggregates
#'
#' Creates aggregations for common grade groupings: K-8, 9-12 (HS).
#'
#' @param df A tidy enrollment df
#' @return df of aggregated enrollment data
#' @export
enr_grade_aggs <- function(df) {

  # TODO: K-8 aggregate

  # TODO: High school (9-12) aggregate

  # TODO: K-12 aggregate (excludes PK)

  stop("Not yet implemented")
}
