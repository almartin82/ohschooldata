# Download enrollment data from ODE Frequently Requested Data

Downloads enrollment data from Ohio Department of Education's Frequently
Requested Data page. This is the most reliable source for Ohio
enrollment data.

## Usage

``` r
download_ode_enrollment(end_year)
```

## Arguments

- end_year:

  School year end (2024 for 2023-24)

## Value

Raw data frame with enrollment data

## Details

The Excel file contains multiple sheets:

- data_notes: Notes (skip)

- fyYY_hdcnt_state: State-level totals

- fyYY_hdcnt_dist: District-level data

- fyYY_hdcnt_bldg: Building/school-level data

- fyYY_hdcnt_stem, fyYY_hdcnt_cs, fyYY_hdcnt_jvsd: Specialty schools
