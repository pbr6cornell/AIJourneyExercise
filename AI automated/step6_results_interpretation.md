# Step 6: Interpretation of Study Results

Date completed: 2026-09-22

## Data Quality and Analysis Population

The analysis included 57576 patient-level records: 45845 in the comparator cohort (`COHORT_ID = 0`) and 11731 in the target cohort (`COHORT_ID = 1`). Required variables were complete, `PERSON_ID` was unique, and `COHORT_ID` and `AE` were limited to valid binary values.

check | result | value
--- | --- | ---
Required columns present | TRUE | 
Input row count | TRUE | 57576
Required fields complete | TRUE | 0
PERSON_ID unique | TRUE | 0
COHORT_ID values limited to 0/1 | TRUE | 0; 1
AE values limited to 0/1 | TRUE | 0; 1

## Baseline Summary

Before adjustment, the target cohort was younger on average than the comparator cohort (mean age 60.0 vs 63.9), had lower mean pain level (4.96 vs 5.61), and had higher mean LDL (121.9 vs 112.5). Race distribution also differed, with a larger White proportion in the target cohort.

These baseline differences support the protocol decision to use confounding adjustment rather than relying on crude comparisons alone.

## Crude Outcome Results

Crude adverse event risk was 10.72% in the target cohort and 6.79% in the comparator cohort. The crude risk difference was 3.92%, and the crude risk ratio was 1.58.

The crude odds ratio for the target versus comparator cohort was 1.65 (95% CI 1.54 to 1.76).

## Adjusted Outcome Model

After adjustment for age, race, pain level, and LDL in logistic regression, the target cohort remained associated with higher odds of adverse event: adjusted odds ratio 1.76 (95% CI 1.64 to 1.89), p = 4.81e-55.

Measured covariates were also associated with adverse event risk in the adjusted model. Higher age, higher pain level, and higher LDL were associated with higher odds of adverse event, while the observed `RACE` categories had different risks relative to the model reference category.

## Propensity Score Weighted Results

The propensity-score weighted target risk was 11.34% and the weighted comparator risk was 6.71%. The weighted risk difference was 0.046 (95% CI 0.040 to 0.052), and the weighted risk ratio was 1.69 (95% CI 1.58 to 1.78).

The trimmed sensitivity analysis did not remove any records (`n_trimmed = 0`), so the trimmed weighted estimates were identical to the main weighted estimates.

## Diagnostics Interpretation

Baseline balance improved after propensity-score weighting. The maximum absolute standardized mean difference decreased from 0.354 before weighting to 0.174 after weighting.

However, the largest post-weighting imbalance remained above the conventional 0.10 threshold: LDL_I (continuous) had an absolute weighted SMD of 0.174. This means measured confounding was reduced but not fully resolved.

Propensity-score overlap was adequate in the sense that no records had scores below 0.01 or above 0.99. The observed propensity-score range was 0.038 to 0.680. Weight diagnostics still show some influence concentration: the maximum IPTW was 25.05, with 3.58% of target-cohort records having weights greater than 10.

variable | level | abs SMD before weighting | abs SMD after weighting
--- | --- | ---: | ---:
AGE | continuous | 0.354 | 0.066
PAIN_LEVEL | continuous | 0.259 | 0.037
LDL_I | continuous | 0.161 | 0.174
RACE | B | 0.116 | 0.038
RACE | O | 0.117 | 0.025
RACE | W | 0.201 | 0.054

## Exploratory Subgroup Summary

The target cohort had higher crude adverse event risk than the comparator cohort in every summarized subgroup. These subgroup results are descriptive only and should not be interpreted as formal effect-modification tests.

- age_group = <50: target risk 8.8% (152/1722) vs comparator risk 6% (312/5242)
- age_group = 50-64: target risk 10.5% (650/6168) vs comparator risk 6.6% (1217/18499)
- age_group = 65-74: target risk 12% (359/2986) vs comparator risk 6.8% (915/13418)
- age_group = 75+: target risk 11.2% (96/855) vs comparator risk 7.7% (669/8686)
- RACE = B: target risk 13.3% (267/2004) vs comparator risk 7.6% (755/9925)
- RACE = O: target risk 11.7% (409/3508) vs comparator risk 6.8% (1108/16214)
- RACE = W: target risk 9.3% (581/6219) vs comparator risk 6.3% (1250/19706)
- pain_category = tertile_1: target risk 9.2% (492/5359) vs comparator risk 5.8% (808/13856)
- pain_category = tertile_2: target risk 12.2% (310/2539) vs comparator risk 6.7% (1108/16636)
- pain_category = tertile_3: target risk 11.9% (455/3833) vs comparator risk 7.8% (1197/15353)
- ldl_category = <100: target risk 10.2% (489/4799) vs comparator risk 6.4% (1113/17334)
- ldl_category = 100-129: target risk 10.2% (148/1451) vs comparator risk 6.8% (878/12881)
- ldl_category = 130+: target risk 11.3% (620/5481) vs comparator risk 7.2% (1122/15630)

## Overall Interpretation

Across crude, multivariable-adjusted, and propensity-score weighted analyses, `COHORT_ID = 1` was consistently associated with higher adverse event risk than `COHORT_ID = 0`. The absolute weighted difference was about 4.6 additional adverse events per 100 patients, and the weighted relative risk was about 1.69.

The direction and magnitude are internally consistent across methods, which strengthens the descriptive finding. Still, the result should be interpreted as an adjusted observational association rather than definitive causal evidence. The main reasons are limited covariate information, unknown source definitions for cohort and outcome, residual LDL imbalance after weighting, high weights for some target-cohort records, and absence of timing or follow-up information.

## Step 6 Completion Check

- Study results, diagnostics, and summary statistics were interpreted.
- Data quality, crude results, adjusted regression, propensity-score weighted results, balance diagnostics, weight diagnostics, and subgroup summaries were reviewed.
- Work product created: `step6_results_interpretation.md`.
