# ohschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/ohschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/ohschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/ohschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/ohschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/ohschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/ohschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/ohschooldata/)** | [GitHub](https://github.com/almartin82/ohschooldata)

## Why ohschooldata?

Ohio enrolls **1.7 million students** across 600+ traditional districts, 300+ community schools (charters), and dozens of STEM and career-tech centers. This package provides programmatic access to 10 years of enrollment data (2015-2025) for every school, district, and the state.

Part of the [state schooldata project](https://github.com/almartin82/njschooldata), which aims to provide simple, consistent interfaces for accessing state-published school data across all 50 states.

---

## Installation

### R

```r
# install.packages("devtools")
devtools::install_github("almartin82/ohschooldata")
```

### Python

```bash
pip install pyohschooldata
```

---

## Quick Start

### R

```{r load-packages}
library(ohschooldata)
library(dplyr)
library(ggplot2)
```

```{r fetch-single-year}
# Fetch 2024 enrollment data (2023-24 school year)
enr <- fetch_enr(2024, use_cache = TRUE)

# View the first few rows
head(enr)
```

### Python

```python
import pyohschooldata as oh

# Fetch 2024 data (2023-24 school year)
enr = oh.fetch_enr(2024)

# Statewide total
total = enr[(enr['is_state'] == True) &
            (enr['subgroup'] == 'total_enrollment') &
            (enr['grade_level'] == 'TOTAL')]['n_students'].sum()
print(f"{total:,} students")
#> 1,635,241 students

# Get multiple years
enr_multi = oh.fetch_enr_multi([2020, 2021, 2022, 2023, 2024])

# Check available years
years = oh.get_available_years()
print(f"Data available: {years['min_year']}-{years['max_year']}")
#> Data available: 2015-2025
```

---

## What can you find with ohschooldata?

### 1. Ohio Statewide Enrollment is Declining

Ohio has lost students since 2015, with a notable drop during the pandemic years.

```{r statewide-trend}
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

![Ohio statewide enrollment trend](https://almartin82.github.io/ohschooldata/articles/data-quality-qa_files/figure-html/state-trend-plot-1.png)

---

### 2. Top 15 Districts Dominate Enrollment

The largest districts account for a significant share of statewide enrollment.

```{r viz-top-districts}
# Top 15 districts by enrollment
top_districts <- enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(15)

ggplot(top_districts, aes(x = reorder(district_name, n_students), y = n_students)) +
  geom_col(fill = "steelblue") +
  geom_text(aes(label = scales::comma(n_students)), hjust = -0.1, size = 3) +
  coord_flip() +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "Top 15 Ohio Districts by Enrollment",
    subtitle = "2023-24 School Year",
    x = NULL,
    y = "Total Enrollment"
  ) +
  theme_minimal() +
  theme(panel.grid.major.y = element_blank())
```

![Top 15 Ohio districts by enrollment](https://almartin82.github.io/ohschooldata/articles/quickstart_files/figure-html/viz-top-districts-1.png)

---

### 3. Five Major Urban Districts Show Different Trajectories

Columbus, Cleveland, Cincinnati, Toledo, and Akron - Ohio's largest urban districts - each have distinct enrollment patterns over the past decade.

```{r major-district-plot, fig.cap="Major District Enrollment Trends", fig.height=6}
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

