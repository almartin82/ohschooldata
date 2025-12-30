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

  School year end (2023-24 = 2024)

## Value

Raw data frame from ODEW

## Details

Note: Ohio Report Card data access may require manual download from
<https://reportcard.education.ohio.gov/download> if direct downloads
fail. The download portal uses dynamic tokens that may prevent automated
access.
