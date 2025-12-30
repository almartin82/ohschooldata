# Download modern format ODEW enrollment data

Downloads enrollment data from the Ohio School Report Cards portal.
Modern format (2015+) uses Excel files with consistent naming.

## Usage

``` r
get_raw_enr_modern(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Raw data frame with district and building enrollment

## Details

Note: Ohio uses dynamic tokens for file access which may cause downloads
to fail. If automated download fails, you may need to:

1.  Visit https://reportcard.education.ohio.gov/download

2.  Select year and download Enrollment files manually

3.  Use import_local_enrollment() to load the downloaded files