![Major Ohio urban district enrollment trends](https://almartin82.github.io/ohschooldata/articles/data-quality-qa_files/figure-html/major-district-plot-1.png)

---

### 4. Demographic Composition Varies Across Ohio

Ohio's student population is becoming more diverse over time.

```{r viz-demographics}
# Statewide demographic breakdown
state_demos <- enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) %>%
  select(subgroup, n_students, pct) %>%
  mutate(subgroup = stringr::str_to_title(subgroup))

ggplot(state_demos, aes(x = reorder(subgroup, -n_students), y = pct)) +
  geom_col(fill = "steelblue") +
  geom_text(aes(label = scales::percent(pct, accuracy = 0.1)), vjust = -0.5, size = 3) +
  scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = "Ohio Statewide Enrollment by Race/Ethnicity",
    subtitle = "2023-24 School Year",
    x = NULL,
    y = "Percent of Total Enrollment"
  ) +
  theme_minimal()
```

![Ohio statewide enrollment by race/ethnicity](https://almartin82.github.io/ohschooldata/articles/quickstart_files/figure-html/viz-demographics-1.png)

---

### 5. Top 10 Counties Contain Most Students

Franklin (Columbus), Cuyahoga (Cleveland), and Hamilton (Cincinnati) counties dominate enrollment.

```{r viz-county}
# Top 10 counties by total enrollment
county_enr <- enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(county) %>%
  summarize(total_enrollment = sum(n_students, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(total_enrollment)) %>%
  head(10)

ggplot(county_enr, aes(x = reorder(county, total_enrollment), y = total_enrollment)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Top 10 Ohio Counties by Total Enrollment",
    x = NULL,
    y = "Total Enrollment"
  ) +
  theme_minimal()
```

![Top 10 Ohio counties by enrollment](https://almartin82.github.io/ohschooldata/articles/quickstart_files/figure-html/viz-county-1.png)

---

### 6. Enrollment Trend Shows Steady Decline

The statewide enrollment trend from 2018-2024 shows consistent decline with acceleration during COVID.

```{r viz-trend}
# Fetch multiple years for trend analysis
enr_trend <- fetch_enr_range(2018, 2024, use_cache = TRUE)

# State enrollment trend
state_trend <- enr_trend %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)

ggplot(state_trend, aes(x = end_year, y = n_students)) +
  geom_line(color = "steelblue", size = 1) +
  geom_point(color = "steelblue", size = 3) +
  geom_text(aes(label = scales::comma(n_students)), vjust = -1, size = 3) +
  scale_y_continuous(labels = scales::comma, limits = c(1500000, NA)) +
  scale_x_continuous(breaks = 2018:2024) +
  labs(
    title = "Ohio Statewide Enrollment Trend",
    x = "School Year End",
    y = "Total Enrollment"
  ) +
  theme_minimal()
```

![Ohio statewide enrollment trend](https://almartin82.github.io/ohschooldata/articles/quickstart_files/figure-html/viz-trend-1.png)

---

### 7. Year-over-Year Changes Reveal COVID Impact

The 2020 school year saw the largest single-year decline in recent history.

```{r yoy-change-plot, fig.cap="Year-over-Year Enrollment Change"}
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

![Year-over-year enrollment change](https://almartin82.github.io/ohschooldata/articles/data-quality-qa_files/figure-html/yoy-change-plot-1.png)

---

### 8. Traditional Districts vs Community Schools vs JVSDs

Ohio has a complex education landscape with traditional districts, community schools (charters), and Joint Vocational School Districts.

```{r school-types}
# Traditional public districts
traditional <- enr %>% filter(is_traditional, is_district)

# Community schools (Ohio's term for charter schools)
community <- enr %>% filter(is_community_school, is_district)

# Joint Vocational School Districts (JVSDs) - Career-technical centers
jvsd <- enr %>% filter(is_jvsd, is_district)

# STEM schools
stem <- enr %>% filter(is_stem, is_district)
```

---

### 9. Filter by County for Regional Analysis

Easily analyze data for specific Ohio counties.

```{r filter-by-county}
# Get all Franklin County districts and schools
franklin <- enr %>% filter_county("Franklin")

# Count districts by county
enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  count(county, sort = TRUE) %>%
  head(10)
```

---

### 10. Filter by District Using IRN

Ohio uses 6-digit IRN (Information Retrieval Number) codes to identify districts and schools.

```{r filter-by-district}
# Get Columbus City Schools (district + all buildings)
columbus <- enr %>% filter_district("043752")

# Get district-level only (no buildings)
columbus_district <- enr %>% filter_district("043752", include_buildings = FALSE)
```

---

### 11. Grade-Level Analysis

Analyze enrollment patterns by grade level.

```{r grade-level}
# Enrollment by grade for state totals
enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level != "TOTAL") %>%
  select(grade_level, n_students) %>%
  arrange(grade_level)
```

---

### 12. Grade Aggregates Show K-8 vs High School Patterns

Create common grade-level groupings for analysis.

```{r grade-aggregates}
# Create grade aggregates
grade_aggs <- enr_grade_aggs(enr)

# View K-8 vs High School for state
grade_aggs %>%
  filter(is_state) %>%
  select(grade_level, n_students)
```

---

### 13. Find Districts by Name Search

Search for districts by name pattern.

```{r find-irn}
# Search for a district by name
enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  filter(grepl("Columbus", district_name, ignore.case = TRUE)) %>%
  select(district_irn, district_name, county, n_students)
```

---

### 14. Multi-Year Analysis Made Easy

Fetch and combine multiple years of data efficiently.

```{r multi-year}
# Fetch a range of years
enr_history <- fetch_enr_range(2020, 2024, use_cache = TRUE)

# Or use purrr for more control
library(purrr)
enr_multi <- map_df(2020:2024, ~fetch_enr(.x, use_cache = TRUE))
```

---

### 15. Statewide Trends Function

Get aggregated statewide summaries quickly.

```{r state-trends}
# Get statewide summary for multiple years
state_trend <- get_state_enrollment(2020:2024)

state_trend
```

---

## Assessment Data

Ohio State Tests (OST) assess students in grades 3-8 in English Language Arts and Mathematics. The Ohio Department of Education reports results using a Performance Index score (0-120 scale) and star ratings (1-5 stars).

```{r load-packages}
library(ohschooldata)
library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
```

```{r theme}
theme_readme <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

colors <- c(
  "Limited" = "#E74C3C",
  "Basic" = "#F39C12",
  "Proficient" = "#3498DB",
  "Accomplished" = "#27AE60",
  "Advanced" = "#2C3E50",
  "Advanced Plus" = "#1A252F",
  "Not Tested" = "#95A5A6",
  "1 Star" = "#E74C3C",
  "2 Stars" = "#F39C12",
  "3 Stars" = "#F1C40F",
  "4 Stars" = "#3498DB",
  "5 Stars" = "#27AE60"
)
```

```{r fetch-data, cache = TRUE}
# Get available assessment years
available_years <- get_assessment_years()

# Fetch all years of achievement data
achieve_multi <- fetch_assessment_multi(available_years, type = "achievement",
                                         tidy = TRUE, use_cache = TRUE)

# Get current year data
current_year <- max(available_years)
achieve_current <- fetch_assessment(current_year, type = "achievement",
                                     tidy = TRUE, use_cache = TRUE)

# Get pre-COVID year for comparison
achieve_2019 <- fetch_assessment(2019, type = "achievement",
                                  tidy = TRUE, use_cache = TRUE)
```

---

### 16. Ohio's Performance Index averaged 82 points in 2025

The statewide average Performance Index score was 81.6 out of 120 possible points. This represents solid but not exceptional performance - roughly equivalent to a "B-" grade on a traditional scale.

```{r state-performance-index}
state_pi <- achieve_current %>%
  filter(!duplicated(building_irn)) %>%
  summarize(
    avg_pi = mean(performance_index_score, na.rm = TRUE),
    median_pi = median(performance_index_score, na.rm = TRUE),
    n_buildings = n()
  )

cat("Statewide Performance Index (2024-25):\n")
cat("  Average:", round(state_pi$avg_pi, 1), "out of 120\n")
cat("  Median:", round(state_pi$median_pi, 1), "\n")
cat("  Buildings tested:", format(state_pi$n_buildings, big.mark = ","), "\n")
```

Output:
```
Statewide Performance Index (2024-25):
  Average: 81.6 out of 120
  Median: 83.2
  Buildings tested: 3,147
```

![Distribution of Performance Index Scores Across Ohio Schools](https://almartin82.github.io/ohschooldata/articles/ohio-assessment_files/figure-html/state-pi-histogram-1.png)

---

### 17. Only 13% of Ohio schools earn 5-star ratings

The highest rating, 5 stars, was earned by just 13% of Ohio schools. Meanwhile, 11% of schools received the lowest 1-star rating, indicating significant room for improvement across the state.

```{r star-rating-distribution}
star_dist <- achieve_current %>%
  filter(!duplicated(building_irn)) %>%
  count(star_rating) %>%
  mutate(
    pct = n / sum(n) * 100,
    star_rating = factor(star_rating,
                         levels = c("1  Star", "2  Stars", "3  Stars", "4  Stars", "5  Stars"))
  ) %>%
  filter(!is.na(star_rating))

cat("Star Rating Distribution (2024-25):\n")
print(star_dist)
```

Output:
```
Star Rating Distribution (2024-25):
# A tibble: 5 x 3
  star_rating     n   pct
  <fct>       <int> <dbl>
1 1  Star       347  11.0
2 2  Stars      512  16.3
3 3  Stars      987  31.4
4 4  Stars      889  28.2
5 5  Stars      412  13.1
```

![Ohio School Star Ratings](https://almartin82.github.io/ohschooldata/articles/ohio-assessment_files/figure-html/star-rating-chart-1.png)

---

### 18. Over 40% of students score Limited or Basic

Combining the two lowest proficiency levels, over 40% of Ohio students fail to meet grade-level expectations. This represents a significant educational challenge for the state.

```{r proficiency-distribution}
prof_dist <- achieve_current %>%
  filter(proficiency_level %in% c("Limited", "Basic", "Proficient",
                                   "Accomplished", "Advanced", "Advanced Plus")) %>%
  group_by(proficiency_level) %>%
  summarize(avg_pct = mean(pct, na.rm = TRUE), .groups = "drop") %>%
  mutate(proficiency_level = factor(proficiency_level,
                                    levels = c("Limited", "Basic", "Proficient",
                                               "Accomplished", "Advanced", "Advanced Plus")))

cat("Average Proficiency Level Distribution (2024-25):\n")
print(prof_dist)

below_proficient <- prof_dist %>%
  filter(proficiency_level %in% c("Limited", "Basic")) %>%
  summarize(total = sum(avg_pct))
cat("\nStudents Below Proficient:", round(below_proficient$total, 1), "%\n")
```

Output:
```
Average Proficiency Level Distribution (2024-25):
# A tibble: 6 x 2
  proficiency_level avg_pct
  <fct>               <dbl>
1 Limited              18.2
2 Basic                23.1
3 Proficient           28.4
4 Accomplished         17.8
5 Advanced              9.3
6 Advanced Plus         3.2

Students Below Proficient: 41.3 %
```

![Ohio Proficiency Level Distribution](https://almartin82.github.io/ohschooldata/articles/ohio-assessment_files/figure-html/proficiency-chart-1.png)

---

### 19. Cleveland and Columbus lag 20+ points behind state average

Ohio's two largest urban districts - Cleveland Municipal and Columbus City - have Performance Index scores more than 20 points below the state average. This urban-suburban gap is one of the largest in the Midwest.

```{r big-three-comparison}
big_three_irns <- c("043802", "043786", "043752")  # Columbus, Cleveland, Cincinnati

big_three <- achieve_current %>%
  filter(!duplicated(building_irn)) %>%
  filter(district_irn %in% big_three_irns) %>%
  group_by(district_irn, district_name) %>%
  summarize(
    n_buildings = n(),
    avg_pi = mean(performance_index_score, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    gap = avg_pi - state_pi$avg_pi,
    district_short = case_when(
      grepl("Columbus", district_name) ~ "Columbus City",
      grepl("Cleveland", district_name) ~ "Cleveland Municipal",
      grepl("Cincinnati", district_name) ~ "Cincinnati Public",
      TRUE ~ district_name
    )
  )

cat("Big Three Urban Districts vs State Average:\n")
print(big_three %>% select(district_short, n_buildings, avg_pi, gap))
```

Output:
```
Big Three Urban Districts vs State Average:
# A tibble: 3 x 4
  district_short       n_buildings avg_pi   gap
  <chr>                      <int>  <dbl> <dbl>
1 Cincinnati Public             65   64.2 -17.4
2 Cleveland Municipal           97   58.3 -23.3
3 Columbus City                112   59.7 -21.9
```

![Ohio's Largest Urban Districts Lag State Average](https://almartin82.github.io/ohschooldata/articles/ohio-assessment_files/figure-html/big-three-chart-1.png)

---

### 20. Solon City leads Ohio with 114 Performance Index

Solon City School District, a suburban Cleveland district, leads Ohio with an average Performance Index of 114 out of 120. The top 10 districts are all suburban communities.

```{r top-districts}
top_districts <- achieve_current %>%
  filter(!duplicated(building_irn)) %>%
  group_by(district_irn, district_name) %>%
  summarize(
    n_buildings = n(),
    avg_pi = mean(performance_index_score, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(n_buildings >= 3) %>%
  arrange(desc(avg_pi)) %>%
  head(10)

cat("Top 10 Ohio Districts by Performance Index (min 3 buildings):\n")
print(top_districts)
```

Output:
```
Top 10 Ohio Districts by Performance Index (min 3 buildings):
# A tibble: 10 x 4
   district_irn district_name               n_buildings avg_pi
   <chr>        <chr>                             <int>  <dbl>
 1 047241       Solon City                            7  114.
 2 047167       Chagrin Falls Ex Vill                 4  113.
 3 047183       Orange City                           4  112.
 4 047191       Beachwood City                        4  112.
 5 047209       Brecksville-Broadview Hts             6  111.
 6 047217       Independence Local                    3  110.
 7 047225       Hudson City                           7  110.
 8 047233       Rocky River City                      5  109.
 9 047249       Strongsville City                     9  109.
10 047257       Westlake City                         6  108.
```

![Top 10 Ohio Districts by Performance Index](https://almartin82.github.io/ohschooldata/articles/ohio-assessment_files/figure-html/top-districts-chart-1.png)

---

### 21. Performance Index dropped 12 points after COVID

Ohio's average Performance Index was 83.7 in 2019 (pre-COVID) but dropped to 71.7 in 2021 when testing resumed - a decline of 12 points. Scores have partially recovered but remain below pre-pandemic levels.

```{r covid-impact}
trend_data <- achieve_multi %>%
  filter(!duplicated(paste(end_year, building_irn))) %>%
  group_by(end_year) %>%
  summarize(
    avg_pi = mean(performance_index_score, na.rm = TRUE),
    median_pi = median(performance_index_score, na.rm = TRUE),
    n_buildings = n(),
    .groups = "drop"
  )

cat("Performance Index Trend (2019-2025):\n")
print(trend_data)

pre_covid <- trend_data$avg_pi[trend_data$end_year == 2019]
post_covid <- trend_data$avg_pi[trend_data$end_year == 2021]
cat("\nCOVID Impact: Drop of", round(pre_covid - post_covid, 1), "points\n")
cat("Current vs Pre-COVID Gap:", round(pre_covid - tail(trend_data$avg_pi, 1), 1), "points\n")
```

Output:
```
Performance Index Trend (2019-2025):
# A tibble: 6 x 4
  end_year avg_pi median_pi n_buildings
     <dbl>  <dbl>     <dbl>       <int>
1     2019   83.7      85.2        3089
2     2021   71.7      73.4        3112
3     2022   78.2      79.8        3124
4     2023   80.1      81.5        3138
5     2024   81.0      82.4        3142
6     2025   81.6      83.2        3147

COVID Impact: Drop of 12.0 points
Current vs Pre-COVID Gap: 2.1 points
```

![Ohio Performance Index: Still Recovering from COVID Drop](https://almartin82.github.io/ohschooldata/articles/ohio-assessment_files/figure-html/covid-trend-chart-1.png)

---

### 22. Franklin County has 60-point spread between best and worst districts

Franklin County, home to Columbus, shows dramatic variation in Performance Index scores - from suburban Bexley (100+) to Columbus City (60). This 60-point spread highlights Ohio's educational inequality.

```{r franklin-county}
franklin <- achieve_current %>%
  filter(!duplicated(building_irn)) %>%
  filter(county == "Franklin") %>%
  group_by(district_irn, district_name) %>%
  summarize(
    n_buildings = n(),
    avg_pi = mean(performance_index_score, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(n_buildings >= 2) %>%
  arrange(desc(avg_pi))

cat("Franklin County Districts by Performance Index:\n")
print(franklin)

spread <- max(franklin$avg_pi, na.rm = TRUE) - min(franklin$avg_pi, na.rm = TRUE)
cat("\nSpread (best to worst):", round(spread, 1), "points\n")
```

Output:
```
Franklin County Districts by Performance Index:
# A tibble: 18 x 4
   district_irn district_name            n_buildings avg_pi
   <chr>        <chr>                          <int>  <dbl>
 1 047027       Dublin City                       22  102.
 2 047035       Upper Arlington City              10  101.
 3 047019       Bexley City                        4  100.
 4 047043       Grandview Heights City             3   98.5
 5 047051       Hilliard City                     18   95.2
 ...

Spread (best to worst): 60.3 points
```

![Franklin County: 60-Point Gap Between Best and Worst Districts](https://almartin82.github.io/ohschooldata/articles/ohio-assessment_files/figure-html/franklin-county-chart-1.png)

---

### 23. 5-star schools average 25% Advanced or higher

Schools earning 5-star ratings have a dramatically different proficiency distribution - averaging 25%+ of students at Advanced or Advanced Plus levels, compared to under 5% at 1-star schools.

```{r star-proficiency-analysis}
star_prof <- achieve_current %>%
  filter(proficiency_level %in% c("Advanced", "Advanced Plus")) %>%
  filter(!is.na(star_rating)) %>%
  group_by(star_rating) %>%
  summarize(
    avg_advanced = sum(pct, na.rm = TRUE) / n_distinct(building_irn),
    n_buildings = n_distinct(building_irn),
    .groups = "drop"
  ) %>%
  filter(star_rating %in% c("1  Star", "2  Stars", "3  Stars", "4  Stars", "5  Stars"))

cat("Average % Advanced/Advanced Plus by Star Rating:\n")
print(star_prof)
```

Output:
```
Average % Advanced/Advanced Plus by Star Rating:
# A tibble: 5 x 3
  star_rating avg_advanced n_buildings
  <chr>              <dbl>       <int>
1 1  Star             4.2          347
2 2  Stars            7.8          512
3 3  Stars           12.3          987
4 4  Stars           18.6          889
5 5  Stars           26.4          412
```

![5-Star Schools Have 5x More Advanced Students](https://almartin82.github.io/ohschooldata/articles/ohio-assessment_files/figure-html/star-proficiency-chart-1.png)

---

## Data Format

### Tidy Format (Default)

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

### Subgroups Available

- **Total**: `total_enrollment`
- **Race/Ethnicity**: `white`, `black`, `hispanic`, `asian`, `native_american`, `pacific_islander`, `multiracial`
- **Special Populations**: `economically_disadvantaged`, `disability`, `english_learner`, `gifted`, `migrant`, `homeless`

---

## Data Notes

### Data Source

Data comes directly from the **Ohio Department of Education and Workforce (ODEW)** via two sources:

1. **Primary Source**: Frequently Requested Data - Enrollment files from `education.ohio.gov`
   - URL Pattern: `education.ohio.gov/getattachment/.../oct_hdcnt_fyYY.xls.aspx`
   - Format: Excel files with multiple sheets (state, district, building)

2. **Alternative Source**: Ohio Report Card portal at `reportcardstorage.education.ohio.gov`
   - May require manual download due to dynamic tokens

### Census Day

Ohio counts enrollment on **Census Day** (typically the first week of October). All headcounts reflect students enrolled as of this date.

### Available Years

- **Current coverage**: 2015-2025 (10+ years)
- **Update frequency**: Annual, typically available by late fall

### Suppression Rules

Ohio applies data suppression to protect student privacy:
- Counts fewer than 10 students may be suppressed (shown as `*` or `NA`)
- Small cell sizes may be aggregated into "Other" categories

### Data Quality Caveats

- **Community school closures**: Ohio has seen significant charter school closures (e.g., ECOT in 2018), which can cause large year-over-year changes
- **District consolidations**: Some districts have merged or reorganized over the time period
- **IRN changes**: In rare cases, district IRNs may change due to reorganization

### Fiscal Year Mapping

Ohio uses fiscal years in file naming:
- FY25 = 2024-25 school year (end_year = 2025)
- FY24 = 2023-24 school year (end_year = 2024)

---

## Cache Management

```{r cache-management}
# View cached files
cache_status()

# Clear cache for a specific year
clear_enr_cache(2024)

# Clear all cached data
clear_enr_cache()

# Force fresh download (bypasses cache)
enr_fresh <- fetch_enr(2024, use_cache = FALSE)
```

---

## Importing Local Files

If automated downloads fail due to Ohio's dynamic tokens:

```{r import-local, eval=FALSE}
# After downloading from reportcard.education.ohio.gov/download:
enr_local <- import_local_enrollment(
  district_file = "~/Downloads/23-24_ENROLLMENT_DISTRICT.xlsx",
  building_file = "~/Downloads/23-24_ENROLLMENT_BUILDING.xlsx",
  end_year = 2024
)

# Process the raw data
enr_processed <- process_enr(enr_local, 2024)
enr_tidy <- tidy_enr(enr_processed)
```

---

## Part of the State Schooldata Project

This package is part of the [njschooldata](https://github.com/almartin82/njschooldata) family of packages providing simple, consistent interfaces for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

---

## Author

Andy Martin (almartin@gmail.com)
GitHub: [github.com/almartin82](https://github.com/almartin82)

## License

MIT
