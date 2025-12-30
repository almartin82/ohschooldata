# ohschooldata: Fetch and Process Ohio School Data

The ohschooldata package provides functions to download and process
school data from the Ohio Department of Education and Workforce (ODEW).

## Main Functions

- [`fetch_enr`](https://almartin82.github.io/ohschooldata/reference/fetch_enr.md):
  Download enrollment data for a specific year

- [`fetch_enr_range`](https://almartin82.github.io/ohschooldata/reference/fetch_enr_range.md):
  Download enrollment data for multiple years

- [`get_state_enrollment`](https://almartin82.github.io/ohschooldata/reference/get_state_enrollment.md):
  Get statewide enrollment summary

## Data Processing

- [`tidy_enr`](https://almartin82.github.io/ohschooldata/reference/tidy_enr.md):
  Convert wide data to tidy (long) format

- [`id_enr_aggs`](https://almartin82.github.io/ohschooldata/reference/id_enr_aggs.md):
  Add aggregation level flags

- [`enr_grade_aggs`](https://almartin82.github.io/ohschooldata/reference/enr_grade_aggs.md):
  Create grade-level aggregates

## Filtering

- [`filter_district`](https://almartin82.github.io/ohschooldata/reference/filter_district.md):
  Filter by district IRN

- [`filter_county`](https://almartin82.github.io/ohschooldata/reference/filter_county.md):
  Filter by county name

## IRN Utilities

- [`is_valid_irn`](https://almartin82.github.io/ohschooldata/reference/is_valid_irn.md):
  Validate IRN format

- [`format_irn`](https://almartin82.github.io/ohschooldata/reference/format_irn.md):
  Format IRN with leading zeros

## Cache Management

- [`cache_status`](https://almartin82.github.io/ohschooldata/reference/cache_status.md):
  Show cached data status

- [`clear_enr_cache`](https://almartin82.github.io/ohschooldata/reference/clear_enr_cache.md):
  Clear cached data

## Data Source

Data is downloaded from the Ohio School Report Cards data portal at
<https://reportcard.education.ohio.gov/download>.

Ohio uses IRN (Information Retrieval Number), a 6-digit identifier, for
districts and schools.

## See also

Useful links:

- <https://almartin82.github.io/ohschooldata/>

- <https://github.com/almartin82/ohschooldata>

- Report bugs at <https://github.com/almartin82/ohschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
