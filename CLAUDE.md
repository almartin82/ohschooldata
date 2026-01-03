# Claude Code Instructions

## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source**
— the entire point of these packages is to provide STATE-LEVEL data
directly from state DOEs. Federal sources aggregate/transform data
differently and lose state-specific details. If a state DOE source is
broken, FIX IT or find an alternative STATE source — do not fall back to
federal data.

------------------------------------------------------------------------

## Ohio DOE Data Sources (Verified January 2026)

### PRIMARY Data Source (Recommended)

**ODE Frequently Requested Data - Enrollment** - URL:
`https://education.ohio.gov/Topics/Data/Frequently-Requested-Data/Enrollment-Data` -
Pattern:
`education.ohio.gov/getattachment/.../oct_hdcnt_fyYY.xls.aspx` - Format:
Excel file with multiple sheets

| Sheet                             | Description                |
|-----------------------------------|----------------------------|
| `fyYY_hdcnt_state`                | State-level totals         |
| `fyYY_hdcnt_dist`                 | District-level data        |
| `fyYY_hdcnt_bldg`                 | Building/school-level data |
| `fyYY_hdcnt_stem`, `_cs`, `_jvsd` | Specialty schools          |

**Fiscal Year Mapping:** - FY25 = 2024-25 school year (end_year =
2025) - FY24 = 2023-24 school year (end_year = 2024)

### Verified URLs (HTTP 200 as of Jan 2026)

- `https://education.ohio.gov/getattachment/Topics/Data/Frequently-Requested-Data/Enrollment-Data/oct_hdcnt_fy25.xls.aspx`
- `https://education.ohio.gov/getattachment/Topics/Data/Frequently-Requested-Data/Enrollment-Data/oct_hdcnt_fy24.xls.aspx`
- Historical data available back to FY16

### ALTERNATIVE Data Source (Report Card)

The Ohio School Report Card portal at
`reportcardstorage.education.ohio.gov` is **NOT RECOMMENDED** - files
frequently return 404 or require dynamic tokens.

------------------------------------------------------------------------

## Git Commits and PRs

- NEVER reference Claude, Claude Code, or AI assistance in commit
  messages
- NEVER reference Claude, Claude Code, or AI assistance in PR
  descriptions
- NEVER add Co-Authored-By lines mentioning Claude or Anthropic
- Keep commit messages focused on what changed, not how it was written

------------------------------------------------------------------------

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally
BEFORE opening a PR:

### CI Checks That Must Pass

| Check        | Local Command                                                                  | What It Tests                                  |
|--------------|--------------------------------------------------------------------------------|------------------------------------------------|
| R-CMD-check  | `devtools::check()`                                                            | Package builds, tests pass, no errors/warnings |
| Python tests | `pytest tests/test_pyohschooldata.py -v`                                       | Python wrapper works correctly                 |
| pkgdown      | [`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html) | Documentation and vignettes render             |

### Quick Commands

``` r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pyohschooldata && pytest tests/test_pyohschooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

Before opening a PR, verify: - \[ \] `devtools::check()` — 0 errors, 0
warnings - \[ \] `pytest tests/test_pyohschooldata.py` — all tests
pass - \[ \]
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
— builds without errors - \[ \] Vignettes render (no `eval=FALSE` hacks)

------------------------------------------------------------------------

## LIVE Pipeline Testing

This package includes `tests/testthat/test-pipeline-live.R` with LIVE
network tests.

### Test Categories:

1.  URL Availability - HTTP 200 checks
2.  File Download - Verify actual file (not HTML error)
3.  File Parsing - readxl/readr succeeds
4.  Column Structure - Expected columns exist
5.  get_raw_enr() - Raw data function works
6.  Data Quality - No Inf/NaN, non-negative counts
7.  Aggregation - State total \> 0
8.  Output Fidelity - tidy=TRUE matches raw

### Running Tests:

``` r
devtools::test(filter = "pipeline-live")
```

See `state-schooldata/CLAUDE.md` for complete testing framework
documentation.
