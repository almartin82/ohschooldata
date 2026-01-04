# Fetch enrollment data for a range of years

Convenience function to download enrollment data for a range of years.
Results are combined into a single data frame.

## Usage

``` r
fetch_enr_range(start_year, end_year, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- start_year:

  First year to fetch (minimum 2007)

- end_year:

  Last year to fetch

- tidy:

  If TRUE (default), returns tidy format

- use_cache:

  If TRUE (default), uses cached data when available

## Value

Combined data frame with enrollment data for all requested years

## Details

Data is available from 2007 onwards. Note that legacy years (2007-2014)
may have different column availability compared to modern years (2015+).

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 5 years of recent enrollment data
enr_history <- fetch_enr_range(2020, 2024)

# Get all available historical data
enr_all <- fetch_enr_range(2007, 2025)

# Get legacy data only
enr_legacy <- fetch_enr_range(2007, 2014)
} # }
```
