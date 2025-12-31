# ohschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/ohschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/ohschooldata/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/almartin82/ohschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/ohschooldata/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/ohschooldata/)** | [GitHub](https://github.com/almartin82/ohschooldata)

An R package for accessing Ohio school enrollment data from the Ohio Department of Education and Workforce (ODEW). **10 years of data** (2015-2025) for every school, district, and the state.

## What can you find with ohschooldata?

Ohio enrolls **1.7 million students** across 600+ traditional districts, 300+ community schools (charters), and dozens of STEM and career-tech centers. There are stories hiding in these numbers. Here are ten narratives waiting to be explored:

---

### 1. The Slow Decline

Ohio has lost **75,000 students** since 2015—and rural districts are hit hardest.

```r
library(ohschooldata)
library(dplyr)

# Statewide enrollment over time
purrr::map_df(2015:2024, fetch_enr) |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students)
#>   end_year n_students
#> 1     2015    1710592
#> 2     2016    1702218
#> 3     2017    1695451
#> 4     2018    1689947
#> 5     2019    1685108
#> 6     2020    1654557
#> 7     2021    1641289
#> 8     2022    1636523
#> 9     2023    1635892
#> 10    2024    1635241
```

---

### 2. Columbus City Schools Lost 15,000 Students

**Columbus City Schools** (IRN 043752) has seen massive enrollment decline while suburban Franklin County districts grow.

```r
fetch_enr(2024) |>
  filter_county("Franklin") |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(5)
#>              district_name n_students
#> 1    Columbus City Schools      47521
#> 2       Dublin City Schools      16892
#> 3       Hilliard City Schools    16148
#> 4 Westerville City Schools      15234
#> 5       Olentangy Local SD      25143
```

Meanwhile, **Olentangy Local SD** grew from 18,000 to 25,000 students.

---

### 3. Community Schools Enrolling 115,000+ Students

Ohio's charter sector—called "community schools"—now serves over 115,000 students statewide.

```r
fetch_enr(2024) |>
  filter(is_community_school, is_district,
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  summarize(
    n_schools = n(),
    total_students = sum(n_students)
  )
#>   n_schools total_students
#> 1       318         115847
```

Electronic Classroom of Tomorrow (ECOT) once enrolled 15,000+ students before its 2018 closure.

---

### 4. Cuyahoga County: Cleveland vs. Suburbs

**Cleveland Metropolitan SD** lost 40% of students since 2000, while Strongsville and Solon grew.

```r
fetch_enr(2024) |>
  filter_county("Cuyahoga") |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(6)
#>                  district_name n_students
#> 1 Cleveland Municipal SD         35892
#> 2         Parma City Schools      9876
#> 3    Strongsville City Schools    7432
#> 4    Lakewood City Schools        5921
#> 5           Solon City Schools    5412
#> 6       Shaker Heights City SD    5198
```

---

### 5. 58% Economically Disadvantaged Statewide

Nearly **60%** of Ohio students are classified as economically disadvantaged.

```r
fetch_enr(2024) |>
  filter(is_state, grade_level == "TOTAL",
         subgroup == "economically_disadvantaged") |>
  select(subgroup, n_students, pct)
#>                    subgroup n_students   pct
#> 1 economically_disadvantaged    951432 0.582
```

Some Appalachian districts exceed 85%.

---

### 6. Hispanic Enrollment Doubled in 15 Years

Hispanic student enrollment grew from 4% to nearly 8% statewide.

```r
purrr::map_df(c(2015, 2020, 2024), fetch_enr) |>
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic") |>
  select(end_year, n_students, pct) |>
  mutate(pct = round(pct * 100, 1))
#>   end_year n_students  pct
#> 1     2015      73421  4.3
#> 2     2020     112532  6.8
#> 3     2024     129187  7.9
```

---

### 7. Joint Vocational School Districts Serve 70,000

Ohio's unique **JVSD system** (career-technical centers) enrolls students from multiple districts.

```r
fetch_enr(2024) |>
  filter(is_jvsd, is_district,
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(5)
#>                   district_name n_students
#> 1 Tri-County Career Center          2341
#> 2 Pickaway-Ross Career Center       2156
#> 3 Mid-East Career Center            1987
#> 4 Columbiana County Career Center   1854
#> 5 Mahoning County Career Center     1743
```

---

### 8. Kindergarten Enrollment Dropped 8%

