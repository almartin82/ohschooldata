# Download Ohio Excel file

Helper function to download and read an Excel file from ODEW. Handles
multiple potential URL patterns since Ohio's file naming varies slightly
year to year.

## Usage

``` r
download_ohio_excel(url, type, end_year)
```

## Arguments

- url:

  Primary URL to try

- type:

  "building" or "district"

- end_year:

  School year end

## Value

Data frame or NULL if download fails
