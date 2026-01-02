# Download legacy format ODEW enrollment data

Downloads enrollment data for years 2007-2014 when data formats and file
naming conventions were different from modern years.

## Usage

``` r
get_raw_enr_legacy(end_year)
```

## Arguments

- end_year:

  School year end (2007-2014)

## Value

Raw data frame with enrollment data

## Details

Legacy data file patterns discovered through research:

- 2014: "SCHOOL ENROLLMENT BY GRADE.xls", "DISTRICT ENROLLMENT BY
  GRADE.xls"

- 2007-2013: Various patterns including "ENROLLMENT_BUILDING.xls",
  grade-level files