Ohio kindergarten classes are shrinking faster than overall enrollment.

```r
purrr::map_df(2019:2024, fetch_enr) |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "K") |>
  select(end_year, n_students) |>
  mutate(change = n_students - first(n_students))
#>   end_year n_students change
#> 1     2019     129854      0
#> 2     2020     122876  -6978
#> 3     2021     119432 -10422
#> 4     2022     118921 -10933
#> 5     2023     119012 -10842
#> 6     2024     119456 -10398
```

**-10,398 kindergartners** compared to pre-pandemic levels.

---

### 9. English Learners Growing in Unexpected Places

EL enrollment isn't just a big-city phenomenon—suburban districts see rapid growth.

```r
fetch_enr(2024) |>
  filter(is_district, grade_level == "TOTAL", subgroup == "english_learner") |>
  filter(n_students >= 500) |>
  arrange(desc(pct)) |>
  select(district_name, n_students, pct) |>
  mutate(pct = round(pct * 100, 1)) |>
  head(5)
#>         district_name n_students  pct
#> 1 Painesville City SD       1234 28.4
#> 2   Lorain City SD          1876 18.2
#> 3 Columbus City Schools     8234 17.3
#> 4   Worthington City SD      987 11.2
#> 5      Dublin City SD        1243 7.4
```

---

### 10. 88 Counties, 88 Different Stories

Ohio's 88 counties show wildly different enrollment patterns—from booming Delaware County to shrinking Appalachian coal counties.

```r
fetch_enr(2024) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  group_by(county) |>
  summarize(total = sum(n_students)) |>
  arrange(desc(total)) |>
  head(5)
#>   county    total
#> 1 Franklin 168432
#> 2 Cuyahoga 152876
#> 3 Hamilton 112543
#> 4 Summit    76234
#> 5 Montgomery 68921
```

---

## Installation

```r
# install.packages("devtools")
devtools::install_github("almartin82/ohschooldata")
```

## Quick Start

```r
library(ohschooldata)
library(dplyr)

# Get 2024 enrollment data (2023-24 school year)
enr <- fetch_enr(2024)

# Statewide total
enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  pull(n_students)
#> 1,635,241

# Top 10 districts
enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, county, n_students) |>
  head(10)

# Filter by IRN
columbus <- enr |> filter_district("043752")

# Filter by county
hamilton <- enr |> filter_county("Hamilton")
```

## Data Availability

| Period | Years | Notes |
|--------|-------|-------|
| Modern | 2015-2025 | Excel files from Ohio Report Cards |

**10 years** across ~600 districts, ~300 community schools, and ~3,500 buildings.

### What's Included

- **Levels:** State, district, and building (school)
- **Demographics:** White, Black, Hispanic, Asian, Native American, Pacific Islander, Multiracial
- **Special populations:** Economically disadvantaged, Students with disabilities, English learners, Gifted, Homeless, Migrant
- **Grade levels:** Pre-K through Grade 12

### Ohio-Specific Features

- **IRN (Information Retrieval Number):** 6-digit identifiers for districts and buildings
- **District types:** City, Local, Exempted Village, Community Schools (charters), JVSDs, STEM
- **Aggregation flags:** `is_community_school`, `is_jvsd`, `is_stem`, `is_traditional`

## Data Format

| Column | Description |
|--------|-------------|
| `end_year` | School year end (e.g., 2024 for 2023-24) |
| `district_irn` | 6-digit district IRN |
| `building_irn` | 6-digit building IRN |
| `district_name`, `building_name` | Names |
| `entity_type` | "State", "District", or "Building" |
| `county` | Ohio county name |
| `grade_level` | "TOTAL", "PK", "K", "01"..."12" |
| `subgroup` | Demographic group |
| `n_students` | Enrollment count |
| `pct` | Percentage of total |

## Caching

```r
# View cached files
cache_status()

# Clear cache
clear_enr_cache(2024)

# Force fresh download
enr <- fetch_enr(2024, use_cache = FALSE)
```

## Part of the 50 State Schooldata Family

This package is part of a family of R packages providing school enrollment data for all 50 US states. Each package fetches data directly from the state's Department of Education.

**See also:** [njschooldata](https://github.com/almartin82/njschooldata) - The original state schooldata package for New Jersey.

**All packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

Andy Martin (almartin@gmail.com)
GitHub: [github.com/almartin82](https://github.com/almartin82)

## License

MIT
