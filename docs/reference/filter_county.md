# Filter enrollment data by county

Convenience function to filter enrollment data to a specific Ohio
county.

## Usage

``` r
filter_county(df, county_name)
```

## Arguments

- df:

  Enrollment dataframe

- county_name:

  Name of Ohio county (case-insensitive)

## Value

Filtered data frame

## Examples

``` r
if (FALSE) { # \dontrun{
# Get Franklin County schools
franklin <- fetch_enr(2024) |> filter_county("Franklin")
} # }
```
