## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  echo = TRUE,
  message = FALSE,
  warning = FALSE,
  fig.width = 7,
  fig.height = 4,
  eval = FALSE
)

## ----load-packages------------------------------------------------------------
# library(ohschooldata)
# library(dplyr)
# library(ggplot2)

## ----fetch-single-year--------------------------------------------------------
# # Fetch 2024 enrollment data (2023-24 school year)
# enr <- fetch_enr(2024)
# 
# # View the first few rows
# head(enr)

## ----available-years----------------------------------------------------------
# # See which years are available
# list_enr_years()

## ----data-structure-----------------------------------------------------------
# # Key columns in tidy format
# enr %>%
#   select(end_year, district_irn, building_irn, district_name,
#          entity_type, grade_level, subgroup, n_students, pct) %>%
#   head(10)

## ----subgroups----------------------------------------------------------------
# # See all subgroups
# enr %>%
#   distinct(subgroup) %>%
#   pull(subgroup)

## ----wide-format--------------------------------------------------------------
# # Fetch in wide format
# enr_wide <- fetch_enr(2024, tidy = FALSE)
# 
# # View demographic columns
# enr_wide %>%
#   filter(entity_type == "State") %>%
#   select(end_year, enrollment_total, white, black, hispanic, asian,
#          economically_disadvantaged)

## ----convert-format-----------------------------------------------------------
# # Convert wide to tidy
# enr_tidy <- tidy_enr(enr_wide)

## ----irn-utilities------------------------------------------------------------
# # Validate an IRN
# is_valid_irn("043752")  # TRUE
# is_valid_irn("12345")   # FALSE (only 5 digits)
# 
# # Format a numeric IRN with leading zeros
# format_irn(43752)       # "043752"
# format_irn("43752")     # "043752"

## ----find-irn-----------------------------------------------------------------
# # Search for a district by name
# enr %>%
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
#   filter(grepl("Columbus", district_name, ignore.case = TRUE)) %>%
#   select(district_irn, district_name, county, n_students)

## ----filter-levels------------------------------------------------------------
# # State totals
# state <- enr %>% filter(is_state)
# 
# # All districts (excluding state totals)
# districts <- enr %>% filter(is_district)
# 
# # All buildings (individual schools)
# buildings <- enr %>% filter(is_building)

## ----school-types-------------------------------------------------------------
# # Traditional public districts
# traditional <- enr %>% filter(is_traditional, is_district)
# 
# # Community schools (Ohio's term for charter schools)
# community <- enr %>% filter(is_community_school, is_district)
# 
# # Joint Vocational School Districts (JVSDs) - Career-technical centers
# jvsd <- enr %>% filter(is_jvsd, is_district)
# 
# # STEM schools
# stem <- enr %>% filter(is_stem, is_district)

## ----filter-by-district-------------------------------------------------------
# # Get Columbus City Schools (district + all buildings)
# columbus <- enr %>% filter_district("043752")
# 
# # Get district-level only (no buildings)
# columbus_district <- enr %>% filter_district("043752", include_buildings = FALSE)

## ----filter-by-county---------------------------------------------------------
# # Get all Franklin County districts and schools
# franklin <- enr %>% filter_county("Franklin")
# 
# # Count districts by county
# enr %>%
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
#   count(county, sort = TRUE) %>%
#   head(10)

## ----multi-year---------------------------------------------------------------
# # Fetch a range of years
# enr_history <- fetch_enr_range(2020, 2024)
# 
# # Or use purrr for more control
# library(purrr)
# enr_multi <- map_df(2020:2024, fetch_enr)

## ----state-trends-------------------------------------------------------------
# # Get statewide summary for multiple years
# state_trend <- get_state_enrollment(2020:2024)
# 
# state_trend

## ----grade-level--------------------------------------------------------------
# # Enrollment by grade for state totals
# enr %>%
#   filter(is_state, subgroup == "total_enrollment", grade_level != "TOTAL") %>%
#   select(grade_level, n_students) %>%
#   arrange(grade_level)

## ----grade-aggregates---------------------------------------------------------
# # Create grade aggregates
# grade_aggs <- enr_grade_aggs(enr)
# 
# # View K-8 vs High School for state
# grade_aggs %>%
#   filter(is_state) %>%
#   select(grade_level, n_students)

