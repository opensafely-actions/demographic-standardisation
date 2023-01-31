######################################
# Direct age-sex (or any other strata) standardisation of event rates
# Standardisation works as follows:
# Strata-specific rates are calculated in a given cohort of interest (eg rates as provided by measures framework)
# This cohort may not reflect the age-sex (or whatever) distribution of the target population of interest, or is not the same as another cohort to be compared
# To deal with this, we can standardise overall rates to a reference population,
# by assuming that the strata-specific rates are the those that would be observed in equivalent strata in the reference population
# Essentially, the overall rates are calculated as a weighted-mean of the strata-specific rates, with weights defined by the relative size of the strata in the reference population
#
# The script proceeds as follows:
# Import the arguments
# Import cohort rates data, stratified by pre-defined strata
# Import reference population data, stratified by the same pre-defined strata
# Calculate the weighted average of the rates (= standardise the rates), overall and in all subgroups of interest
# Output unstandardised and standardised rates + plots if requested

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
  print("zero length args detected")
  # use for interactive testing
  df_input <- "output/measures/measure_death.feather"
  dir_output <-  "output/standardised"
  standardisation_strata <- "year;sex;ageband5year;region"
  subgroups <- "overall;sex;ageband20year;region"
  numerator <- "death_1year"
  denominator <- "population"
  reference_population <- "ONS-England-mid-year-pop"
  min_count <- as.integer("6")
  round_method <- "mid"
  make_plots <- TRUE

} else {

  option_list <- list(
    make_option("--df_input", type = "character", default = NULL,
                help = "Input dataset .feather filename [default %default]. feather format is enforced to preserve factor levels, and ensure a separate script to make adding subgroups, factorising variables etc, is used as standard.",
                metavar = "filename.feather"),
    make_option("--dir_output", type = "character", default = NULL,
                help = "Output directory [default %default].",
                metavar = "output"),
    make_option("--standardisation_strata", type = "character", default = NULL,
                help = "Strata used to standardise rates, separated by semi-colon (;) [default %default]. Usually age-sex-year, but could include region, ethnicity, or anything as long as it's available in the reference population of interest.",
                metavar = "strata_name"),
    make_option("--subgroups", type = "character", default = NULL,
                help = "Subgroup variable name or list of variable names, separated by semi-colon (;) [default %default]. If subgroups are used, rate are standardised within those subgroups. Subgroups are analysed independently, not in combination. If NULL, rates will be calculated over the entire cohort only.",
                metavar = "subgroup_varnames"),
    make_option("--numerator", type="character", default = NULL,
                help = "Name of the numerator variable in the cohort dataset [default %default]. This is usually an event count within a given period."),
    make_option("--denominator", type="character", default = NULL,
                help = "Name of the denominator variable in the cohort dataset [default %default]. This is usually a population count or time-at-risk."),
    make_option("--reference_population", type="character", default = NULL,
                help = "Filepath of the reference population used for standardisation. This dataset must be stratified by the strata defined in 'standardisation_strata'. NEEDS THOUGHT ABOUT HOW TO MAKE THESE AVAILABLE ON THE BACKEND OR NOT"),
    make_option("--min_count", type = "integer", default = 6,
                help = "The minimum permissable numerator and denominator counts for each rate in each subgroup [default %default].",
                metavar = "min_count"),
    make_option("--round_method", type = "character", default = "constant",
                help = "Small number suppression method [default %default]. 'ceiling' rounds values up to the nearest multiple of 'min_count'. 'floor' rounds values down to the nearest multiple of 'min_count'. 'mid' rounds values to the nearest multiple of 'min_count', with a 'min_count/2' offset. 'redact' will set values less than 'min_count' to 'NA'",
                metavar = "method"),
    make_option("--make_plots", type = "logical", default = TRUE,
                help = "Should plots of unstandardised and standardised rates for each subgroup be created in the output folder? [default %default]. These are fairly basic plots for sense-checking purposes only.",
                metavar = "TRUE/FALSE")
  )

  opt_parser <- OptionParser(usage = "direct_standardisation:[version] [options]", option_list = option_list)
  opt <- parse_args(opt_parser)

  df_input <- opt$df_input
  dir_output <- opt$dir_output
  standardisation_strata <- opt$standardisation_strata
  subgroups <- opt$subgroups
  denominator <- opt$denominator
  numerator <- opt$numerator
  reference_population <- opt$reference_population
  min_count <- opt$min_count
  round_method <- opt$round_method
  make_plots <- opt$make_plots
}

