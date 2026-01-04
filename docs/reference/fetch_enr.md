# Fetch Ohio enrollment data

Downloads and processes enrollment data from the Ohio Department of
Education and Workforce EMIS data files. Data is available from the Ohio
School Report Cards data download portal.

## Usage

``` r
fetch_enr(end_year, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  A school year. Year is the end of the academic year - eg 2023-24
  school year is year '2024'. Valid values are 2007 onwards.

- tidy:

  If TRUE (default), returns data in long (tidy) format with subgroup
  column. If FALSE, returns wide format with one row per entity.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from ODEW.

## Value

Data frame with enrollment data. Tidy format includes columns:

- end_year: School year end (e.g., 2024 for 2023-24)

- district_irn: 6-digit district IRN

- building_irn: 6-digit building IRN (NA for district-level)

- district_name: Name of the district

- building_name: Name of the building (NA for district-level)

- entity_type: "District" or "Building"

- county: Ohio county name

- grade_level: Grade level or "TOTAL"

- subgroup: Demographic or population subgroup

- n_students: Student count

- pct: Percentage of total enrollment

## Details

Data availability spans from 2007 to the current school year:

- 2007-2014: Legacy format data with varying file structures

- 2015-present: Modern format with consistent
  ENROLLMENT_BUILDING/DISTRICT files

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# Get 2025 data (2024-25 school year, released September 2025)
enr_2025 <- fetch_enr(2025)

# Get historical data from 2010 (2009-10 school year)
enr_2010 <- fetch_enr(2010)

# Get wide format (one row per entity)
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Force fresh download (ignore cache)
enr_fresh <- fetch_enr(2024, use_cache = FALSE)

# Get multiple years - full available range
enr_all <- purrr::map_df(2007:2025, fetch_enr)

# Get recent 5 years
enr_recent <- purrr::map_df(2020:2024, fetch_enr)
} # }
```
