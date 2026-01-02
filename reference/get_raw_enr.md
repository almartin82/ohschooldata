# Download raw enrollment data from ODEW

Downloads enrollment data from the Ohio School Report Cards data
download portal. Data includes district and building level enrollment by
grade, demographics, and special populations.

## Usage

``` r
get_raw_enr(end_year)
```

## Arguments

- end_year:

  School year end (2023-24 = 2024). Valid range is 2007 to current year.

## Value

Raw data frame from ODEW

## Details

Data availability by year:

- 2007-2014: Legacy format with different file naming conventions

- 2015-present: Modern format with consistent
  ENROLLMENT_BUILDING/DISTRICT files

Note: Ohio Report Card data access may require manual download from
<https://reportcard.education.ohio.gov/download> if direct downloads
fail. The download portal uses dynamic tokens that may prevent automated
access.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get raw 2024 data
raw_2024 <- get_raw_enr(2024)

# Get historical 2010 data
raw_2010 <- get_raw_enr(2010)
} # }
```
