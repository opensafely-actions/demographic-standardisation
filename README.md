# demographic-standardisation

[View on OpenSAFELY](https://jobs.opensafely.org/repo/https%253A%252F%252Fgithub.com%252Fopensafely%252Fdemographic-standardisation)

Details of the purpose and any published outputs from this project can be found at the link above.

The contents of this repository MUST NOT be considered an accurate or valid representation of the study or its purpose. 
This repository may reflect an incomplete or incorrect analysis with no further ongoing work.
The content has ONLY been made public to support the OpenSAFELY [open science and transparency principles](https://www.opensafely.org/about/#contributing-to-best-practice-around-open-science) and to support the sharing of re-usable code for other subsequent users.
No clinical, policy or safety conclusions must be drawn from the contents of this repository.

# About the OpenSAFELY framework

The OpenSAFELY framework is a Trusted Research Environment (TRE) for electronic
health records research in the NHS, with a focus on public accountability and
research quality.

Read more at [OpenSAFELY.org](https://opensafely.org).

# Licences
As standard, research projects have a MIT license. 


# Overview of Direct Standardisation

Direct Standardisation is a way to make event rates (often mortality rates) comparable across two or more cohorts whose demographic characteristics (often age-sex-year distributions) are not the same. 

Say we want to compare death rates between cohort A and cohort B. Cohort A is substantially younger on average than cohort B, so naturally the death rate in cohort A is lower. But cohort B is more affluent and has better access to healthcare services. If the age distribution of the two cohorts was the same would we still see that cohort A had a lower death rate than cohort B? To answer this question, we can _standardise_ the age distributions so that they match a reference population, the population of England for example, and then compare rates. 

Essentially, direct standardisation answers the question: "if each cohort had the same number of people in each demographic strata as the reference population, but the event rates stayed the same in each strata, what would the overall event rate be?". 

Often the comparator cohort is the reference population itself. The standardisation procedure remains the same. 

This idea can be extended to other cohort characteristics, such as sex, region, ethnicity, as long as the number of poeple in each stratum is known in the reference population. 

A reference population is usually a real distribution, such as the population of England or Europe, but can be anything.

Unstandardised event rates can be calculated as `R = events/people` or `events/timeatrisk`. This can be decomposed into strata-specific rates `R_i = events_i/people_i`, where `people_i` is the number of people in stratum `i`, and `event_i` is the nubmer of events in stratum `i`. This is in turn can be used to recover the overall rate: `R = sum(R_i * people_i)/sum(people_i) = sum((events_i/people_i)*people_i)/sum(people_i) = sum(events_i)/sum(people_i) = events/people`. But instead of recovering the original rate `R` using the size of each stratum in the cohort, `people_i`, we can recover an alternative rate using any other population with different stratum sizes. This leads us to standardised event rates: `R = sum(R_i * reference_i)/sum(reference_i)`, where `reference_i` is the number of people in each stratum of the reference population. 






