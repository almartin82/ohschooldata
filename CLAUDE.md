# Claude Code Instructions for ohschooldata

## Commit and PR Guidelines

- Do NOT include "Generated with Claude Code" in commit messages
- Do NOT include "Co-Authored-By: Claude" in commit messages
- Do NOT mention Claude or AI assistance in PR descriptions
- Keep commit messages clean and professional

## Project Context

This is an R package for fetching and processing Ohio school enrollment data from ODEW (Ohio Department of Education and Workforce).

### Key Files

- `R/fetch_enrollment.R` - Main `fetch_enr()` function
- `R/get_raw_enrollment.R` - Downloads raw data from ODEW
- `R/process_enrollment.R` - Transforms raw data to standard schema
- `R/tidy_enrollment.R` - Converts to long/tidy format
- `R/cache.R` - Local caching layer

### Data Sources

Data comes from https://reportcard.education.ohio.gov/download
Storage URL: https://reportcardstorage.education.ohio.gov/data-download-YYYY/

Available year range: 2007-present (2024-25 school year = end_year 2025)
- 2007-2014: Legacy format (varying file names, grade-by-grade enrollment)
- 2015-present: Modern format (ENROLLMENT_BUILDING.xlsx, ENROLLMENT_DISTRICT.xlsx)

## Package Conventions
- Follow tidyverse style guide
- Use roxygen2 for documentation
- All exported functions should have examples
- Cache downloaded data to avoid repeated API calls

## Ohio-Specific Notes
- IRN (Information Retrieval Number) is 6 digits for districts/schools
- Data source: Ohio Department of Education and Workforce (ODEW)
- Primary data system: EMIS (Education Management Information System)
- District types: city, local, exempted village, joint vocational
