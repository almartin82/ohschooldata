# Filter enrollment data by district

Convenience function to filter enrollment data to a specific district
using the IRN.

## Usage

``` r
filter_district(df, irn, include_buildings = TRUE)
```

## Arguments

- df:

  Enrollment dataframe

- irn:

  District IRN (6-digit identifier)

- include_buildings:

  If TRUE (default), include building-level data. If FALSE, only return
  district-level aggregates.

## Value

Filtered data frame

## Examples

``` r
if (FALSE) { # \dontrun{
# Get Columbus City Schools (IRN 043752)
columbus <- fetch_enr(2024) %>% filter_district("043752")
} # }
```
