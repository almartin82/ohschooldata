# List available enrollment data years

Returns a vector of years for which enrollment data is likely available
from the Ohio School Report Cards portal.

## Usage

``` r
list_enr_years()
```

## Value

Integer vector of available years

## Details

Ohio Report Card data availability:

- 2007-2014: Legacy format data (data-download-YYYY folders with varying
  file names)

- 2015-present: Modern format with consistent
  ENROLLMENT_BUILDING/DISTRICT files

Note: EMIS historical data extends back to the 1990s but requires
different access methods. This package focuses on the Report Card
download portal data.

## Examples

``` r
if (FALSE) { # \dontrun{
available_years <- list_enr_years()
} # }
```
