# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw ODEW enrollment data into a
# clean, standardized format.
#
# Ohio uses IRN (Information Retrieval Number) as a 6-digit identifier for
# districts and schools.
#
# ==============================================================================

#' Convert to numeric, handling suppression markers
#'
#' ODEW uses various markers for suppressed data (*, <10, NC, etc.)
#' and uses commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Remove commas and whitespace, then convert to numeric
  x <- gsub(",", "", x)
  x <- trimws(x)
  # Handle common suppression markers
  x <- gsub("^\\*$", NA_character_, x)
  x <- gsub("^NC$", NA_character_, x, ignore.case = TRUE)
  x <- gsub("^<.*$", NA_character_, x)
  x <- gsub("^N/A$", NA_character_, x, ignore.case = TRUE)
  x <- gsub("^-$", NA_character_, x)
  suppressWarnings(as.numeric(x))
}


#' Process raw ODEW enrollment data
#'
#' Transforms raw ODEW enrollment data into a standardized format with
#' consistent column names and data types.
#'
#' @param df Raw data frame from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(df, end_year) {

  if (end_year >= 2015) {
    process_enr_modern(df, end_year)
  } else {
    process_enr_legacy(df, end_year)
  }
}


#' Process modern format ODEW data
#'
#' Processes enrollment data from Ohio Report Card downloads (2015+).
#' Standardizes column names and extracts key enrollment metrics.
#'
#' @param df Raw data frame
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_enr_modern <- function(df, end_year) {

  cols <- names(df)

  # Ohio column names are typically formatted like:
  # "District IRN", "District Name", "Building IRN", "Building Name"
  # "Total Enrollment", demographic columns, grade columns

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

  # District IRN (6 digits)
  dist_irn_col <- find_col("^District.*IRN$|^Dist.*IRN$|^DIST_IRN$")
  if (!is.null(dist_irn_col)) {
    result$district_irn <- sprintf("%06d", as.integer(df[[dist_irn_col]]))
  }

  # Building IRN (6 digits)
  bldg_irn_col <- find_col("^Building.*IRN$|^Bldg.*IRN$|^BLDG_IRN$|^School.*IRN$")
  if (!is.null(bldg_irn_col)) {
    result$building_irn <- sprintf("%06d", as.integer(df[[bldg_irn_col]]))
  }

  # District Name
  dist_name_col <- find_col("^District.*Name$|^Dist.*Name$|^DISTRICT$")
  if (!is.null(dist_name_col)) {
    result$district_name <- trimws(df[[dist_name_col]])
  }

  # Building Name
  bldg_name_col <- find_col("^Building.*Name$|^Bldg.*Name$|^School.*Name$|^BUILDING$")
  if (!is.null(bldg_name_col)) {
    result$building_name <- trimws(df[[bldg_name_col]])
  }

  # County
  county_col <- find_col("^County$|^COUNTY$")
  if (!is.null(county_col)) {
    result$county <- trimws(df[[county_col]])
  }

  # Entity type (District/Building)
  if ("entity_type" %in% names(df)) {
    result$entity_type <- df$entity_type
  } else {
    # Infer from presence of building IRN
    result$entity_type <- ifelse(
      is.na(result$building_irn) | result$building_irn == "000000",
      "District",
      "Building"
    )
  }

  # === ENROLLMENT TOTALS ===

  total_col <- find_col("^Total.*Enrollment$|^Enrollment$|^TOTAL_ENR$|^ENROLLMENT$")
  if (!is.null(total_col)) {
    result$enrollment_total <- safe_numeric(df[[total_col]])
  }

  # === DEMOGRAPHICS - Race/Ethnicity ===

  demo_map <- list(
    "white" = "White|%.*White|WHITE",
    "black" = "Black|African.*American|%.*Black|BLACK",
    "hispanic" = "Hispanic|Latino|%.*Hispanic|HISPANIC",
    "asian" = "Asian|%.*Asian|ASIAN",
    "pacific_islander" = "Pacific.*Islander|Hawaiian|%.*Pacific|PACIFIC",
    "native_american" = "American.*Indian|Native.*American|%.*Indian|INDIAN",
    "multiracial" = "Multi.*Racial|Two.*More|%.*Multi|MULTI"
  )

  for (new_name in names(demo_map)) {
    pattern <- demo_map[[new_name]]
    # Look for count columns first, then percentage columns
    count_col <- find_col(paste0("^#.*", pattern, "|^Count.*", pattern, "|^N_", toupper(new_name)))
    pct_col <- find_col(paste0("^%.*", pattern, "|^Pct.*", pattern, "|^PCT_", toupper(new_name)))

    if (!is.null(count_col)) {
      result[[new_name]] <- safe_numeric(df[[count_col]])
    } else if (!is.null(pct_col) && "enrollment_total" %in% names(result)) {
      # Convert percentage to count
      pct_val <- safe_numeric(df[[pct_col]])
      result[[new_name]] <- round(pct_val / 100 * result$enrollment_total)
    }
  }

  # === SPECIAL POPULATIONS ===

  special_map <- list(
    "economically_disadvantaged" = "Econom.*Disadv|Low.*Income|ED|%.*Econom",
    "disability" = "Disabilit|Special.*Ed|IEP|SWD|%.*Disab",
    "english_learner" = "English.*Learner|EL|LEP|%.*English.*Learn",
    "gifted" = "Gifted|%.*Gifted",
    "migrant" = "Migrant|%.*Migrant",
    "homeless" = "Homeless|%.*Homeless"
  )

  for (new_name in names(special_map)) {
    pattern <- special_map[[new_name]]
    count_col <- find_col(paste0("^#.*", pattern, "|^Count.*", pattern, "|^N_"))
    pct_col <- find_col(paste0("^%.*", pattern, "|^Pct.*", pattern, "|^PCT_"))

    if (!is.null(count_col)) {
      result[[new_name]] <- safe_numeric(df[[count_col]])
    } else if (!is.null(pct_col) && "enrollment_total" %in% names(result)) {
      pct_val <- safe_numeric(df[[pct_col]])
      result[[new_name]] <- round(pct_val / 100 * result$enrollment_total)
    }
  }

  # === GRADE-LEVEL ENROLLMENT ===

  grade_map <- list(
    "grade_pk" = "^PK$|Pre.*K|PreK|Grade.*PK",
    "grade_k" = "^K$|^KG$|Kindergarten|Grade.*K$",
    "grade_01" = "^1$|^01$|Grade.*1$|^G1$",
    "grade_02" = "^2$|^02$|Grade.*2$|^G2$",
    "grade_03" = "^3$|^03$|Grade.*3$|^G3$",
    "grade_04" = "^4$|^04$|Grade.*4$|^G4$",
    "grade_05" = "^5$|^05$|Grade.*5$|^G5$",
    "grade_06" = "^6$|^06$|Grade.*6$|^G6$",
    "grade_07" = "^7$|^07$|Grade.*7$|^G7$",
    "grade_08" = "^8$|^08$|Grade.*8$|^G8$",
    "grade_09" = "^9$|^09$|Grade.*9$|^G9$",
    "grade_10" = "^10$|Grade.*10$|^G10$",
    "grade_11" = "^11$|Grade.*11$|^G11$",
    "grade_12" = "^12$|Grade.*12$|^G12$"
  )

  for (new_name in names(grade_map)) {
    pattern <- grade_map[[new_name]]
    grade_col <- find_col(pattern)
    if (!is.null(grade_col)) {
      result[[new_name]] <- safe_numeric(df[[grade_col]])
    }
  }

  # === DISTRICT TYPE (Ohio-specific) ===

  dist_type_col <- find_col("District.*Type|Dist.*Type|TYPE")
  if (!is.null(dist_type_col)) {
    result$district_type <- trimws(df[[dist_type_col]])
  }

  result
}


