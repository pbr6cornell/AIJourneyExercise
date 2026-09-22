# Step 4: Protocol and Analysis Specification

Date completed: 2026-09-22

## Protocol Title

Comparative risk of adverse events among patients in target versus comparator cohorts in a de-identified observational analytic dataset.

## Version and Status

- Protocol version: 1.0
- Status: Pre-analysis specification based on dataset intake, research question selection, and study design decisions.
- Statistical language: R
- Source dataset: `analytic_dataset.csv`

## Background and Rationale

The analytic dataset contains one record per patient, a binary cohort indicator, measured baseline covariates, and a binary adverse event outcome. Crude adverse event risk differs between cohorts, and baseline characteristics also differ. A structured observational study is therefore required to estimate the cohort-outcome association while assessing measured confounding, covariate balance, and positivity.

The dataset does not contain event dates, index dates, censoring dates, exposure duration, dose, treatment history, or person-time. The protocol is therefore limited to person-level binary outcome analyses over an assumed comparable outcome assessment window.

## Objectives

### Primary Objective

Estimate whether patients in `COHORT_ID = 1` have a different risk of `AE` compared with patients in `COHORT_ID = 0`, after accounting for measured baseline differences in age, race, pain level, and baseline LDL.

### Secondary Objectives

- Describe baseline characteristics by cohort.
- Quantify baseline covariate balance before and after propensity-score weighting.
- Estimate crude and adjusted cohort-outcome associations.
- Assess whether the findings are sensitive to poor propensity-score overlap or extreme weights.
- Summarize exploratory subgroup patterns by age, race, pain level, and LDL category.

## Study Design

This will be a retrospective, person-level, active-comparator cohort study.

- Target cohort: `COHORT_ID = 1`
- Comparator cohort: `COHORT_ID = 0`
- Outcome: `AE`
- Unit of analysis: patient-level record identified by `PERSON_ID`
- Analysis population: all records in `analytic_dataset.csv` meeting data quality checks for required variables

## Eligibility and Attrition Specification

Because the dataset is already analytic and de-identified, eligibility criteria are inferred from file inclusion. The analysis code will perform these checks before estimation:

- Confirm all required columns are present.
- Confirm `PERSON_ID` is unique.
- Confirm `COHORT_ID` contains only 0 and 1.
- Confirm `AE` contains only 0 and 1.
- Confirm no missing values in `COHORT_ID`, `PERSON_ID`, `AGE`, `RACE`, `PAIN_LEVEL`, `LDL_I`, or `AE`.
- Exclude records failing required-variable completeness checks if any are discovered, and report the number excluded.

No additional clinical exclusions will be created because the source definitions are unavailable.

## Variable Specification

Variable | Role | Planned handling
--- | --- | ---
`PERSON_ID` | Identifier | Used for uniqueness checks only
`COHORT_ID` | Exposure/cohort | Binary target-comparator indicator; target = 1, comparator = 0
`AE` | Outcome | Binary adverse event indicator; event = 1, no event = 0
`AGE` | Baseline covariate | Continuous in primary models; categorized for subgroup summaries
`RACE` | Baseline covariate | Categorical covariate using observed levels
`PAIN_LEVEL` | Baseline covariate | Continuous in primary models; categorized for subgroup summaries
`LDL_I` | Baseline covariate | Continuous in primary models; categorized for subgroup summaries

## Estimands and Effect Measures

Estimand | Measure | Primary use
--- | --- | ---
Crude association | Risk difference, risk ratio, odds ratio | Descriptive benchmark
Adjusted association from outcome regression | Odds ratio and 95% confidence interval | Primary model-based inference
Propensity-score weighted association | Weighted risk difference and weighted risk ratio | Primary risk interpretation
Sensitivity trimmed association | Weighted risk difference and risk ratio after propensity-score trimming | Robustness to poor overlap

## Statistical Analysis Specification

### Descriptive Analysis

- Report patient counts by cohort.
- Report event counts and crude event risks by cohort.
- Summarize continuous covariates with mean, standard deviation, median, quartiles, minimum, and maximum.
- Summarize categorical covariates with counts and percentages.
- Calculate standardized mean differences before adjustment.

### Propensity Score Model

Fit a logistic regression model for cohort membership:

```r
COHORT_ID ~ AGE + RACE + PAIN_LEVEL + LDL_I
```

