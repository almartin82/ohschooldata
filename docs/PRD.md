# Product Requirements Document: ohschooldata

## Overview

`ohschooldata` is an R package for downloading and processing school data from the Ohio Department of Education and Workforce (ODEW). It provides a consistent interface for fetching enrollment data and transforming it into tidy format for analysis.

## Data Source

- **Primary Source**: Ohio Department of Education and Workforce (ODEW)
- **Data Portal**: https://education.ohio.gov/Topics/Data
- **Data System**: EMIS (Education Management Information System)

## Ohio School System Structure

### Identification System
- **IRN (Information Retrieval Number)**: 6-digit identifier for districts and schools
- Districts and schools each have unique IRNs
- Format: XXXXXX (6 digits)

### District Types (~1,037 total)
- **City School Districts**: Urban districts, typically larger
- **Local School Districts**: Suburban and rural districts
- **Exempted Village School Districts**: Historical designation, operate independently
- **Joint Vocational School Districts (JVSDs)**: Career-technical education centers
- **Community Schools (Charter Schools)**: Publicly funded, independently operated
- **STEM Schools**: Science, technology, engineering, and math focused

### Geographic Organization
- 88 counties
- Educational Service Centers (ESCs) provide regional support
- Information Technology Centers (ITCs) serve as data intermediaries

## Key Data Available

### Enrollment Data
- Total enrollment by district/school
- Grade-level enrollment (PK-12)
- Demographic breakdowns (race/ethnicity, gender)
- Special populations (IEP, LEP, economically disadvantaged)

### EMIS Data Collections
- **October Count**: Official fall enrollment snapshot
- **Graduation Data**: Four-year and five-year rates
- **Staff Data**: Teacher and administrator information
- **Financial Data**: Expenditure and revenue reports

### Report Card Data
- Performance Index scores
- Achievement component scores
- Gap Closing metrics
- Graduation rates
- Prepared for Success indicators

## Market Context

### ORC 5705.391 - Five-Year Forecast Requirement
Ohio Revised Code 5705.391 mandates that all school districts submit:
- Five-year financial forecasts
- Updated twice annually (October and May)
- Must include assumptions and explanations
- Treasurer certification required

This creates a **strong forcing function** for districts to:
- Accurately project enrollment
- Plan for demographic shifts
- Justify levy requests with data

### Competitive Landscape
- **Cropper GIS**: Active in the Ohio school data market
- Provides enrollment projections and boundary analysis
- Strong presence in levy planning support

### Sales Environment
- **High bid threshold**: $77,250 (ORC 3313.46)
- Districts can purchase services under this threshold without competitive bidding
- Makes sales cycle faster for appropriately priced solutions

## Technical Requirements

### Core Functions

```r
# Main enrollment fetch function
fetch_enr(end_year, tidy = TRUE, use_cache = TRUE)

# Raw data download
get_raw_enr(end_year)

# Data processing
process_enr(df, end_year)

# Tidying functions
tidy_enr(df)
id_enr_aggs(df)
```

### Data Schema

**Enrollment Output Columns:**
- `irn`: 6-digit district/school identifier
- `entity_name`: District or school name
- `entity_type`: "District", "School", "State"
- `county`: Ohio county name
- `end_year`: School year end (e.g., 2024 for 2023-24)
- `grade_level`: Grade level or "TOTAL"
- `subgroup`: Demographic or population subgroup
- `n_students`: Student count
- `pct`: Percentage of total

### Caching Strategy
- Cache downloaded files locally using `rappdirs`
- Default cache expiry: 30 days
- Allow forced refresh with `use_cache = FALSE`
- Provide cache management functions

## Implementation Phases

### Phase 1: Core Enrollment
- [ ] Implement modern format data fetching (recent years)
- [ ] Parse IRN identifiers correctly
- [ ] Create tidy output format
- [ ] Implement caching layer

### Phase 2: Historical Data
- [ ] Handle legacy data formats
- [ ] Map historical column layouts
- [ ] Normalize across years

### Phase 3: Extended Data
- [ ] Report card data
- [ ] Financial data (five-year forecasts)
- [ ] Staff data

## Data Quality Notes

### Known Issues
- Suppression markers for small cell sizes (typically < 10)
- Varying column names across years
- Community school data may be incomplete in some years

### Validation Approach
- Cross-check totals against published state summaries
- Flag implausible year-over-year changes
- Document known data gaps

## References

- Ohio Department of Education: https://education.ohio.gov
- EMIS Manual: https://education.ohio.gov/Topics/Data/EMIS
- Report Card Resources: https://reportcard.education.ohio.gov
- ORC 5705.391 (Five-Year Forecast): https://codes.ohio.gov/ohio-revised-code/section-5705.391
- ORC 3313.46 (Bidding Requirements): https://codes.ohio.gov/ohio-revised-code/section-3313.46
