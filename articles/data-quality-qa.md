# Data Quality Analysis for Ohio School Enrollment

## Overview

This vignette performs quality assurance (QA) analysis on Ohio school
enrollment data fetched through the `ohschooldata` package. We examine:

1.  **Statewide time series** - Total enrollment trends and
    year-over-year changes
2.  **Major district analysis** - Enrollment patterns for Ohio’s 5
    largest urban districts
3.  **Data quality checks** - Missing values, outliers, and unusual
    patterns
4.  **Data issues** - Documentation of any discovered data quality
    issues

## Known Data Access Issues

**Important**: The Ohio Department of Education and Workforce (ODEW)
Report Card portal uses dynamic tokens for file access, which may
prevent automated downloads. If you encounter download errors:

1.  Visit <https://reportcard.education.ohio.gov/download>
2.  Select the desired school year
3.  Download the Enrollment files (District and Building level)
4.  Use
    [`import_local_enrollment()`](https://almartin82.github.io/ohschooldata/reference/import_local_enrollment.md)
    to load the files

See the package documentation for more details.

``` r
library(ohschooldata)
library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)
```

## Fetch Multi-Year Data

We attempt to fetch enrollment data from 2015-2024 (or the latest
available year).

``` r
# Get available years
available_years <- list_enr_years()
message(paste("Available years:", paste(available_years, collapse = ", ")))
```

    ## Available years: 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025

``` r
# Fetch all available years
years_to_fetch <- available_years

# Try to fetch data for each year, handling errors gracefully
all_enr <- purrr::map_df(years_to_fetch, function(y) {
  tryCatch({
    message(paste("Fetching year:", y))
    fetch_enr(y, tidy = TRUE, use_cache = TRUE)
  }, error = function(e) {
    warning(paste("Could not fetch data for", y, ":", e$message))
    NULL
  })
})
```

    ## Fetching year: 2007

    ## Downloading enrollment data for 2007 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   ODE Frequently Requested Data not available: HTTP error: 404

    ##   Trying Report Card data source...

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/SCHOOL%20ENROLLMENT%20BY%20GRADE.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/SCHOOL
    ## ENROLLMENT BY GRADE.xls': status was 'URL using bad/illegal format or missing
    ## URL'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/06-07_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/06-07_ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/0607_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/0607_ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/ENROLLMENT_BUILDING.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/Enrollment_Building.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/Enrollment_Building_2007.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/06-07_Building_Enrollment.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/Building_Enrollment_06-07.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/FY07_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/FY2007_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/DISTRICT%20ENROLLMENT%20BY%20GRADE.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/DISTRICT
    ## ENROLLMENT BY GRADE.xls': status was 'URL using bad/illegal format or missing
    ## URL'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/06-07_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/06-07_ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/0607_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/0607_ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/ENROLLMENT_DISTRICT.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/Enrollment_District.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/Enrollment_District_2007.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/06-07_District_Enrollment.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/District_Enrollment_06-07.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/FY07_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2007/FY2007_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in value[[3L]](cond): Could not fetch data for 2007 : Could not find enrollment data for year 2007 
    ##  Legacy data (2007-2014) uses varying file formats.
    ##  Please try downloading manually from: https://reportcard.education.ohio.gov/download
    ##  Then use import_local_enrollment() to load the files.

    ## Fetching year: 2008

    ## Downloading enrollment data for 2008 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   ODE Frequently Requested Data not available: HTTP error: 404

    ##   Trying Report Card data source...

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/SCHOOL%20ENROLLMENT%20BY%20GRADE.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/SCHOOL
    ## ENROLLMENT BY GRADE.xls': status was 'URL using bad/illegal format or missing
    ## URL'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/07-08_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/07-08_ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/0708_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/0708_ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/ENROLLMENT_BUILDING.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/Enrollment_Building.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/Enrollment_Building_2008.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/07-08_Building_Enrollment.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/Building_Enrollment_07-08.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/FY08_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/FY2008_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/DISTRICT%20ENROLLMENT%20BY%20GRADE.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/DISTRICT
    ## ENROLLMENT BY GRADE.xls': status was 'URL using bad/illegal format or missing
    ## URL'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/07-08_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/07-08_ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/0708_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/0708_ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/ENROLLMENT_DISTRICT.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/Enrollment_District.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/Enrollment_District_2008.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/07-08_District_Enrollment.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/District_Enrollment_07-08.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/FY08_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2008/FY2008_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in value[[3L]](cond): Could not fetch data for 2008 : Could not find enrollment data for year 2008 
    ##  Legacy data (2007-2014) uses varying file formats.
    ##  Please try downloading manually from: https://reportcard.education.ohio.gov/download
    ##  Then use import_local_enrollment() to load the files.

    ## Fetching year: 2009

    ## Downloading enrollment data for 2009 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   ODE Frequently Requested Data not available: HTTP error: 404

    ##   Trying Report Card data source...

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/SCHOOL%20ENROLLMENT%20BY%20GRADE.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/SCHOOL
    ## ENROLLMENT BY GRADE.xls': status was 'URL using bad/illegal format or missing
    ## URL'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/08-09_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/08-09_ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/0809_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/0809_ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/ENROLLMENT_BUILDING.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/Enrollment_Building.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/Enrollment_Building_2009.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/08-09_Building_Enrollment.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/Building_Enrollment_08-09.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/FY09_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/FY2009_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/DISTRICT%20ENROLLMENT%20BY%20GRADE.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/DISTRICT
    ## ENROLLMENT BY GRADE.xls': status was 'URL using bad/illegal format or missing
    ## URL'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/08-09_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/08-09_ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/0809_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/0809_ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/ENROLLMENT_DISTRICT.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/Enrollment_District.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/Enrollment_District_2009.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/08-09_District_Enrollment.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/District_Enrollment_08-09.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/FY09_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2009/FY2009_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in value[[3L]](cond): Could not fetch data for 2009 : Could not find enrollment data for year 2009 
    ##  Legacy data (2007-2014) uses varying file formats.
    ##  Please try downloading manually from: https://reportcard.education.ohio.gov/download
    ##  Then use import_local_enrollment() to load the files.

    ## Fetching year: 2010

    ## Downloading enrollment data for 2010 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   ODE Frequently Requested Data not available: HTTP error: 404

    ##   Trying Report Card data source...

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/SCHOOL%20ENROLLMENT%20BY%20GRADE.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/SCHOOL
    ## ENROLLMENT BY GRADE.xls': status was 'URL using bad/illegal format or missing
    ## URL'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/09-10_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/09-10_ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/0910_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/0910_ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/ENROLLMENT_BUILDING.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/Enrollment_Building.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/Enrollment_Building_2010.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/09-10_Building_Enrollment.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/Building_Enrollment_09-10.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/FY10_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/FY2010_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/DISTRICT%20ENROLLMENT%20BY%20GRADE.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/DISTRICT
    ## ENROLLMENT BY GRADE.xls': status was 'URL using bad/illegal format or missing
    ## URL'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/09-10_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/09-10_ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/0910_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/0910_ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/ENROLLMENT_DISTRICT.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/Enrollment_District.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/Enrollment_District_2010.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/09-10_District_Enrollment.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/District_Enrollment_09-10.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/FY10_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2010/FY2010_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in value[[3L]](cond): Could not fetch data for 2010 : Could not find enrollment data for year 2010 
    ##  Legacy data (2007-2014) uses varying file formats.
    ##  Please try downloading manually from: https://reportcard.education.ohio.gov/download
    ##  Then use import_local_enrollment() to load the files.

    ## Fetching year: 2011

    ## Downloading enrollment data for 2011 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   ODE Frequently Requested Data not available: HTTP error: 404

    ##   Trying Report Card data source...

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/SCHOOL%20ENROLLMENT%20BY%20GRADE.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/SCHOOL
    ## ENROLLMENT BY GRADE.xls': status was 'URL using bad/illegal format or missing
    ## URL'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/10-11_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/10-11_ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/1011_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/1011_ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/ENROLLMENT_BUILDING.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/Enrollment_Building.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/Enrollment_Building_2011.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/10-11_Building_Enrollment.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/Building_Enrollment_10-11.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/FY11_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/FY2011_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/DISTRICT%20ENROLLMENT%20BY%20GRADE.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/DISTRICT
    ## ENROLLMENT BY GRADE.xls': status was 'URL using bad/illegal format or missing
    ## URL'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/10-11_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/10-11_ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/1011_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/1011_ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/ENROLLMENT_DISTRICT.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/Enrollment_District.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/Enrollment_District_2011.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/10-11_District_Enrollment.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/District_Enrollment_10-11.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/FY11_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2011/FY2011_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in value[[3L]](cond): Could not fetch data for 2011 : Could not find enrollment data for year 2011 
    ##  Legacy data (2007-2014) uses varying file formats.
    ##  Please try downloading manually from: https://reportcard.education.ohio.gov/download
    ##  Then use import_local_enrollment() to load the files.

    ## Fetching year: 2012

    ## Downloading enrollment data for 2012 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   ODE Frequently Requested Data not available: HTTP error: 404

    ##   Trying Report Card data source...

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/SCHOOL%20ENROLLMENT%20BY%20GRADE.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/SCHOOL
    ## ENROLLMENT BY GRADE.xls': status was 'URL using bad/illegal format or missing
    ## URL'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/11-12_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/11-12_ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/1112_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/1112_ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/ENROLLMENT_BUILDING.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/Enrollment_Building.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/Enrollment_Building_2012.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/11-12_Building_Enrollment.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/Building_Enrollment_11-12.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/FY12_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/FY2012_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/DISTRICT%20ENROLLMENT%20BY%20GRADE.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/DISTRICT
    ## ENROLLMENT BY GRADE.xls': status was 'URL using bad/illegal format or missing
    ## URL'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/11-12_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/11-12_ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/1112_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/1112_ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/ENROLLMENT_DISTRICT.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/Enrollment_District.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/Enrollment_District_2012.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/11-12_District_Enrollment.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/District_Enrollment_11-12.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/FY12_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2012/FY2012_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in value[[3L]](cond): Could not fetch data for 2012 : Could not find enrollment data for year 2012 
    ##  Legacy data (2007-2014) uses varying file formats.
    ##  Please try downloading manually from: https://reportcard.education.ohio.gov/download
    ##  Then use import_local_enrollment() to load the files.

    ## Fetching year: 2013

    ## Downloading enrollment data for 2013 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   Read 612 district rows

    ## Cached data for 2013

    ## Fetching year: 2014

    ## Downloading enrollment data for 2014 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   ODE Frequently Requested Data not available: HTTP error: 404

    ##   Trying Report Card data source...

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/SCHOOL%20ENROLLMENT%20BY%20GRADE.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/SCHOOL
    ## ENROLLMENT BY GRADE.xls': status was 'URL using bad/illegal format or missing
    ## URL'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/13-14_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/13-14_ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/1314_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/1314_ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/ENROLLMENT_BUILDING.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/ENROLLMENT_BUILDING.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/Enrollment_Building.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/Enrollment_Building_2014.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/13-14_Building_Enrollment.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/Building_Enrollment_13-14.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/FY14_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/FY2014_Enrollment_Building.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/DISTRICT%20ENROLLMENT%20BY%20GRADE.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/DISTRICT
    ## ENROLLMENT BY GRADE.xls': status was 'URL using bad/illegal format or missing
    ## URL'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/13-14_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/13-14_ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/1314_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/1314_ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/ENROLLMENT_DISTRICT.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/ENROLLMENT_DISTRICT.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/Enrollment_District.xls':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/Enrollment_District_2014.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/13-14_District_Enrollment.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/District_Enrollment_13-14.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/FY14_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in download.file(url, method = method, ...): URL
    ## 'https://reportcardstorage.education.ohio.gov/data-download-2014/FY2014_Enrollment_District.xlsx':
    ## status was 'SSL peer certificate or SSH remote key was not OK'

    ## Warning in value[[3L]](cond): Could not fetch data for 2014 : Could not find enrollment data for year 2014 
    ##  Legacy data (2007-2014) uses varying file formats.
    ##  Please try downloading manually from: https://reportcard.education.ohio.gov/download
    ##  Then use import_local_enrollment() to load the files.

    ## Fetching year: 2015

    ## Downloading enrollment data for 2015 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   Read 610 district rows

    ## Cached data for 2015

    ## Fetching year: 2016

    ## Downloading enrollment data for 2016 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   Read 608 district rows

    ## Cached data for 2016

    ## Fetching year: 2017

    ## Downloading enrollment data for 2017 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   Read 610 district rows

    ##   Read 3142 building rows

    ## Cached data for 2017

    ## Fetching year: 2018

    ## Downloading enrollment data for 2018 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   Read 610 district rows

    ##   Read 3151 building rows

    ## Cached data for 2018

    ## Fetching year: 2019

    ## Downloading enrollment data for 2019 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   Read 610 district rows

    ##   Read 3142 building rows

    ## Cached data for 2019

    ## Fetching year: 2020

    ## Downloading enrollment data for 2020 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   Read 610 district rows

    ##   Read 3121 building rows

    ## Cached data for 2020

    ## Fetching year: 2021

    ## Downloading enrollment data for 2021 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   Read 609 district rows

    ##   Read 3114 building rows

    ## Cached data for 2021

    ## Fetching year: 2022

    ## Downloading enrollment data for 2022 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   Read 609 district rows

    ##   Read 3214 building rows

    ## Cached data for 2022

    ## Fetching year: 2023

    ## Downloading enrollment data for 2023 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   Read 609 district rows

    ##   Read 3179 building rows

    ## Cached data for 2023

    ## Fetching year: 2024

    ## Downloading enrollment data for 2024 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   Read 609 district rows

    ##   Read 3146 building rows

    ## Cached data for 2024

    ## Fetching year: 2025

    ## Downloading enrollment data for 2025 ...

    ##   Downloading from ODE Frequently Requested Data...

    ##   Read 609 district rows

    ##   Read 3114 building rows

    ## Cached data for 2025

``` r
# Check if we got any data
if (nrow(all_enr) == 0) {
  message("WARNING: No enrollment data could be fetched.")
  message("This is likely due to Ohio's data access restrictions.")
  message("Please download data manually from: https://reportcard.education.ohio.gov/download")
  data_available <- FALSE
} else {
  data_available <- TRUE
  # Verify years fetched
  years_fetched <- unique(all_enr$end_year)
  message(paste("Successfully fetched years:", paste(sort(years_fetched), collapse = ", ")))
}
```

    ## Successfully fetched years: 2013, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025

## Statewide Enrollment Time Series

The following analyses require enrollment data. If data could not be
fetched automatically, please download it manually and re-run this
vignette.

### Total Enrollment Trend

``` r
# Calculate statewide totals by year
state_totals <- all_enr %>%
  filter(
    entity_type == "District",
    subgroup == "total_enrollment",
    grade_level == "TOTAL"
  ) %>%
  group_by(end_year) %>%
  summarize(
    n_districts = n_distinct(district_irn),
    total_enrollment = sum(n_students, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(end_year) %>%
  mutate(
    yoy_change = total_enrollment - lag(total_enrollment),
    yoy_pct_change = (total_enrollment / lag(total_enrollment) - 1) * 100
  )

# Display the trend
knitr::kable(
  state_totals,
  col.names = c("Year", "Districts", "Total Enrollment", "YoY Change", "YoY % Change"),
  format.args = list(big.mark = ","),
  digits = 2,
  caption = "Ohio Statewide Enrollment Trend"
)
```

|  Year | Districts | Total Enrollment | YoY Change | YoY % Change |
|------:|----------:|-----------------:|-----------:|-------------:|
| 2,013 |       611 |        1,618,918 |         NA |           NA |
| 2,015 |       608 |        1,597,411 |    -21,507 |        -1.33 |
| 2,016 |       607 |        1,583,183 |    -14,228 |        -0.89 |
| 2,017 |       609 |        1,586,002 |      2,819 |         0.18 |
| 2,018 |       608 |        1,582,374 |     -3,628 |        -0.23 |
| 2,019 |       608 |        1,577,099 |     -5,275 |        -0.33 |
| 2,020 |       609 |        1,571,880 |     -5,219 |        -0.33 |
| 2,021 |       608 |        1,515,306 |    -56,574 |        -3.60 |
| 2,022 |       607 |        1,525,865 |     10,559 |         0.70 |
| 2,023 |       608 |        1,520,728 |     -5,137 |        -0.34 |
| 2,024 |       607 |        1,507,996 |    -12,732 |        -0.84 |
| 2,025 |       608 |        1,492,210 |    -15,786 |        -1.05 |

Ohio Statewide Enrollment Trend

### Visualize Statewide Trend

``` r
ggplot(state_totals, aes(x = end_year, y = total_enrollment)) +
  geom_line(color = "steelblue", linewidth = 1.2) +
  geom_point(color = "steelblue", size = 3) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  scale_x_continuous(breaks = state_totals$end_year) +
  labs(
    title = "Ohio Statewide K-12 Enrollment",
    subtitle = "District-level totals aggregated by year",
    x = "School Year (End Year)",
    y = "Total Enrollment"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
```

![Ohio Statewide Enrollment Over
Time](data-quality-qa_files/figure-html/state-trend-plot-1.png)

Ohio Statewide Enrollment Over Time

### Flag Large Year-over-Year Changes

Any year-over-year changes greater than 5% warrant investigation.

``` r
# Identify years with >5% change
large_changes <- state_totals %>%
  filter(abs(yoy_pct_change) > 5)

if (nrow(large_changes) > 0) {
  message("WARNING: Found years with >5% year-over-year change:")
  print(large_changes)
} else {
  message("No statewide year-over-year changes exceed 5%.")
}
```

    ## No statewide year-over-year changes exceed 5%.

### Year-over-Year Change Plot

``` r
state_totals_filtered <- state_totals %>% filter(!is.na(yoy_pct_change))

if (nrow(state_totals_filtered) > 0) {
  ggplot(state_totals_filtered, aes(x = end_year, y = yoy_pct_change)) +
    geom_col(aes(fill = yoy_pct_change > 0)) +
    geom_hline(yintercept = c(-5, 5), linetype = "dashed", color = "red", alpha = 0.7) +
    geom_hline(yintercept = 0, color = "black") +
    scale_fill_manual(values = c("TRUE" = "darkgreen", "FALSE" = "darkred"), guide = "none") +
    scale_x_continuous(breaks = state_totals_filtered$end_year) +
    labs(
      title = "Year-over-Year Enrollment Change",
      subtitle = "Red dashed lines indicate +/- 5% threshold",
      x = "School Year (End Year)",
      y = "Percent Change (%)"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}
```

![Year-over-Year Enrollment
Change](data-quality-qa_files/figure-html/yoy-change-plot-1.png)

Year-over-Year Enrollment Change

## Major District Analysis

We analyze Ohio’s 5 largest urban districts:

1.  **Columbus City Schools** (Franklin County)
2.  **Cleveland Municipal School District** (Cuyahoga County)
3.  **Cincinnati Public Schools** (Hamilton County)
4.  **Toledo Public Schools** (Lucas County)
5.  **Akron Public Schools** (Summit County)

### Identify Major Districts

``` r
# Get most recent year for district lookup
latest_year <- max(all_enr$end_year, na.rm = TRUE)

# Get district totals for most recent year
district_totals <- all_enr %>%
  filter(
    end_year == latest_year,
    entity_type == "District",
    subgroup == "total_enrollment",
    grade_level == "TOTAL"
  ) %>%
  arrange(desc(n_students)) %>%
  select(district_irn, district_name, county, n_students)

# Display top 10 districts
knitr::kable(
  head(district_totals, 10),
  col.names = c("IRN", "District Name", "County", "Enrollment"),
  format.args = list(big.mark = ","),
  caption = paste("Top 10 Ohio Districts by Enrollment (", latest_year, ")")
)
```

| IRN    | District Name                  | County   | Enrollment |
|:-------|:-------------------------------|:---------|-----------:|
| 043802 | Columbus City Schools District | Franklin |     46,630 |
| 043752 | Cincinnati Public Schools      | Hamilton |     34,547 |
| 043786 | Cleveland Municipal            | Cuyahoga |     33,189 |
| 046763 | Olentangy Local                | Delaware |     24,062 |
| 044800 | South-Western City             | Franklin |     21,906 |
| 044909 | Toledo City                    | Lucas    |     21,247 |
| 043489 | Akron City                     | Summit   |     19,985 |
| 046110 | Lakota Local                   | Butler   |     17,355 |
| 047027 | Dublin City                    | Franklin |     16,879 |
| 047019 | Hilliard City                  | Franklin |     16,251 |

Top 10 Ohio Districts by Enrollment ( 2025 )

### Define Target Districts

``` r
# Search for our target districts by name pattern
target_patterns <- c(
  "Columbus City" = "Columbus City",
  "Cleveland Municipal" = "Cleveland",
  "Cincinnati Public" = "Cincinnati",
  "Toledo Public" = "Toledo",
  "Akron Public" = "Akron"
)

# Find IRNs for each target district
target_districts <- purrr::map_df(names(target_patterns), function(name) {
  pattern <- target_patterns[name]
  match <- district_totals %>%
    filter(grepl(pattern, district_name, ignore.case = TRUE)) %>%
    head(1)
  if (nrow(match) > 0) {
    match$target_name <- name
    match
  } else {
    NULL
  }
})

if (nrow(target_districts) > 0) {
  knitr::kable(
    target_districts %>% select(target_name, district_irn, district_name, county),
    col.names = c("Target", "IRN", "Full Name", "County"),
    caption = "Major Ohio Urban Districts Identified"
  )
} else {
  message("WARNING: Could not identify target districts.")
}
```

| Target              | IRN    | Full Name                      | County   |
|:--------------------|:-------|:-------------------------------|:---------|
| Columbus City       | 043802 | Columbus City Schools District | Franklin |
| Cleveland Municipal | 043786 | Cleveland Municipal            | Cuyahoga |
| Cincinnati Public   | 043752 | Cincinnati Public Schools      | Hamilton |
| Toledo Public       | 044909 | Toledo City                    | Lucas    |
| Akron Public        | 043489 | Akron City                     | Summit   |

Major Ohio Urban Districts Identified

### Major District Enrollment Trends

``` r
# Get time series for target districts
if (nrow(target_districts) > 0) {
  target_irns <- target_districts$district_irn

  major_district_trends <- all_enr %>%
    filter(
      district_irn %in% target_irns,
      entity_type == "District",
      subgroup == "total_enrollment",
      grade_level == "TOTAL"
    ) %>%
    left_join(
      target_districts %>% select(district_irn, target_name),
      by = "district_irn"
    ) %>%
    select(end_year, target_name, district_name, n_students) %>%
    arrange(target_name, end_year)

  # Calculate YoY changes for each district
  major_district_yoy <- major_district_trends %>%
    group_by(target_name) %>%
    arrange(end_year) %>%
    mutate(
      yoy_change = n_students - lag(n_students),
      yoy_pct_change = (n_students / lag(n_students) - 1) * 100
    ) %>%
    ungroup()
}
```

### Major District Trend Plot

``` r
if (exists("major_district_trends") && nrow(major_district_trends) > 0) {
  ggplot(major_district_trends, aes(x = end_year, y = n_students, color = target_name)) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    scale_y_continuous(labels = comma) +
    scale_x_continuous(breaks = unique(major_district_trends$end_year)) +
    labs(
      title = "Major Ohio Urban District Enrollment Trends",
      x = "School Year (End Year)",
      y = "Total Enrollment",
      color = "District"
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "bottom"
    )
}
```

![Major District Enrollment
Trends](data-quality-qa_files/figure-html/major-district-plot-1.png)

Major District Enrollment Trends

### Flag Large District-Level Changes

``` r
if (exists("major_district_yoy")) {
  large_district_changes <- major_district_yoy %>%
    filter(abs(yoy_pct_change) > 5) %>%
    arrange(target_name, end_year)

  if (nrow(large_district_changes) > 0) {
    message("WARNING: Found major district years with >5% year-over-year change:")
    knitr::kable(
      large_district_changes %>%
        select(end_year, target_name, n_students, yoy_change, yoy_pct_change),
      col.names = c("Year", "District", "Enrollment", "YoY Change", "YoY %"),
      format.args = list(big.mark = ","),
      digits = 2,
      caption = "Major District Years with >5% Enrollment Change"
    )
  } else {
    message("No major district year-over-year changes exceed 5%.")
  }
}
```

    ## WARNING: Found major district years with >5% year-over-year change:

|  Year | District            | Enrollment | YoY Change | YoY % |
|------:|:--------------------|-----------:|-----------:|------:|
| 2,015 | Cincinnati Public   |     32,651 |      2,341 |  7.72 |
| 2,017 | Cincinnati Public   |     33,652 |      1,787 |  5.61 |
| 2,021 | Cleveland Municipal |     34,785 |     -2,111 | -5.72 |

Major District Years with \>5% Enrollment Change

### Major District Summary Table

``` r
if (exists("major_district_trends") && nrow(major_district_trends) > 0) {
  # Create wide summary table
  district_summary <- major_district_trends %>%
    select(end_year, target_name, n_students) %>%
    pivot_wider(names_from = end_year, values_from = n_students)

  knitr::kable(
    district_summary,
    format.args = list(big.mark = ","),
    caption = "Major District Enrollment by Year"
  )
}
```

| target_name         |   2013 |   2015 |   2016 |   2017 |   2018 |   2019 |   2020 |   2021 |   2022 |   2023 |   2024 |   2025 |
|:--------------------|-------:|-------:|-------:|-------:|-------:|-------:|-------:|-------:|-------:|-------:|-------:|-------:|
| Akron Public        | 22,008 | 21,500 | 21,236 | 21,380 | 21,355 | 21,276 | 21,281 | 20,531 | 20,926 | 20,519 | 19,984 | 19,985 |
| Cincinnati Public   | 30,310 | 32,651 | 31,865 | 33,652 | 34,058 | 34,775 | 35,991 | 34,564 | 35,796 | 35,584 | 34,873 | 34,547 |
| Cleveland Municipal | 38,731 | 38,843 | 37,768 | 38,656 | 38,253 | 37,634 | 36,896 | 34,785 | 35,349 | 33,954 | 33,906 | 33,189 |
| Columbus City       | 49,508 | 50,380 | 49,184 | 50,370 | 50,271 | 48,985 | 48,715 | 46,645 | 45,586 | 45,352 | 45,381 | 46,630 |
| Toledo Public       | 21,874 | 21,820 | 21,877 | 22,879 | 23,108 | 23,308 | 22,854 | 22,300 | 22,047 | 21,837 | 21,083 | 21,247 |

Major District Enrollment by Year

## Data Quality Checks

### Missing Value Analysis

``` r
# Check for missing values in key columns
missing_summary <- all_enr %>%
  summarize(
    total_rows = n(),
    missing_district_irn = sum(is.na(district_irn)),
    missing_district_name = sum(is.na(district_name)),
    missing_n_students = sum(is.na(n_students)),
    missing_county = sum(is.na(county)),
    pct_missing_students = round(100 * sum(is.na(n_students)) / n(), 2)
  )

knitr::kable(
  missing_summary,
  col.names = c("Total Rows", "Missing IRN", "Missing Name", "Missing Students",
                "Missing County", "% Missing Students"),
  caption = "Missing Value Summary"
)
```

| Total Rows | Missing IRN | Missing Name | Missing Students | Missing County | % Missing Students |
|-----------:|------------:|-------------:|-----------------:|---------------:|-------------------:|
|     783969 |           0 |            0 |                0 |              0 |                  0 |

Missing Value Summary

### Missing Values by Year

``` r
missing_by_year <- all_enr %>%
  group_by(end_year) %>%
  summarize(
    total_rows = n(),
    missing_n_students = sum(is.na(n_students)),
    pct_missing = round(100 * missing_n_students / total_rows, 2),
    .groups = "drop"
  )

knitr::kable(
  missing_by_year,
  col.names = c("Year", "Total Rows", "Missing Students", "% Missing"),
  caption = "Missing Values by Year"
)
```

| Year | Total Rows | Missing Students | % Missing |
|-----:|-----------:|-----------------:|----------:|
| 2013 |      10909 |                0 |         0 |
| 2015 |      12896 |                0 |         0 |
| 2016 |      12875 |                0 |         0 |
| 2017 |      78675 |                0 |         0 |
| 2018 |      79027 |                0 |         0 |
| 2019 |      83980 |                0 |         0 |
| 2020 |      83678 |                0 |         0 |
| 2021 |      83561 |                0 |         0 |
| 2022 |      85164 |                0 |         0 |
| 2023 |      84892 |                0 |         0 |
| 2024 |      84429 |                0 |         0 |
| 2025 |      83883 |                0 |         0 |

Missing Values by Year

### Zero Enrollment Check

``` r
# Check for districts with zero total enrollment
zero_enrollment <- all_enr %>%
  filter(
    entity_type == "District",
    subgroup == "total_enrollment",
    grade_level == "TOTAL",
    n_students == 0
  ) %>%
  select(end_year, district_irn, district_name, county, n_students) %>%
  arrange(end_year, district_name)

if (nrow(zero_enrollment) > 0) {
  message(paste("Found", nrow(zero_enrollment), "district-years with zero enrollment:"))
  knitr::kable(
    head(zero_enrollment, 20),
    col.names = c("Year", "IRN", "District Name", "County", "Enrollment"),
    caption = "Districts with Zero Enrollment (first 20)"
  )
} else {
  message("No districts with zero enrollment found.")
}
```

    ## No districts with zero enrollment found.

### Duplicate Record Check

``` r
# Check for duplicate district-year-subgroup-grade combinations
duplicates <- all_enr %>%
  filter(entity_type == "District") %>%
  group_by(end_year, district_irn, subgroup, grade_level) %>%
  filter(n() > 1) %>%
  ungroup()

if (nrow(duplicates) > 0) {
  message(paste("WARNING: Found", nrow(duplicates), "duplicate records"))
  knitr::kable(
    head(duplicates, 10),
    caption = "Sample Duplicate Records"
  )
} else {
  message("No duplicate records found.")
}
```

    ## No duplicate records found.

### Subgroup Coverage by Year

``` r
# Check which subgroups are available each year
subgroup_coverage <- all_enr %>%
  filter(grade_level == "TOTAL") %>%
  group_by(end_year, subgroup) %>%
  summarize(
    n_records = n(),
    total_students = sum(n_students, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = end_year,
    values_from = n_records,
    values_fill = 0
  )

knitr::kable(
  subgroup_coverage,
  caption = "Subgroup Record Counts by Year"
)
```

| subgroup                   | total_students | 2013 | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | 2021 | 2022 | 2023 | 2024 | 2025 |
|:---------------------------|---------------:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|
| asian                      |          30276 |  321 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| black                      |         229308 |  403 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| hispanic                   |          66368 |  499 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| multiracial                |          70345 |  539 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| total_enrollment           |        1618918 |  611 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| white                      |        1258588 |  609 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| asian                      |          32899 |    0 |  317 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| black                      |         224502 |    0 |  387 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| disability                 |         215486 |    0 |  609 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| economically_disadvantaged |         692527 |    0 |  603 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| hispanic                   |          75084 |    0 |  506 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| multiracial                |          72423 |    0 |  535 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| native_american            |            752 |    0 |  241 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| total_enrollment           |        1597411 |    0 |  608 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| white                      |        1188463 |    0 |  607 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| asian                      |          34335 |    0 |    0 |  323 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| black                      |         222763 |    0 |    0 |  399 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| disability                 |         215907 |    0 |    0 |  607 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| economically_disadvantaged |         708298 |    0 |    0 |  607 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| hispanic                   |          78968 |    0 |    0 |  514 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| multiracial                |          74148 |    0 |    0 |  541 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| native_american            |            735 |    0 |    0 |  243 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| total_enrollment           |        1583183 |    0 |    0 |  607 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| white                      |        1169159 |    0 |    0 |  605 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| asian                      |          68705 |    0 |    0 |    0 | 1892 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| black                      |         450469 |    0 |    0 |    0 | 2384 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| disability                 |         438073 |    0 |    0 |    0 | 3711 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| economically_disadvantaged |        1474394 |    0 |    0 |    0 | 3726 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| hispanic                   |         162078 |    0 |    0 |    0 | 2473 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| multiracial                |         151199 |    0 |    0 |    0 | 2778 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| native_american            |            761 |    0 |    0 |    0 | 2279 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| total_enrollment           |        3169463 |    0 |    0 |    0 | 3743 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| white                      |        2314182 |    0 |    0 |    0 | 3685 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| asian                      |          72932 |    0 |    0 |    0 |    0 | 1937 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| black                      |         453364 |    0 |    0 |    0 |    0 | 2419 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| disability                 |         443458 |    0 |    0 |    0 |    0 | 3721 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| economically_disadvantaged |        1479354 |    0 |    0 |    0 |    0 | 3711 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| hispanic                   |         170428 |    0 |    0 |    0 |    0 | 2518 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| multiracial                |         156559 |    0 |    0 |    0 |    0 | 2801 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| native_american            |            841 |    0 |    0 |    0 |    0 | 2303 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| total_enrollment           |        3162113 |    0 |    0 |    0 |    0 | 3749 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| white                      |        2286519 |    0 |    0 |    0 |    0 | 3685 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |
| asian                      |          76565 |    0 |    0 |    0 |    0 |    0 | 1971 |    0 |    0 |    0 |    0 |    0 |    0 |
| black                      |         454032 |    0 |    0 |    0 |    0 |    0 | 2394 |    0 |    0 |    0 |    0 |    0 |    0 |
| disability                 |         451378 |    0 |    0 |    0 |    0 |    0 | 3714 |    0 |    0 |    0 |    0 |    0 |    0 |
| economically_disadvantaged |        1454465 |    0 |    0 |    0 |    0 |    0 | 3710 |    0 |    0 |    0 |    0 |    0 |    0 |
| english_learner            |          96060 |    0 |    0 |    0 |    0 |    0 | 2378 |    0 |    0 |    0 |    0 |    0 |    0 |
| hispanic                   |         179400 |    0 |    0 |    0 |    0 |    0 | 2550 |    0 |    0 |    0 |    0 |    0 |    0 |
| multiracial                |         160937 |    0 |    0 |    0 |    0 |    0 | 2806 |    0 |    0 |    0 |    0 |    0 |    0 |
| native_american            |            925 |    0 |    0 |    0 |    0 |    0 | 2263 |    0 |    0 |    0 |    0 |    0 |    0 |
| pacific_islander           |            953 |    0 |    0 |    0 |    0 |    0 | 2756 |    0 |    0 |    0 |    0 |    0 |    0 |
| total_enrollment           |        3151749 |    0 |    0 |    0 |    0 |    0 | 3740 |    0 |    0 |    0 |    0 |    0 |    0 |
| white                      |        2258150 |    0 |    0 |    0 |    0 |    0 | 3670 |    0 |    0 |    0 |    0 |    0 |    0 |
| asian                      |          78919 |    0 |    0 |    0 |    0 |    0 |    0 | 1952 |    0 |    0 |    0 |    0 |    0 |
| black                      |         451928 |    0 |    0 |    0 |    0 |    0 |    0 | 2402 |    0 |    0 |    0 |    0 |    0 |
| disability                 |         459109 |    0 |    0 |    0 |    0 |    0 |    0 | 3690 |    0 |    0 |    0 |    0 |    0 |
| economically_disadvantaged |        1399526 |    0 |    0 |    0 |    0 |    0 |    0 | 3687 |    0 |    0 |    0 |    0 |    0 |
| english_learner            |         103914 |    0 |    0 |    0 |    0 |    0 |    0 | 2383 |    0 |    0 |    0 |    0 |    0 |
| hispanic                   |         190574 |    0 |    0 |    0 |    0 |    0 |    0 | 2581 |    0 |    0 |    0 |    0 |    0 |
| multiracial                |         174945 |    0 |    0 |    0 |    0 |    0 |    0 | 2877 |    0 |    0 |    0 |    0 |    0 |
| native_american            |            798 |    0 |    0 |    0 |    0 |    0 |    0 | 2254 |    0 |    0 |    0 |    0 |    0 |
| pacific_islander           |           1129 |    0 |    0 |    0 |    0 |    0 |    0 | 2735 |    0 |    0 |    0 |    0 |    0 |
| total_enrollment           |        3141261 |    0 |    0 |    0 |    0 |    0 |    0 | 3726 |    0 |    0 |    0 |    0 |    0 |
| white                      |        2222715 |    0 |    0 |    0 |    0 |    0 |    0 | 3665 |    0 |    0 |    0 |    0 |    0 |
| asian                      |          79138 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 1975 |    0 |    0 |    0 |    0 |
| black                      |         438696 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2378 |    0 |    0 |    0 |    0 |
| disability                 |         447882 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3680 |    0 |    0 |    0 |    0 |
| economically_disadvantaged |        1355798 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3658 |    0 |    0 |    0 |    0 |
| english_learner            |         101443 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2366 |    0 |    0 |    0 |    0 |
| hispanic                   |         190912 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2586 |    0 |    0 |    0 |    0 |
| multiracial                |         169612 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2861 |    0 |    0 |    0 |    0 |
| native_american            |            804 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2324 |    0 |    0 |    0 |    0 |
| pacific_islander           |           1080 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2771 |    0 |    0 |    0 |    0 |
| total_enrollment           |        3028012 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3712 |    0 |    0 |    0 |    0 |
| white                      |        2127772 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3641 |    0 |    0 |    0 |    0 |
| asian                      |          81378 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2071 |    0 |    0 |    0 |
| black                      |         445001 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2463 |    0 |    0 |    0 |
| disability                 |         449776 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3718 |    0 |    0 |    0 |
| economically_disadvantaged |        1331551 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3732 |    0 |    0 |    0 |
| english_learner            |         108589 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2474 |    0 |    0 |    0 |
| hispanic                   |         203161 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2737 |    0 |    0 |    0 |
| multiracial                |         176552 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2968 |    0 |    0 |    0 |
| native_american            |            878 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2402 |    0 |    0 |    0 |
| pacific_islander           |           1167 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2842 |    0 |    0 |    0 |
| total_enrollment           |        3047057 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3738 |    0 |    0 |    0 |
| white                      |        2120732 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3708 |    0 |    0 |    0 |
| asian                      |          85836 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2095 |    0 |    0 |
| black                      |         445186 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2489 |    0 |    0 |
| disability                 |         460841 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3700 |    0 |    0 |
| economically_disadvantaged |        1388915 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3702 |    0 |    0 |
| english_learner            |         120433 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2464 |    0 |    0 |
| hispanic                   |         214861 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2762 |    0 |    0 |
| multiracial                |         182675 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2964 |    0 |    0 |
| native_american            |            836 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2327 |    0 |    0 |
| pacific_islander           |           1166 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2802 |    0 |    0 |
| total_enrollment           |        3038326 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3737 |    0 |    0 |
| white                      |        2088711 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3680 |    0 |    0 |
| asian                      |          89516 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2092 |    0 |
| black                      |         444182 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2470 |    0 |
| disability                 |         476315 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3676 |    0 |
| economically_disadvantaged |        1536920 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3678 |    0 |
| english_learner            |         133850 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2436 |    0 |
| hispanic                   |         228212 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2841 |    0 |
| multiracial                |         186526 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2969 |    0 |
| native_american            |            926 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2238 |    0 |
| pacific_islander           |           1241 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2777 |    0 |
| total_enrollment           |        3013532 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3706 |    0 |
| white                      |        2043742 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3654 |    0 |
| asian                      |          93094 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2068 |
| black                      |         445228 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2416 |
| disability                 |         482714 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3648 |
| economically_disadvantaged |        1773403 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3681 |
| english_learner            |         149375 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2442 |
| hispanic                   |         241769 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2852 |
| multiracial                |         191434 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3000 |
| native_american            |            934 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2213 |
| pacific_islander           |           1434 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 2748 |
| total_enrollment           |        2982335 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3685 |
| white                      |        1989536 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 |    0 | 3622 |

Subgroup Record Counts by Year

## Demographic Trend Analysis

### Statewide Demographic Composition

``` r
# Calculate statewide demographic percentages
demographics <- all_enr %>%
  filter(
    entity_type == "District",
    grade_level == "TOTAL",
    subgroup %in% c("white", "black", "hispanic", "asian", "multiracial", "total_enrollment")
  ) %>%
  group_by(end_year, subgroup) %>%
  summarize(
    total = sum(n_students, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = subgroup, values_from = total)

# Calculate percentages if columns exist
if ("total_enrollment" %in% names(demographics)) {
  demo_cols <- intersect(c("white", "black", "hispanic", "asian", "multiracial"), names(demographics))
  for (col in demo_cols) {
    demographics[[paste0(col, "_pct")]] <- round(100 * demographics[[col]] / demographics$total_enrollment, 1)
  }

  # Show percentage trends
  pct_cols <- paste0(demo_cols, "_pct")
  pct_cols <- pct_cols[pct_cols %in% names(demographics)]

  if (length(pct_cols) > 0) {
    knitr::kable(
      demographics %>% select(end_year, all_of(pct_cols)),
      caption = "Statewide Demographic Percentages by Year"
    )
  }
}
```

| end_year | white_pct | black_pct | hispanic_pct | asian_pct | multiracial_pct |
|---------:|----------:|----------:|-------------:|----------:|----------------:|
|     2013 |      77.7 |      14.2 |          4.1 |       1.9 |             4.3 |
|     2015 |      74.4 |      14.1 |          4.7 |       2.1 |             4.5 |
|     2016 |      73.8 |      14.1 |          5.0 |       2.2 |             4.7 |
|     2017 |      73.0 |      14.3 |          5.3 |       2.3 |             4.9 |
|     2018 |      72.3 |      14.5 |          5.5 |       2.4 |             5.1 |
|     2019 |      71.6 |      14.5 |          5.8 |       2.5 |             5.2 |
|     2020 |      70.7 |      14.5 |          6.2 |       2.6 |             5.7 |
|     2021 |      70.2 |      14.6 |          6.5 |       2.7 |             5.7 |
|     2022 |      69.5 |      14.7 |          6.8 |       2.8 |             5.9 |
|     2023 |      68.7 |      14.8 |          7.2 |       2.9 |             6.1 |
|     2024 |      67.8 |      14.8 |          7.7 |       3.1 |             6.3 |
|     2025 |      66.7 |      15.0 |          8.2 |       3.2 |             6.5 |

Statewide Demographic Percentages by Year

## Data Quality Issues Summary

``` r
issues <- list()

# Check for statewide jumps
if (exists("large_changes") && nrow(large_changes) > 0) {
  issues$statewide_jumps <- paste(
    "Statewide enrollment changes >5% detected in years:",
    paste(large_changes$end_year, collapse = ", ")
  )
}

# Check for district jumps
if (exists("large_district_changes") && nrow(large_district_changes) > 0) {
  issues$district_jumps <- paste(
    "Major district enrollment changes >5% detected:",
    nrow(large_district_changes), "instances"
  )
}

# Check for missing data
if (missing_summary$pct_missing_students > 5) {
  issues$missing_data <- paste(
    "High percentage of missing student counts:",
    missing_summary$pct_missing_students, "%"
  )
}

# Check for duplicates
if (nrow(duplicates) > 0) {
  issues$duplicates <- paste("Duplicate records found:", nrow(duplicates))
}

# Report issues
if (length(issues) > 0) {
  message("DATA QUALITY ISSUES DETECTED:")
  for (issue_name in names(issues)) {
    message(paste(" -", issues[[issue_name]]))
  }
} else {
  message("No major data quality issues detected.")
}
```

    ## DATA QUALITY ISSUES DETECTED:

    ##  - Major district enrollment changes >5% detected: 3 instances

## Session Information

``` r
sessionInfo()
```

    ## R version 4.5.2 (2025-10-31)
    ## Platform: x86_64-pc-linux-gnu
    ## Running under: Ubuntu 24.04.3 LTS
    ## 
    ## Matrix products: default
    ## BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
    ## LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
    ## 
    ## locale:
    ##  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
    ##  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
    ##  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
    ## [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
    ## 
    ## time zone: UTC
    ## tzcode source: system (glibc)
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## other attached packages:
    ## [1] tidyr_1.3.2        scales_1.4.0       ggplot2_4.0.1      dplyr_1.1.4       
    ## [5] ohschooldata_0.1.0
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] gtable_0.3.6       jsonlite_2.0.0     compiler_4.5.2     tidyselect_1.2.1  
    ##  [5] jquerylib_0.1.4    systemfonts_1.3.1  textshaping_1.0.4  readxl_1.4.5      
    ##  [9] yaml_2.3.12        fastmap_1.2.0      R6_2.6.1           labeling_0.4.3    
    ## [13] generics_0.1.4     curl_7.0.0         knitr_1.51         tibble_3.3.1      
    ## [17] desc_1.4.3         downloader_0.4.1   bslib_0.9.0        pillar_1.11.1     
    ## [21] RColorBrewer_1.1-3 rlang_1.1.7        cachem_1.1.0       xfun_0.55         
    ## [25] fs_1.6.6           sass_0.4.10        S7_0.2.1           cli_3.6.5         
    ## [29] pkgdown_2.2.0      withr_3.0.2        magrittr_2.0.4     digest_0.6.39     
    ## [33] grid_4.5.2         rappdirs_0.3.3     lifecycle_1.0.5    vctrs_0.7.0       
    ## [37] evaluate_1.0.5     glue_1.8.0         cellranger_1.1.0   farver_2.1.2      
    ## [41] codetools_0.2-20   ragg_1.5.0         httr_1.4.7         purrr_1.2.1       
    ## [45] rmarkdown_2.30     tools_4.5.2        pkgconfig_2.0.3    htmltools_0.5.9
