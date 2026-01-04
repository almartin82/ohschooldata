# Process legacy format ODEW data

Processes enrollment data from older Ohio data formats (2007-2014).
Column layouts and file formats differ from modern data.

## Usage

``` r
process_enr_legacy(df, end_year)
```

## Arguments

- df:

  Raw data frame with layout-derived column names

- end_year:

  School year end (2007-2014)

## Value

Processed data frame with standardized columns

## Details

Legacy data characteristics:

- May use different column names (e.g., "School IRN" vs "Building IRN")

- May have different grade level encoding

- Demographics may be in percentage rather than count format

- Some columns present in modern data may be missing
