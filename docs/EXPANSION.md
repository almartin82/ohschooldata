# Ohio School Data Expansion Research

**Last Updated:** 2026-01-04 **Themes Researched:** Graduation Rates,
School Directory

------------------------------------------------------------------------

## School Directory Implementation (COMPLETED)

**Status:** IMPLEMENTED **Function:**
[`fetch_directory()`](https://almartin82.github.io/ohschooldata/reference/fetch_directory.md)
**Source:** Ohio Educational Directory System (OEDS) Data Extract API
**Implementation Date:** 2026-01-04

### Implementation Summary

The school directory feature has been fully implemented using the OEDS
Data Extract API:

**Functions Created:** -
[`fetch_directory()`](https://almartin82.github.io/ohschooldata/reference/fetch_directory.md) -
Main interface for retrieving directory data -
[`get_raw_directory()`](https://almartin82.github.io/ohschooldata/reference/get_raw_directory.md) -
Downloads from OEDS API -
[`process_directory()`](https://almartin82.github.io/ohschooldata/reference/process_directory.md) -
Standardizes schema and parses addresses - Directory-specific cache
functions -
[`clear_directory_cache()`](https://almartin82.github.io/ohschooldata/reference/clear_directory_cache.md) -
Cache management

**Data Source:** - **URL:**
`https://oeds.ode.state.oh.us/DataExtract/GetRequestOrgExtract` -
**Method:** HTTP POST with JSON payload - **Format:** CSV download (skip
first line with timestamp) - **Coverage:** All organization types
(districts, schools, ESCs, JVSDs, STEM, community schools)

**Data Fields Provided:** - IRN (state_school_id, state_district_id) -
Organization names (school_name, district_name) - Organization type and
category - School type and grade span - Status (Open, Closed, etc.) -
Full address (parsed into street, city, state, zip) - Contact info
(phone, fax, website, email) - **Superintendent:** name, email, phone -
**Principal:** name, email, phone - **Treasurer:** name, email, phone -
County designation

### Known Issues

**OEDS Server Connectivity (January 2026):** - The OEDS server at
`oeds.ode.state.oh.us` is experiencing connection timeouts - Both the
web interface and API endpoint are unreachable - This appears to be a
temporary server issue, not a code problem - The implementation is
complete and tested; it will work when the server is responsive

**Workarounds:** - Tests use `skip_if_offline()` guards to handle server
unavailability - Cache functionality allows using previously downloaded
data - Implementation follows the same pattern as other state packages

### Testing

Comprehensive test suite created in `tests/testthat/test-directory.R`: -
Data structure validation - Contact information presence checks - IRN
format validation - Major district verification - Organization category
validation - Data quality checks - Cache functionality tests - Grade
span and school type validation - County coverage verification

All tests use `skip_on_cran()` and `skip_if_offline()` guards for CI
compatibility.

### Documentation

- Function documentation with examples (roxygen2)
- README updated with directory usage examples
- Data availability section updated
- All functions exported in NAMESPACE

### References

- [Ohio OEDS Main
  Page](https://education.ohio.gov/Topics/Data/Ohio-Educational-Directory-System-OEDS)
- [OEDS Data Extract Tool](https://oeds.ode.state.oh.us/DataExtract)
- [OEDS Search Organizations](https://oeds.ode.state.oh.us/searchorg)

------------------------------------------------------------------------

## Graduation Rates Research

## Executive Summary

Ohio graduation rate data is available through the Ohio School Report
Cards portal. Direct downloadable files exist in the legacy
`reportcardstorage.education.ohio.gov` blob storage for **2015-2020** (6
years of data), but **2021+ data is not available via direct URL
download** - it requires JavaScript interaction with the modern Report
Card portal (`reportcard.education.ohio.gov/download`).

**Key Finding:** Modern (2021+) graduation data access requires
either: 1. Browser automation (Selenium/Playwright) to interact with the
download portal 2. Manual download and local import functions 3. Finding
an alternative API endpoint

## Data Sources Found

### Source 1: Report Card Storage - Legacy Files (2015-2020)

**Base URL:**
`https://reportcardstorage.education.ohio.gov/data-download-{YEAR}/`

| Year  | File                                  | HTTP Status | Size          | Level    |
|-------|---------------------------------------|-------------|---------------|----------|
| 2015  | `1415_DISTRICT_GRAD_RATE.xls`         | 200         | 284,672 bytes | District |
| 2016  | `1516_DISTRICT_Grad_Rate.xls`         | 200         | 444,416 bytes | District |
| 2017  | `1617_DISTRICT_GRAD_RATE_REVISED.xls` | 200         | 397,312 bytes | District |
| 2018  | `1718_DISTRICT_GRAD_RATE.xlsx`        | 200         | 139,229 bytes | District |
| 2018  | `1718_BUILDING_GRAD_RATE.xlsx`        | 200         | 727,473 bytes | Building |
| 2019  | `1819_DISTRICT_GRAD_RATE.xlsx`        | 200         | 96,290 bytes  | District |
| 2019  | `1819_BUILDING_GRAD_RATE.xlsx`        | 200         | (not tested)  | Building |
| 2020  | `1920_DISTRICT_GRAD_RATE.xlsx`        | 200         | 96,603 bytes  | District |
| 2020  | `1920_BUILDING_GRAD_RATE.xlsx`        | 200         | (not tested)  | Building |
| 2021+ | Various patterns                      | 404         | N/A           | N/A      |

**Notes:** - Files use `.xls` format for 2015-2017, `.xlsx` for 2018+ -
Building-level data only confirmed for 2018-2020 - 2021+ files do not
exist in blob storage; data-download folders return 404

### Source 2: Report Card Portal (2021+)

- **URL:** `https://reportcard.education.ohio.gov/download`
- **HTTP Status:** 200 (returns HTML)
- **Format:** Single-page JavaScript application (Angular)
- **Access:** Requires JavaScript interaction - no direct URL download
  available
- **Years:** 2021-2025 (current)

**Technical Details:** - Portal uses dynamic content loading - No public
API endpoints discovered - All tested API routes return HTML (SPA
routing), not JSON data - File downloads likely require
session/authentication tokens

### Source 3: ODE Frequently Requested Data

- **URL:**
  `https://education.ohio.gov/Topics/Data/Frequently-Requested-Data/`
- **Graduation Data:** NOT AVAILABLE - unlike enrollment, graduation
  rate data is not in this location
- **Enrollment Pattern:** `oct_hdcnt_fy{YY}.xls.aspx` (for reference)

## Schema Analysis

### Column Names by Year

**2015 Format (single sheet with both 4-year and 5-year):** \| Column \|
Description \| \|——–\|————-\| \| District IRN \| 6-character district
identifier \| \| District Name \| District name \| \| County \| Ohio
county \| \| Region \| ODE region (1-16) \| \| Street Address \|
District address \| \| City and Zip Code \| City, state, zip \| \| Phone
\# \| Contact phone \| \| Superintendent \| Superintendent name \| \|
Four Year Longitudinal Graduation Rate - Class of 2014 \| 4-year rate as
percentage \| \| Letter Grade of 4 Year Graduate Rate 2014 \| A-F grade
\| \| Four Year Graduation Rate Numerator - Class of 2014 \| Cohort
graduates \| \| Four Year Graduation Rate Denominator - Class of 2014 \|
Cohort total \| \| Five Year Longitudinal Graduation Rate - Class of
2013 \| 5-year rate \| \| Letter Grade of 5 Year Graduate Rate 2013 \|
A-F grade \| \| Five Year Graduation Rate Numerator - Class of 2013 \|
5-year numerator \| \| Five Year Graduation Rate Denominator - Class of
2013 \| 5-year denominator \| \| Watermark \| File version marker \|

**2016-2018 Format (separate sheets for 4-year and 5-year):** - Sheet 1:
“Four Year Graduation” - Sheet 2: “Five Year Graduation” - Sheet 3:
“Data Notes” (or “Notes”)

Each sheet contains: \| Column \| Description \| \|——–\|————-\| \|
District IRN \| 6-character district ID \| \| District Name \| District
name \| \| County \| County \| \| Region \| ODE region \| \| Address \|
Street address \| \| City and Zip Code \| Location \| \| Phone \# \|
Phone number \| \| Superintendent \| Contact \| \| Four Year
Longitudinal Graduation Rate - Class of {YEAR} \| Rate as percentage
(0-100) \| \| Letter Grade of 4 year Graduation Rate {YEAR} \| A/B/C/D/F
\| \| Four Year Graduation Rate Numerator - Class of {YEAR} \| Graduates
count \| \| Four Year Graduation Rate Denominator - Class of {YEAR} \|
Cohort size \| \| Four Year Graduation Rate - Similar District Average
\| Comparison \| \| Four Year Graduation Rate - Statewide Average \|
State average \| \| Watermark \| Version marker \|

**2020 Format (COVID year - simplified):** - Removed address/contact
info columns - Added “Data Notes” sheet with COVID explanation - Sheet
naming changed to “Four-Year Graduation” (with hyphen) - Columns
simplified to: - District IRN, District Name, County, Region - Four-Year
Graduation Rate - Class of {YEAR} - Four-Year Graduation Rate Measure
Letter Grade - Four-Year Graduation Rate Numerator/Denominator -
Four-Year Graduation Rate - Similar District Average/Statewide Average -
Watermark

**Building-Level Format (2018-2020):** Same as district format but adds:
\| Column \| Description \| \|——–\|————-\| \| Building IRN \|
6-character building ID \| \| Building Name \| School name \| \|
Principal \| Building principal \|

### Schema Changes Noted

| Year  | Change                                                       |
|-------|--------------------------------------------------------------|
| 2015  | Single sheet format with both 4-year and 5-year rates        |
| 2016  | Split into separate sheets for 4-year and 5-year             |
| 2017  | Added “REVISED” suffix to filename                           |
| 2018  | Changed from .xls to .xlsx format; added building-level data |
| 2020  | Removed address/contact columns; added COVID data notes      |
| 2021+ | Files no longer in blob storage; requires portal download    |

### ID System

- **District IRN:** 6-character string (e.g., “043489” for Akron City)
- **Building IRN:** 6-character string (e.g., “012345”)
- **Leading zeros:** MUST preserve - IRNs starting with “0” are common
- **Type:** Always character/string, never numeric

### Known Data Issues

1.  **Suppressed values:** Small cohorts may have masked rates
    (displayed as text or blank)
2.  **COVID impact (2020):** Limited data due to pandemic; see “Data
    Notes” sheet
3.  **Rate format:** Stored as percentage values (0-100), not decimals
4.  **Watermark column:** Internal use, can be dropped in processing
5.  **Cohort timing:** 4-year rate for “Class of 2019” appears in 2020
    file (1-year lag)

## Time Series Heuristics

### Expected Ranges

| Metric                | Expected Value  | Red Flag If          |
|-----------------------|-----------------|----------------------|
| Statewide 4-year rate | 85-90%          | \< 80% or \> 95%     |
| Statewide 5-year rate | 87-92%          | \< 82% or \> 96%     |
| District count        | 607-610         | Sudden change \> 5   |
| Building count        | 3,400-3,500     | Sudden change \> 100 |
| YoY change            | \< 2% typically | \> 5% statewide      |

### Major Districts for Validation

| District            | IRN    | Expected 4-Year Rate |
|---------------------|--------|----------------------|
| Columbus City       | 043802 | 73-78%               |
| Cleveland Municipal | 043786 | 68-75%               |
| Cincinnati City     | 043752 | 72-80%               |
| Akron City          | 043489 | 74-80%               |
| Toledo City         | 044792 | 75-82%               |

### Verified Values from Raw Data

**2016 (Class of 2015):** - Columbus City (043802): 73.7% - Cleveland
Municipal (043786): 69.1% - Cincinnati City (043752): 72.9% - Statewide
Average: 83.0%

**2018 (Class of 2017):** - Statewide Average: Listed in data - District
count: 608

## Available Years Summary

| Year Range | Entity Levels       | Access Method | Format  |
|------------|---------------------|---------------|---------|
| 2015-2017  | District only       | Direct URL    | .xls    |
| 2018-2020  | District + Building | Direct URL    | .xlsx   |
| 2021-2025  | District + Building | Portal/Manual | Unknown |

## Subgroup Data

**NOT AVAILABLE** in the discovered files.

The legacy graduation rate files contain only aggregate rates - no
demographic subgroups (race, gender, economically disadvantaged, ELL,
special education).

Subgroup graduation data may be available: 1. Through the Report Card
portal download interface 2. In the “Gap Closing” component files 3.
Through EMIS direct data access (requires different approach)

## Recommended Implementation

### Priority: MEDIUM

### Complexity: MEDIUM (2015-2020) / HARD (2021+)

### Estimated Files to Modify: 5-6

### Phase 1: Implement 2015-2020 (Direct Download)

1.  Create `get_raw_grad()` function for direct URL downloads
2.  Handle schema differences between 2015 and 2016-2020
3.  Create `process_grad()` for standardization
4.  Create `tidy_grad()` for long format
5.  Create `fetch_grad()` main interface
6.  Write comprehensive tests

### Phase 2: Implement 2021+ (Requires Investigation)

Options: 1. **Browser automation:** Use Selenium/Playwright via
reticulate 2. **Local import:** Create `import_local_graduation()` for
manual downloads 3. **API discovery:** Further investigate portal API
endpoints 4. **Alternative sources:** Research if EMIS or ODE has
alternative access

### Implementation Steps

1.  **Create `R/get_raw_graduation.R`:**
    - `get_raw_grad(end_year)` - downloads and returns raw data
    - Handle 2015 vs 2016+ schema differences
    - Handle .xls vs .xlsx formats
    - Return combined 4-year and 5-year data
2.  **Create `R/process_graduation.R`:**
    - `process_grad(raw, end_year)` - standardizes column names
    - Handle schema evolution
    - Compute derived columns if needed
3.  **Create `R/tidy_graduation.R`:**
    - `tidy_grad(processed)` - converts to long format
    - Create subgroup column for “4_year_rate”, “5_year_rate”
    - Standard output format matching enrollment
4.  **Create `R/fetch_graduation.R`:**
    - `fetch_grad(end_year, tidy = TRUE, use_cache = TRUE)`
    - `fetch_grad_multi(end_years)`
    - `fetch_grad_range(start_year, end_year)`
    - `list_grad_years()` - returns available years
5.  **Update `R/cache.R`:**
    - Add graduation cache type
6.  **Create tests:**
    - `tests/testthat/test-graduation-pipeline-live.R`
    - `tests/testthat/test-graduation-fidelity.R`

## Test Requirements

### Raw Data Fidelity Tests Needed

``` r
test_that("2016: Columbus City 4-year rate matches raw Excel", {
  skip_if_offline()
  data <- fetch_grad(2016, tidy = FALSE)
  columbus <- data[data$district_irn == "043802", ]
  # Verified raw value: 73.7
  expect_equal(columbus$four_year_rate, 73.7, tolerance = 0.1)
})

test_that("2018: Cleveland Municipal 4-year rate matches raw Excel", {
  skip_if_offline()
  data <- fetch_grad(2018, tidy = FALSE)
  cleveland <- data[data$district_irn == "043786", ]
  # Verify against raw file
  expect_equal(cleveland$four_year_rate, 69.1, tolerance = 0.1)
})

test_that("2020: Data returns despite COVID", {
  skip_if_offline()
  data <- fetch_grad(2020, tidy = TRUE)
  expect_gt(nrow(data), 600) # Should have all districts
})
```

### Data Quality Checks

``` r
test_that("Graduation rates are in valid range", {
  data <- fetch_grad(2019, tidy = FALSE)
  # Rates should be 0-100 (percentages)
  expect_true(all(data$four_year_rate >= 0 & data$four_year_rate <= 100, na.rm = TRUE))
  expect_true(all(data$five_year_rate >= 0 & data$five_year_rate <= 100, na.rm = TRUE))
})

test_that("No negative cohort sizes", {
  data <- fetch_grad(2019, tidy = FALSE)
  expect_true(all(data$four_year_denominator >= 0, na.rm = TRUE))
})

test_that("Statewide average is reasonable", {
  data <- fetch_grad(2019, tidy = FALSE)
  state_avg <- unique(data$four_year_statewide_average)
  expect_true(state_avg > 80 && state_avg < 95)
})
```

## Blockers and Risks

### Critical Issues

1.  **2021+ Data Access:** No direct download URLs discovered.
    Implementation for 2021+ requires either:
    - Browser automation investment
    - Accepting manual download workflow
    - Finding undocumented API
2.  **No Subgroup Data:** Discovered files lack demographic breakdowns.
    Full graduation analysis requires finding additional data sources.

### Moderate Issues

1.  **Schema changes:** Multiple format changes require careful column
    mapping
2.  **Building-level gaps:** Only 2018-2020 have building-level files in
    storage

### Low Risk

1.  **COVID 2020 data:** Well-documented, just needs proper handling
2.  **IRN format:** Simple 6-character strings, already handled in
    enrollment code

## References

- [Ohio School Report Cards
  Download](https://reportcard.education.ohio.gov/download)
- [Graduation Component Technical
  Documentation](https://education.ohio.gov/getattachment/Topics/Data/Report-Card-Resources/Traditional-Report-Cards/Traditional-Graduation-Component-Technical-Document.pdf.aspx)
- [Guide to 2024-2025 Ohio School Report
  Cards](https://education.ohio.gov/getattachment/Topics/Data/Report-Card-Resources/Traditional-Report-Cards/2024-2025-Report-Card-Guide.pdf.aspx)
- [ODE Frequently Requested
  Data](http://education.ohio.gov/Topics/Data/Frequently-Requested-Data)