## ----viz-top-districts--------------------------------------------------------
# # Top 15 districts by enrollment
# top_districts <- enr %>%
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
#   arrange(desc(n_students)) %>%
#   head(15)
# 
# ggplot(top_districts, aes(x = reorder(district_name, n_students), y = n_students)) +
#   geom_col(fill = "steelblue") +
#   geom_text(aes(label = scales::comma(n_students)), hjust = -0.1, size = 3) +
#   coord_flip() +
#   scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
#   labs(
#     title = "Top 15 Ohio Districts by Enrollment",
#     subtitle = "2023-24 School Year",
#     x = NULL,
#     y = "Total Enrollment"
#   ) +
#   theme_minimal() +
#   theme(panel.grid.major.y = element_blank())

## ----viz-demographics---------------------------------------------------------
# # Statewide demographic breakdown
# state_demos <- enr %>%
#   filter(is_state, grade_level == "TOTAL",
#          subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) %>%
#   select(subgroup, n_students, pct) %>%
#   mutate(subgroup = stringr::str_to_title(subgroup))
# 
# ggplot(state_demos, aes(x = reorder(subgroup, -n_students), y = pct)) +
#   geom_col(fill = "steelblue") +
#   geom_text(aes(label = scales::percent(pct, accuracy = 0.1)), vjust = -0.5, size = 3) +
#   scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.1))) +
#   labs(
#     title = "Ohio Statewide Enrollment by Race/Ethnicity",
#     subtitle = "2023-24 School Year",
#     x = NULL,
#     y = "Percent of Total Enrollment"
#   ) +
#   theme_minimal()

## ----viz-trend----------------------------------------------------------------
# # Fetch multiple years for trend analysis
# enr_trend <- fetch_enr_range(2018, 2024)
# 
# # State enrollment trend
# state_trend <- enr_trend %>%
#   filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
#   select(end_year, n_students)
# 
# ggplot(state_trend, aes(x = end_year, y = n_students)) +
#   geom_line(color = "steelblue", size = 1) +
#   geom_point(color = "steelblue", size = 3) +
#   geom_text(aes(label = scales::comma(n_students)), vjust = -1, size = 3) +
#   scale_y_continuous(labels = scales::comma, limits = c(1500000, NA)) +
#   scale_x_continuous(breaks = 2018:2024) +
#   labs(
#     title = "Ohio Statewide Enrollment Trend",
#     x = "School Year End",
#     y = "Total Enrollment"
#   ) +
#   theme_minimal()

## ----viz-county---------------------------------------------------------------
# # Top 10 counties by total enrollment
# county_enr <- enr %>%
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
#   group_by(county) %>%
#   summarize(total_enrollment = sum(n_students, na.rm = TRUE), .groups = "drop") %>%
#   arrange(desc(total_enrollment)) %>%
#   head(10)
# 
# ggplot(county_enr, aes(x = reorder(county, total_enrollment), y = total_enrollment)) +
#   geom_col(fill = "steelblue") +
#   coord_flip() +
#   scale_y_continuous(labels = scales::comma) +
#   labs(
#     title = "Top 10 Ohio Counties by Total Enrollment",
#     x = NULL,
#     y = "Total Enrollment"
#   ) +
#   theme_minimal()

## ----cache-management---------------------------------------------------------
# # View cached files
# cache_status()
# 
# # Clear cache for a specific year
# clear_enr_cache(2024)
# 
# # Clear all cached data
# clear_enr_cache()
# 
# # Force fresh download (bypasses cache)
# enr_fresh <- fetch_enr(2024, use_cache = FALSE)

## ----import-local-------------------------------------------------------------
# # After downloading from reportcard.education.ohio.gov/download:
# enr_local <- import_local_enrollment(
#   district_file = "~/Downloads/23-24_ENROLLMENT_DISTRICT.xlsx",
#   building_file = "~/Downloads/23-24_ENROLLMENT_BUILDING.xlsx",
#   end_year = 2024
# )
# 
# # Process the raw data
# enr_processed <- process_enr(enr_local, 2024)
# enr_tidy <- tidy_enr(enr_processed)