#' Process legacy format ODEW data
#'
#' Processes enrollment data from older Ohio data formats (2007-2014).
#' Column layouts and file formats differ from modern data.
#'
#' Legacy data characteristics:
#' - May use different column names (e.g., "School IRN" vs "Building IRN")
#' - May have different grade level encoding
#' - Demographics may be in percentage rather than count format
#' - Some columns present in modern data may be missing
#'
#' @param df Raw data frame with layout-derived column names
#' @param end_year School year end (2007-2014)
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr_legacy <- function(df, end_year) {

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
  # Legacy data may use "School" instead of "Building"

  # District IRN
  dist_irn_col <- find_col("^District.*IRN$|^Dist.*IRN$|^DIST_IRN$|^DISTRICT$")
  if (!is.null(dist_irn_col)) {
    result$district_irn <- sprintf("%06d", as.integer(df[[dist_irn_col]]))
  }

  # Building/School IRN (legacy often uses "School")
  bldg_irn_col <- find_col("^Building.*IRN$|^Bldg.*IRN$|^School.*IRN$|^SCHOOL_IRN$|^IRN$")
  if (!is.null(bldg_irn_col)) {
    result$building_irn <- sprintf("%06d", as.integer(df[[bldg_irn_col]]))
  }

  # District Name
  dist_name_col <- find_col("^District.*Name$|^Dist.*Name$|^DISTRICT$|^District$")
  if (!is.null(dist_name_col) && dist_name_col != dist_irn_col) {
    result$district_name <- trimws(df[[dist_name_col]])
  }

  # Building/School Name
  bldg_name_col <- find_col("^Building.*Name$|^Bldg.*Name$|^School.*Name$|^SCHOOL$|^School$|^Building$")
  if (!is.null(bldg_name_col) && bldg_name_col != bldg_irn_col) {
    result$building_name <- trimws(df[[bldg_name_col]])
  }

  # County
  county_col <- find_col("^County$|^COUNTY$")
  if (!is.null(county_col)) {
    result$county <- trimws(df[[county_col]])
  }

  # Entity type
  if ("entity_type" %in% names(df)) {
    result$entity_type <- df$entity_type
  } else {
    # Infer from presence of building IRN
    result$entity_type <- ifelse(
      is.na(result$building_irn) | result$building_irn == "000000",
      "District",
      "Building"
    )
  }

  # === ENROLLMENT BY GRADE ===
  # Legacy files often have grade columns directly named

  grade_patterns <- list(
    "grade_pk" = "^PK$|^Pre-?K|^PreK|^PREK",
    "grade_k" = "^K$|^KG$|^Kindergarten|^KINDER",
    "grade_01" = "^1$|^01$|^Grade.?1$|^G1$|^GRADE_1$|^First",
    "grade_02" = "^2$|^02$|^Grade.?2$|^G2$|^GRADE_2$|^Second",
    "grade_03" = "^3$|^03$|^Grade.?3$|^G3$|^GRADE_3$|^Third",
    "grade_04" = "^4$|^04$|^Grade.?4$|^G4$|^GRADE_4$|^Fourth",
    "grade_05" = "^5$|^05$|^Grade.?5$|^G5$|^GRADE_5$|^Fifth",
    "grade_06" = "^6$|^06$|^Grade.?6$|^G6$|^GRADE_6$|^Sixth",
    "grade_07" = "^7$|^07$|^Grade.?7$|^G7$|^GRADE_7$|^Seventh",
    "grade_08" = "^8$|^08$|^Grade.?8$|^G8$|^GRADE_8$|^Eighth",
    "grade_09" = "^9$|^09$|^Grade.?9$|^G9$|^GRADE_9$|^Ninth",
    "grade_10" = "^10$|^Grade.?10$|^G10$|^GRADE_10$|^Tenth",
    "grade_11" = "^11$|^Grade.?11$|^G11$|^GRADE_11$|^Eleventh",
    "grade_12" = "^12$|^Grade.?12$|^G12$|^GRADE_12$|^Twelfth"
  )

  for (new_name in names(grade_patterns)) {
    pattern <- grade_patterns[[new_name]]
    grade_col <- find_col(pattern)
    if (!is.null(grade_col)) {
      result[[new_name]] <- safe_numeric(df[[grade_col]])
    }
  }

  # === TOTAL ENROLLMENT ===
  total_col <- find_col("^Total$|^Total.*Enrollment$|^Enrollment$|^TOTAL$|^TOTAL_ENR$|^Grand.*Total$")
  if (!is.null(total_col)) {
    result$enrollment_total <- safe_numeric(df[[total_col]])
  } else {
    # Calculate from grade columns if available
    grade_cols <- names(result)[grepl("^grade_", names(result))]
    if (length(grade_cols) > 0) {
      result$enrollment_total <- rowSums(result[, grade_cols, drop = FALSE], na.rm = TRUE)
      result$enrollment_total[result$enrollment_total == 0] <- NA
    }
  }

  # === DEMOGRAPHICS (may not be available in all legacy files) ===

  demo_map <- list(
    "white" = "White|%.*White|WHITE|Caucasian",
    "black" = "Black|African.*American|%.*Black|BLACK",
    "hispanic" = "Hispanic|Latino|%.*Hispanic|HISPANIC",
    "asian" = "Asian|%.*Asian|ASIAN",
    "pacific_islander" = "Pacific.*Islander|Hawaiian|%.*Pacific|PACIFIC",
    "native_american" = "American.*Indian|Native.*American|%.*Indian|INDIAN",
    "multiracial" = "Multi.*Racial|Two.*More|%.*Multi|MULTI"
  )

  for (new_name in names(demo_map)) {
    pattern <- demo_map[[new_name]]
    count_col <- find_col(paste0("^#.*", pattern, "|^Count.*", pattern, "|^N_", toupper(new_name)))
    pct_col <- find_col(paste0("^%.*", pattern, "|^Pct.*", pattern, "|^PCT_", toupper(new_name)))

    if (!is.null(count_col)) {
      result[[new_name]] <- safe_numeric(df[[count_col]])
    } else if (!is.null(pct_col) && "enrollment_total" %in% names(result)) {
      pct_val <- safe_numeric(df[[pct_col]])
      result[[new_name]] <- round(pct_val / 100 * result$enrollment_total)
    }
  }

  # === SPECIAL POPULATIONS (may be limited in legacy data) ===

  special_map <- list(
    "economically_disadvantaged" = "Econom.*Disadv|Low.*Income|ED|%.*Econom|Free.*Lunch|Reduced.*Lunch",
    "disability" = "Disabilit|Special.*Ed|IEP|SWD|%.*Disab",
    "english_learner" = "English.*Learner|EL|LEP|%.*English.*Learn|Limited.*English"
  )

  for (new_name in names(special_map)) {
    pattern <- special_map[[new_name]]
    count_col <- find_col(paste0("^#.*", pattern, "|^Count.*", pattern, "|^N_"))
    pct_col <- find_col(paste0("^%.*", pattern, "|^Pct.*", pattern, "|^PCT_"))

    if (!is.null(count_col)) {
      result[[new_name]] <- safe_numeric(df[[count_col]])
    } else if (!is.null(pct_col) && "enrollment_total" %in% names(result)) {
      pct_val <- safe_numeric(df[[pct_col]])
      result[[new_name]] <- round(pct_val / 100 * result$enrollment_total)
    }
  }

  # === DISTRICT TYPE ===

  dist_type_col <- find_col("District.*Type|Dist.*Type|TYPE|Type")
  if (!is.null(dist_type_col)) {
    result$district_type <- trimws(df[[dist_type_col]])
  }

  result
}


#' Validate IRN format
#'
#' Checks if an IRN is valid (6-digit Ohio identifier).
#'
#' @param irn Character vector of IRNs to validate
#' @return Logical vector indicating valid IRNs
#' @export
#' @examples
#' is_valid_irn("043752")  # TRUE
#' is_valid_irn("12345")   # FALSE (only 5 digits)
#' is_valid_irn("1234567") # FALSE (7 digits)
is_valid_irn <- function(irn) {
  # IRN should be exactly 6 digits
  grepl("^[0-9]{6}$", irn)
}


#' Format IRN with leading zeros
#'
#' Ensures IRN is formatted as a 6-digit string with leading zeros.
#'
#' @param irn Numeric or character IRN
#' @return Character vector with properly formatted IRNs
#' @export
#' @examples
#' format_irn(43752)    # "043752"
#' format_irn("43752")  # "043752"
format_irn <- function(irn) {
  sprintf("%06d", as.integer(irn))
}