standardisation_strata <- str_split(standardisation_strata, ";")[[1]]
subgroups <- str_split(subgroups, ";")[[1]]


# it is assumed that the dataset contains a YYYY-MM-DD formatted "date" variable defining relevant calendar-time strata
# maybe this should be defined explicitly as a "strata"

## get measure id from filename, as specified in study definition
measure_id <- str_remove(fs::path_ext_remove(fs::path_file(df_input)), "measure\\_")

## define input/output directories ----
fs::dir_create(fs::path(here(dir_output)))
analysis_dir <- here("output", "analysis")


## create rounding function for small number suppression ----

osround <- function(x, min_count=5, method="mid"){
  switch(
    method,
    "redact" = {if_else(x < min_count, NA_integer_, as.integer(x))},
    "mid" = {ceiling(x/min_count)*min_count - (floor(min_count/2)*(x!=0))},
    "floor" = {floor(x/min_count)*min_count},
    "ceiling" = {ceiling(x/min_count)*min_count}
  )
}


# import cohort rates data ----

## import ----
data_cohort0 <- arrow::read_feather(df_input)

stopifnot("standardisation_strata not in cohort population" = all(standardisation_strata %in% names(data_cohort0)))

## process ----
data_cohort <-
  data_cohort0  %>%
  transmute(
    !!! syms(subgroups),
    !!! syms(standardisation_strata),
    #death_1year = as.integer(death_1year),
    numerator = as.integer(.data[[numerator]]),
    denominator = as.integer(.data[[denominator]]),
    rate = value,
    date = as.Date(date),

  ) %>%
  arrange(
    !!! syms(standardisation_strata),
    date,
  )

# import reference population ----
data_reference_everything <- arrow::read_feather(here("reference-populations", glue("{reference_population}.feather")))

## test that standardisation_strata match between cohort and reference ----
stopifnot("standardisation_strata not in reference population" = all(standardisation_strata %in% names(data_reference_everything)))

## test that subgroup levels match between cohort and reference ----

print("Do group levels in reference population match those in cohort population?")
for(i in c(standardisation_strata)){
  print(i)

  referencelevels <- levels(factor(data_reference_everything[[i]]))
  cohortlevels <- levels(factor(data_cohort[[i]]))
  alllevels <- unique(c(referencelevels, cohortlevels))
  inlevel <- cbind(
      "in reference" = as.integer(alllevels %in% referencelevels),
      "in cohort" = as.integer(alllevels %in% cohortlevels)
    )
  rownames(inlevel) <- alllevels
  print(inlevel)
}

# apply weighting to get standardised rates ----

## aggregate population counts by required standardisation_strata ----
data_reference <-
  data_reference_everything %>%
  group_by(!!!syms(standardisation_strata)) %>%
  summarise(
    N_reference = sum(population),
  ) %>%
  ungroup()

## join cohort rates and reference population size ----

data_combined <-
  left_join(
    data_cohort,
    data_reference,
    by = c(standardisation_strata)
  )

## TODO may need a test here to ensure factors have been merged as intended

