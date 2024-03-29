# # # # # # # # # # # # # # # # # # # # #
# Purpose: Download and restructure mid pop estimates to be used to weight the
# TPP population
#
# Notes: the 2020 mid year population estimates are used for reweighing
# # # # # # # # # # # # # # # # # # # # #

# preliminaries ----
## import libraries ----
library('tidyverse')
library('onsr')
library('here')
## create output directories ----
fs::dir_create(here("ONS-data"))

# download mid year pop estimates ----
ons_pop_estimates <- ons_get(id = "mid-year-pop-est")

# restructure to same format as our estimates are in ----
ons_pop_estimates_region <-
  ons_pop_estimates %>%
  filter(
    `administrative-geography` %in% c(
      "E12000001",
      "E12000002",
      "E12000003",
      "E12000004",
      "E12000005",
      "E12000006",
      "E12000007",
      "E12000008",
      "E12000009"
    ), # nine regions in England
    sex %in% c("male", "female"),
    `single-year-of-age` %in% c(0:89, "90+"),
    # `calendar-years` %in% seq(2018,2021,1)
  ) %>%
  transmute(
    year=`calendar-years`,
    age_string=`single-year-of-age`,
    age_int = as.integer(str_extract(age_string, "\\d+")), # remove +
    ageband5year = case_when(
      age_int>=0 & age_int<=4 ~ "0-4",
      age_int>=5 & age_int<=9 ~ "5-9",
      age_int>=10 & age_int<=14 ~ "10-14",
      age_int>=15 & age_int<=19 ~ "15-19",
      age_int>=20 & age_int<=24 ~ "20-24",
      age_int>=25 & age_int<=29 ~ "25-29",
      age_int>=30 & age_int<=34 ~ "30-34",
      age_int>=35 & age_int<=39 ~ "35-39",
      age_int>=40 & age_int<=44 ~ "40-44",
      age_int>=45 & age_int<=49 ~ "45-49",
      age_int>=50 & age_int<=54 ~ "50-54",
      age_int>=55 & age_int<=59 ~ "55-59",
      age_int>=60 & age_int<=64 ~ "60-64",
      age_int>=65 & age_int<=69 ~ "65-69",
      age_int>=70 & age_int<=74 ~ "70-74",
      age_int>=75 & age_int<=79 ~ "75-79",
      age_int>=80 & age_int<=84 ~ "80-84",
      age_int>=85 & age_int<=89 ~ "85-89",
      age_int>=90 ~ "90+",
    ),
    ageband5year = factor(ageband5year,
                          levels = c("0-4",
                                     "5-9",
                                     "10-14",
                                     "15-19",
                                     "20-24",
                                     "25-29",
                                     "30-34",
                                     "35-39",
                                     "40-44",
                                     "45-49",
                                     "50-54",
                                     "55-59",
                                     "60-64",
                                     "65-69",
                                     "70-74",
                                     "75-79",
                                     "80-84",
                                     "85-89",
                                     "90+")),
    sex=`Sex`,
    region=str_replace(str_to_title(`Geography`), "And The", "and The"), # this matches what's in TPP
    population=`v4_0`,
  ) %>%
  arrange(
    year,
    age_int,
    sex,
    region
  )

# save restructured estimates ----
arrow::write_feather(ons_pop_estimates_region, here("reference-populations", "ONS-England-mid-year-pop.feather"))
