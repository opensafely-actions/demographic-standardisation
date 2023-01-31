######################################
# make measures output match standardisation strata and subgroups used
# add required subgroups
## output as a feather file
######################################

# preliminaries ----
## import libraries ----
library('tidyverse')
library('lubridate')
library('here')
library('glue')
library("optparse")


## arguments -----


## parse command-line arguments ----

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  # use for interactive testing
  df_input <- "output/measures/measure_death.csv"
  dir_output <-  "output/measures"
  print("zero length args detected")
} else {
  print(args)
  option_list <- list(
    make_option("--df_input", type = "character", default = NULL,
                help = "Input dataset .csv or .csv.gz filename [default %default]. Only supports csv as this matches output from measures framework.",
                metavar = "filename"),
    make_option("--dir_output", type = "character", default = NULL,
                help = "Output directory [default %default].",
                metavar = "output")
  )

  opt_parser <- OptionParser(option_list = option_list)
  opt <- parse_args(opt_parser)

  df_input <- opt$df_input
  dir_output <- opt$dir_output
}

## define input/output directories ----
fs::dir_create(fs::path(here(dir_output)))


# import and process cohort rates data ----

data_cohort <-read_csv(df_input) %>%
  mutate(
    # can these operations be parameterised and incorporated into the main standardisation script?
    year = as.integer(lubridate::year(date)),
    sex = factor(sex, levels=c("F", "M"), labels= c("Female", "Male")),
    ageband5year = factor(ageband5year),
    region = factor(region),
    ageband20year = cut(as.numeric(str_extract(ageband5year, "^\\d+")), c(0,20,40,60, 80, Inf), right = FALSE),
    overall=factor("overall"),
    death_1year = as.integer(death_1year),
    population = as.integer(population)
  )


# write to file -----
arrow::write_feather(data_cohort, here(dir_output, fs::path_ext_set(fs::path_file(df_input), ".feather")))