## define function to standardise rates within specified subgroups ----
rounded_rates <- function(data, min_count, method, ...){
  data %>%
    group_by(...) %>%
    summarise(
      numerator_sum = sum(numerator), # renamed to numerator_sum as unsummed numerator is needed later
      denominator_sum = sum(denominator), # renamed to denominator_sum as unsummed denominator is needed later
      N_reference_sum = sum(N_reference),

      rate_unweighted = numerator_sum / denominator_sum,
      var_rate_unweighted = rate_unweighted * (1 - rate_unweighted) * (1 / denominator_sum), # variance using aggregate counts
      var_rate_unweighted1 = (1/(n()^2))* sum(rate * (1 - rate) * (1 / denominator)), # variance using sum of variance of unaggregated counts

      rate_weighted = sum((numerator*N_reference) /  denominator) / N_reference_sum, # = sum(numerator * weight / denominator) = sum(weight*rate), where weight = (N_reference / sum(N_reference))
      var_rate_weighted = sum(((N_reference/N_reference_sum)^2) * rate * (1 - rate) * (1 / denominator)), # = sum(weight^2 * rate * (1-rate) / denominator)
      .groups="drop"
    ) %>%
    # rounding
    mutate(
      numerator_sum_rounded = osround(numerator_sum, min_count, method),
      denominator_sum_rounded = osround(denominator_sum, min_count, method),
      rate_unweighted_rounded = numerator_sum_rounded / denominator_sum_rounded,
      var_rate_unweighted_rounded = (rate_unweighted_rounded * (1 - rate_unweighted_rounded)) * (1 / denominator_sum_rounded), # normal approximation
    ) %>%
    select(
      ...,

      rate_unweighted,
      var_rate_unweighted,
      var_rate_unweighted1,

      #numerator_sum,
      #denominator_sum,
      rate_weighted,
      var_rate_weighted,

      numerator_sum_rounded,
      denominator_sum_rounded,
      rate_unweighted_rounded,
      var_rate_unweighted_rounded,

    )
}

## define function to plot stnadardised rates  within specified subgroups ----
plot_standardised_rates <- function(data, group, ..., filename){


  data_weighted <-
    data %>%
    transmute(
      {{ group }},
      ...,
      weighted = "weighted",
      rate = rate_weighted,
      var = var_rate_weighted
    )

  data_unweighted <-
    data %>%
    transmute(
      {{ group }},
      ...,
      weighted = "unweighted",
      rate = rate_unweighted,
      var = var_rate_unweighted
    )

  data_long <<-
    bind_rows(data_weighted, data_unweighted) %>%
    mutate(
      rate.ll = rate + qnorm(0.025)*sqrt(var),
      rate.ul = rate + qnorm(0.975)*sqrt(var)
    )

  plot_rates <-
    data_long %>%
    ggplot(aes(group={{ group }})) +
    #geom_hline(aes(yintercept=0), colour="black")+
    geom_line(aes(x=date, y=rate, colour={{ group }}))+
    geom_ribbon(aes(x=date, ymin=rate.ll, ymax=rate.ul, fill={{ group }}), colour="transparent", alpha=0.05)+
    facet_grid(rows=vars(weighted))+
    scale_x_date(
      labels = scales::label_date("%b"),
      date_breaks = "2 months",
      sec.axis = sec_axis(
        trans = ~as.Date(.),
        labels = scales::label_date("%Y")
      )
    )+
    scale_color_brewer(type="qual", palette="Set1")+
    scale_fill_brewer(type="qual", palette="Set1")+
    labs(
      x="Date",
      y="Rate",
      colour=NULL,
      fill=NULL,
      linetype=NULL
    )+
    theme_minimal()+
    theme(
      legend.position="bottom",
      axis.ticks.x = element_line(),
      axis.text.x = element_text(hjust=0),
      strip.text.y = element_text(angle=0)
    )

  #print(plot_rates) # to test interactively


  ggsave(
    filename = filename,
    plot = plot_rates
  )

}

## test rates and variance are equal if no aggregation performed ----
data_check <- rounded_rates(data_combined, min_count, round_method, 1, date, !!! syms(standardisation_strata))
stopifnot("weighted rate should be the same as the unweighted rate if no agregation is used" = all(abs(data_check$rate_unweighted - data_check$rate_weighted)<(2^-15), na.rm = TRUE))

## calculate rates overall (not within any subgroup) ----
data_all <- rounded_rates(data_combined, min_count, round_method, date)


## calculate subgroup specific rates (across all specified subgroups), write to file, and plot if requested ----

for(i in subgroups){

  sym_i <- sym(i)
  rates_weighted <- rounded_rates(data_combined, min_count, round_method, {{ sym_i }}, date)
  arrow::write_feather(rates_weighted, fs::path(here(dir_output), glue("rates_{i}.feather")))
  if(make_plots){
    plot_standardised_rates(
      rates_weighted,
      group = {{ sym_i }},
      date,
      filename=fs::path(here(dir_output), glue("rates_{i}.jpeg"))
    )
  }
}

