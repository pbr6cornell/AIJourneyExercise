# Step 3: Study Design and Statistical Methods

Date completed: 2026-09-22

## Selected Study Design

The appropriate design is a retrospective, person-level, active-comparator cohort study using the existing analytic dataset.

The target cohort is assumed to be `COHORT_ID = 1` and the comparator cohort is assumed to be `COHORT_ID = 0`. The outcome is the binary adverse event indicator `AE`. Each row is treated as one eligible patient, with one record per `PERSON_ID`.

This is the strongest feasible design for the available data because the dataset contains a cohort indicator, baseline covariates, and a binary outcome, but does not contain dates, follow-up time, exposure duration, or longitudinal treatment history.

## Primary Estimand

The primary estimand is the adjusted comparative risk of `AE` for patients in `COHORT_ID = 1` versus patients in `COHORT_ID = 0`, conditional on the measured baseline covariates available in the dataset.

The primary effect measures will be:

- Adjusted odds ratio from outcome regression.
- Propensity-score weighted risk difference.
- Propensity-score weighted risk ratio.

The odds ratio will support model-based inference, while the risk difference and risk ratio will provide more directly interpretable absolute and relative risk summaries.

## Covariates

Measured baseline covariates available for confounding assessment and adjustment are:

- `AGE`
- `RACE`
- `PAIN_LEVEL`
- `LDL_I`

`PERSON_ID` is an identifier and will not be used as a predictor. `AE` is the outcome and will not be included in the propensity score model. `COHORT_ID` is the exposure/cohort indicator.

## Primary Statistical Approach

The primary analysis will use two complementary adjustment strategies:

1. Propensity score adjustment

   Estimate the probability of being in `COHORT_ID = 1` using logistic regression with `AGE`, `RACE`, `PAIN_LEVEL`, and `LDL_I` as predictors. Use inverse probability of treatment weighting to balance the measured covariates across cohorts. Estimate weighted risks, weighted risk difference, and weighted risk ratio.

2. Multivariable outcome regression

   Fit a logistic regression model for `AE` including `COHORT_ID`, `AGE`, `RACE`, `PAIN_LEVEL`, and `LDL_I`. Report the adjusted odds ratio for `COHORT_ID = 1` versus `COHORT_ID = 0` with a 95% confidence interval.

Using both methods is appropriate here because the dataset is compact, the number of covariates is small, and concordance between approaches will help assess robustness.

## Diagnostics

The analysis should include the following diagnostics before interpretation:

- Cohort attrition and eligibility confirmation: confirm unique `PERSON_ID` and absence of missing values in required fields.
- Baseline balance before and after propensity score weighting using standardized mean differences.
- Propensity score overlap by cohort, including minimum, quartiles, median, mean, and maximum.
- Weight diagnostics, including extreme weights and effective sample size.
- Outcome event counts by cohort to verify adequate events for adjusted modeling.
- Positivity assessment to determine whether any cohort has near-zero probability of receiving either cohort assignment within observed covariate patterns.

## Secondary and Sensitivity Analyses

Planned secondary analyses are:

- Crude unadjusted association between `COHORT_ID` and `AE`.
- Stratified descriptive analyses by age group, race, pain-level category, and LDL category.
- Adjusted model including flexible terms for continuous covariates if diagnostics suggest nonlinearity, using simple restricted categories if package availability limits spline modeling.
- Sensitivity analysis trimming patients with extreme propensity scores, such as scores below 0.01 or above 0.99, if poor overlap is observed.

Subgroup findings will be treated as exploratory because the dataset lacks protocol-level clinical justification for formal effect modification hypotheses.

## Methods Not Selected

- Cox proportional hazards regression is not appropriate because there is no event time or censoring time.
- Poisson or incidence-rate modeling is not appropriate because person-time is unavailable.
- Self-controlled designs are not appropriate because there is no longitudinal within-person exposure or outcome timing.
- New-user design verification cannot be performed because treatment initiation dates and prior exposure history are unavailable.
- Negative and positive control outcome calibration cannot be performed from this file alone because no control outcomes are provided.

## Key Assumptions

- `COHORT_ID` correctly identifies mutually exclusive target and comparator cohorts.
- `AE` represents outcome occurrence during a comparable fixed window for both cohorts.
- `AGE`, `RACE`, `PAIN_LEVEL`, and `LDL_I` are measured before or at cohort entry and are not consequences of cohort assignment.
- There is no unmeasured confounding beyond what can be addressed with the available variables; this assumption is strong and will be emphasized as a reliability limitation.
- Patients are independent observations.

## Step 3 Completion Check

- A retrospective active-comparator cohort design was selected.
- Primary and secondary statistical methods were specified.
- Diagnostics, sensitivity analyses, unsupported methods, and key assumptions were documented.
- Work product created: `step3_study_design_methods.md`.