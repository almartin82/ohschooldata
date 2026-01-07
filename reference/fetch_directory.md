# Fetch Ohio school directory data

Downloads and processes school directory data from the Ohio Department
of Education and Workforce OEDS (Ohio Educational Directory System).
This includes all public schools and districts with contact information
and administrator names.

## Usage

``` r
fetch_directory(end_year = NULL, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  Currently unused. The directory data represents current schools and is
  not year-specific. Included for API consistency with other fetch
  functions.

- tidy:

  If TRUE (default), returns data in a standardized format with
  consistent column names. If FALSE, returns raw column names from OEDS.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from ODEW.

## Value

A tibble with school directory data. Columns include:

- `irn`: 6-digit IRN (Information Retrieval Number)

- `state_school_id`: IRN (same as irn, for schema consistency)

- `state_district_id`: Parent IRN (district IRN for schools)

- `school_name`: Name of the school or district

- `district_name`: Parent organization name

- `school_type`: Grade-level category (Elementary, High School, etc.)

- `org_type`: Organization type (Public School, Public District, etc.)

- `org_category`: Category (School, District, etc.)

- `grades_served`: Grade span served

- `status`: Organization status (Open, Closed, etc.)

- `county`: Ohio county name

- `address`: Full mailing address

- `city`: City (parsed from address)

- `state`: State (always "Ohio")

- `zip`: ZIP code (parsed from address)

- `phone`: Phone number

- `fax`: Fax number

- `website`: Organization website URL

- `email`: Organization email address

- `superintendent_name`: Superintendent name

- `superintendent_email`: Superintendent email

- `superintendent_phone`: Superintendent phone

- `treasurer_name`: Treasurer name

- `treasurer_email`: Treasurer email

- `principal_name`: Principal name

- `principal_email`: Principal email

- `principal_phone`: Principal phone

## Details

The directory data is downloaded from the OEDS Data Extract API. This
data represents the current state of Ohio schools and districts and is
updated regularly by ODEW.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get school directory data
dir_data <- fetch_directory()

# Get raw format (original OEDS column names)
dir_raw <- fetch_directory(tidy = FALSE)

# Force fresh download (ignore cache)
dir_fresh <- fetch_directory(use_cache = FALSE)

# Filter to active schools only
library(dplyr)
active_schools <- dir_data |>
  filter(org_category == "School", status == "Open")

# Find all schools in a district
columbus_schools <- dir_data |>
  filter(state_district_id == "043802", org_category == "School")
} # }
```