The predicted probability of `COHORT_ID = 1` will be used as the propensity score.

### Weighting Specification

Use inverse probability of treatment weights for the average treatment effect:

- For `COHORT_ID = 1`: weight = `1 / propensity_score`
- For `COHORT_ID = 0`: weight = `1 / (1 - propensity_score)`

The analysis will report unstabilized weight summaries, effective sample size, and the proportion of records with large weights. If extreme weights or poor overlap are observed, a pre-specified sensitivity analysis will trim propensity scores below 0.01 or above 0.99.

### Covariate Balance

Calculate standardized mean differences before and after weighting. Balance will be considered acceptable when absolute standardized mean differences are below 0.10 for all measured covariates. If balance remains poor, the final interpretation will emphasize residual measured confounding.

### Outcome Regression

Fit a logistic regression model for the binary outcome:

```r
AE ~ COHORT_ID + AGE + RACE + PAIN_LEVEL + LDL_I
```

Report the adjusted odds ratio, 95% confidence interval, and p-value for `COHORT_ID`.

### Weighted Risk Estimation

Estimate weighted event risk in each cohort using inverse probability weights. Report:

- Weighted risk in target cohort
- Weighted risk in comparator cohort
- Weighted risk difference
- Weighted risk ratio

Use nonparametric bootstrap with a fixed random seed for uncertainty intervals if computationally feasible. If bootstrap runtime or package constraints prevent this, report point estimates and use the regression-based confidence interval as the inferential anchor.

### Exploratory Subgroup Summaries

Create descriptive subgroup summaries for:

- Age group: `<50`, `50-64`, `65-74`, `75+`
- Race: observed `RACE` categories
- Pain category: tertiles of `PAIN_LEVEL`
- LDL category: `<100`, `100-129`, `130+`

Subgroup results will be interpreted as exploratory and hypothesis-generating.

## Diagnostics and Decision Rules

Diagnostic | Decision rule | Impact on interpretation
--- | --- | ---
Required variable completeness | Any exclusions must be reported | Defines analysis population
Duplicate `PERSON_ID` | Duplicates indicate invalid person-level assumptions | Stop and revise analysis if found
Event counts | Sparse events may destabilize adjusted models | Report instability if present
Propensity-score overlap | Poor overlap if many scores are near 0 or 1 | Run trimming sensitivity analysis
Weights | Extreme weights indicate positivity concerns | Emphasize weighted estimate fragility
Balance | Absolute SMD < 0.10 preferred | Poor balance limits causal interpretation
Model convergence | Non-convergence invalidates regression estimate | Simplify model or report limitation

## Planned Tables and Figures

Output | File
--- | ---
Analysis dataset checks | `results/data_quality_checks.csv`
Table 1 baseline characteristics | `results/table1_baseline_characteristics.csv`
Crude outcome summary | `results/table2_crude_outcomes.csv`
Propensity score and weight diagnostics | `results/table3_ps_diagnostics.csv`
Covariate balance table | `results/table4_covariate_balance.csv`
Adjusted outcome model | `results/table5_adjusted_model.csv`
Weighted effect estimates | `results/table6_weighted_effects.csv`
Subgroup summaries | `results/table7_subgroup_summaries.csv`
Propensity score overlap figure | `results/figure1_propensity_overlap.png`
Covariate balance figure | `results/figure2_covariate_balance.png`

## Reproducibility Requirements

- All analyses will be implemented in R.
- Scripts will create a `results` directory if it does not exist.
- Random components, including bootstrap procedures, will use a fixed seed.
- Package use will be minimized; base R will be preferred where feasible for portability.
- All assumptions and deviations from this protocol will be documented in later steps.

## Limitations Specified Before Analysis

- The analysis cannot estimate hazards, incidence rates, or time-to-event effects.
- The source clinical definitions of cohort assignment and adverse event are unknown.
- The available covariate set is small, so unmeasured confounding is likely possible.
- The binary outcome window is assumed comparable across cohorts but cannot be verified from this file alone.
- Causal language should be avoided unless source documentation later supports the necessary design assumptions.

## Step 4 Completion Check

- A protocol was written for the observational comparative cohort study.
- An analysis specification was written with variables, models, diagnostics, outputs, and decision rules.
- Work product created: `step4_protocol_analysis_specification.md`.