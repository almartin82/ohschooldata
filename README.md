# ohschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/ohschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/ohschooldata/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/almartin82/ohschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/ohschooldata/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

An R package for fetching and processing Ohio school enrollment data from the Ohio Department of Education and Workforce (ODEW).

## Overview

`ohschooldata` provides a simple interface to download, process, and analyze Ohio public school enrollment data. The package:
- Downloads enrollment data from the Ohio School Report Cards portal
- Transforms raw data into a standardized, tidy format
- Supports district and building (school) level data
- Includes demographic breakdowns and grade-level enrollment
- Provides local caching to avoid repeated downloads

## Installation

Install from GitHub:

```r
# install.packages("remotes")
remotes::install_github("almartin82/ohschooldata")
```

## Quick Start

```r
library(ohschooldata)
library(dplyr)

# Fetch 2024 enrollment data (2023-24 school year)
enr <- fetch_enr(2024)

# View statewide totals
enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# Get data for a specific district using IRN
columbus <- enr %>% filter_district("043752")

# Filter by county
franklin <- enr %>% filter_county("Franklin")
```

### Tidying the Data

By default, `fetch_enr()` returns data in tidy (long) format. For wide format:

```r
# Wide format: one column per demographic
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Or tidy an existing wide dataset
enr_tidy <- tidy_enr(enr_wide)
```

### Multiple Years

```r
# Fetch a range of years
enr_history <- fetch_enr_range(2020, 2024)

# Or use purrr
library(purrr)
enr_multi <- map_df(2020:2024, fetch_enr)
```

## Documentation

Full documentation is available at the [pkgdown site](https://almartin82.github.io/ohschooldata/).

## Available Data

### Years

Data is available from **2015 onwards** through the Ohio School Report Cards portal. Use `list_enr_years()` to see currently available years.

### Data Sources

Data is sourced from the [Ohio School Report Cards](https://reportcard.education.ohio.gov/) portal, which provides enrollment files from the EMIS (Education Management Information System).

**Note**: If automated downloads fail due to portal security, you can manually download files from [reportcard.education.ohio.gov/download](https://reportcard.education.ohio.gov/download) and use `import_local_enrollment()` to load them.

## Understanding IRN Codes

Ohio uses **IRN (Information Retrieval Number)** as the unique identifier for districts and buildings:

- IRNs are 6-digit codes (e.g., `043752` for Columbus City Schools)
- District IRNs identify school districts
- Building IRNs identify individual schools within districts

```r
# Validate and format IRNs
is_valid_irn("043752")  # TRUE
format_irn(43752)       # "043752" (adds leading zeros)

# Filter by district IRN
columbus <- enr %>% filter_district("043752")
```

## Ohio School Types

The data includes flags for Ohio-specific school types:

- `is_traditional`: Traditional public school districts
- `is_community_school`: Community schools (Ohio's term for charter schools)
- `is_jvsd`: Joint Vocational School Districts (career-technical centers)
- `is_stem`: STEM schools

```r
# Get only community schools
community <- enr %>% filter(is_community_school, is_district)

# Get traditional public districts
traditional <- enr %>% filter(is_traditional, is_district)
```

## Data Schema

Tidy format includes these columns:

| Column | Description |
|--------|-------------|
| `end_year` | School year end (e.g., 2024 for 2023-24) |
| `district_irn` | 6-digit district IRN |
| `building_irn` | 6-digit building IRN (NA for district-level) |
| `district_name` | Name of the district |
| `building_name` | Name of the building (NA for district-level) |
| `entity_type` | "District" or "Building" |
| `county` | Ohio county name |
| `grade_level` | Grade level ("TOTAL", "K", "01", etc.) |
| `subgroup` | Demographic subgroup |
| `n_students` | Student count |
| `pct` | Percentage of total enrollment |

## Caching

Downloaded data is cached locally to speed up subsequent requests:

```r
# View cached files
cache_status()

# Clear cache for a specific year
clear_enr_cache(2024)

# Clear all cached data
clear_enr_cache()

# Force fresh download
enr <- fetch_enr(2024, use_cache = FALSE)
```

## Contributing

Issues and pull requests are welcome at [GitHub](https://github.com/almartin82/ohschooldata).

## License

MIT
