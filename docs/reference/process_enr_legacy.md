# Process legacy format ODEW data

Processes enrollment data from older Ohio data formats (pre-2015).
Column layouts and file formats differ from modern data.

## Usage

``` r
process_enr_legacy(df, end_year)
```

## Arguments

- df:

  Raw data frame with layout-derived column names

- end_year:

  School year end

## Value

Processed data frame
