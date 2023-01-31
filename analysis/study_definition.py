
from cohortextractor import (
  StudyDefinition,
  patients,
  codelist_from_csv,
  codelist,
  filter_codes_by_category,
  combine_codelists,
  Measure
)

start_date = "2018-01-01"

# Specify study definition
study = StudyDefinition(
  
  # Configure the expectations framework
  default_expectations={
    "date": {"earliest": "2018-01-01", "latest": "2020-01-01"},
    "rate": "uniform",
    "incidence": 0.1,
    "int": {"distribution": "normal", "mean": 1000, "stddev": 100},
    "float": {"distribution": "normal", "mean": 25, "stddev": 5},
  },
  
  index_date = start_date,
  
  # This line defines the study population
  population=patients.satisfying(
    """
      registered
      AND
      age >= 0 AND age <=110
      AND
      sex = "M" OR sex = "F" 
      AND
      NOT has_died
    """,
    
    # we define baseline variables on the day _before_ the study date
    registered=patients.registered_as_of(
      "index_date",
    ),
    has_died=patients.died_from_any_cause(
      on_or_before="index_date - 1 day",
      returning="binary_flag",
    ), 
  ),
  
  
  ###############################################################################
  ## Demographics
  ###############################################################################
  
  age=patients.age_as_of( 
    "index_date",
  ),
  
  
  ageband5year=patients.categorised_as(
    {
      "": "DEFAULT",
      "0-4"   : "age>=0 AND age<=4", 
      "5-9"   : "age>=5 AND age<=9", 
      "10-14" : "age>=10 AND age<=14", 
      "15-19" : "age>=15 AND age<=19",
      "20-24" : "age>=20 AND age<=24",
      "25-29" : "age>=25 AND age<=29",
      "30-34" : "age>=30 AND age<=34",
      "35-39" : "age>=35 AND age<=39",
      "40-44" : "age>=40 AND age<=44",
      "45-49" : "age>=45 AND age<=49",
      "50-54" : "age>=50 AND age<=54",
      "55-59" : "age>=55 AND age<=59",
      "60-64" : "age>=60 AND age<=64",
      "65-69" : "age>=65 AND age<=69",
      "70-74" : "age>=70 AND age<=74",
      "75-79" : "age>=75 AND age<=79",
      "80-84" : "age>=80 AND age<=84",
      "85-89" : "age>=85 AND age<=89",
      "90+" : "age>=90",
    },
    return_expectations={
      "category":{"ratios": 
        {
        "0-4"   : 0.05,
        "5-9"   : 0.05,
        "10-14" : 0.05,
        "15-19" : 0.05,
        "20-24" : 0.05,
        "25-29" : 0.05,
        "30-34" : 0.05,
        "35-39" : 0.05,
        "40-44" : 0.05,
        "45-49" : 0.05,
        "50-54" : 0.1,
        "55-59" : 0.05,
        "60-64" : 0.05,
        "65-69" : 0.05,
        "70-74" : 0.05,
        "75-79" : 0.05,
        "80-84" : 0.05,
        "85-89" : 0.05,
        "90+"   : 0.05,
        }
      }
    },
  ),
  
  sex=patients.sex(
    return_expectations={
      "rate": "universal",
      "category": {"ratios": {"M": 0.49, "F": 0.51}},
      "incidence": 1,
    }
  ),

  # msoa
  msoa=patients.address_as_of(
    "index_date",
    returning="msoa",
    return_expectations={
      "rate": "universal",
      "category": {"ratios": {"E02000001": 0.0625, "E02000002": 0.0625, "E02000003": 0.0625, "E02000004": 0.0625,
        "E02000005": 0.0625, "E02000007": 0.0625, "E02000008": 0.0625, "E02000009": 0.0625, 
        "E02000010": 0.0625, "E02000011": 0.0625, "E02000012": 0.0625, "E02000013": 0.0625, 
        "E02000014": 0.0625, "E02000015": 0.0625, "E02000016": 0.0625, "E02000017": 0.0625}},
    },
  ),    
  
  # stp is an NHS administration region based on geography
  stp=patients.registered_practice_as_of(
    "index_date",
    returning="stp_code",
    return_expectations={
      "rate": "universal",
      "category": {
        "ratios": {
          "STP1": 0.1,
          "STP2": 0.1,
          "STP3": 0.1,
          "STP4": 0.1,
          "STP5": 0.1,
          "STP6": 0.1,
          "STP7": 0.1,
          "STP8": 0.1,
          "STP9": 0.1,
          "STP10": 0.1,
        }
      },
    },
  ),
  
  # NHS administrative region
  # FIXME can we get an equivalent using patient postcode not GP address?
  region=patients.registered_practice_as_of(
    "index_date",
    returning="nuts1_region_name",
    return_expectations={
      "rate": "universal",
      "category": {
        "ratios": {
          "North East": 0.1,
          "North West": 0.1,
          "Yorkshire and The Humber": 0.2,
          "East Midlands": 0.1,
          "West Midlands": 0.1,
          "East": 0.1,
          "London": 0.1,
          "South East": 0.1,
          "South West": 0.1
          #"" : 0.01
        },
      },
    },
  ),
  
  death_date = patients.died_from_any_cause(
      on_or_after="index_date",
      returning="date_of_death",
    ), 
    
  death_1year = patients.died_from_any_cause(
      between=["index_date", "index_date + 364 days"], # doesn't do leap years, but `+ 1 year - 1 day` doesn't work
      returning="binary_flag",
    ), 
  
)

measures = [

    Measure(
      id="death",
      numerator="death_1year",
      denominator="population",
      group_by=["sex", "ageband5year", "region"],
      small_number_suppression=False
    ),

]

