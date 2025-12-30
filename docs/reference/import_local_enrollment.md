# Import local enrollment Excel files

Imports enrollment data from locally downloaded Excel files. Use this
when automatic downloads fail and you need to manually download files
from <https://reportcard.education.ohio.gov/download>.

## Usage

``` r
import_local_enrollment(district_file = NULL, building_file = NULL, end_year)
```

## Arguments

- district_file:

  Path to district-level enrollment Excel file

- building_file:

  Path to building-level enrollment Excel file (optional)

- end_year:

  School year end (e.g., 2024 for 2023-24)

## Value

Raw data frame with enrollment data

## Examples

``` r
if (FALSE) { # \dontrun{
# After downloading files from Ohio Report Card portal:
enr_raw <- import_local_enrollment(
  district_file = "~/Downloads/23-24_ENROLLMENT_DISTRICT.xlsx",
  building_file = "~/Downloads/23-24_ENROLLMENT_BUILDING.xlsx",
  end_year = 2024
)
} # }
```
