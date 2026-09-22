# Step 2: Research Questions

Date completed: 2026-09-22

## Data Signals Used

The available analysis variables support questions about a binary cohort contrast, baseline covariates, and a binary adverse event outcome. They do not support questions requiring treatment dates, outcome dates, censoring dates, longitudinal exposure patterns, dose, duration, or follow-up time.

### Cohort and Outcome Counts

COHORT_ID | persons | AE events | crude AE risk | non-events
--- | ---: | ---: | ---: | ---:
0 | 45,845 | 3,113 | 6.79% | 42,732
1 | 11,731 | 1,257 | 10.72% | 10,474

### Mean Baseline Covariates by Cohort

COHORT_ID | AGE | PAIN_LEVEL | LDL_I
--- | ---: | ---: | ---:
0 | 63.89 | 5.61 | 112.54
1 | 59.99 | 4.96 | 121.88

### Race Distribution by Cohort

COHORT_ID | race distribution
--- | ---
0 | B: 21.6%; O: 35.4%; W: 43%
1 | B: 17.1%; O: 29.9%; W: 53%

## Primary Research Question

Among patients represented in the analytic dataset, is membership in `COHORT_ID = 1`, compared with `COHORT_ID = 0`, associated with a different risk of the binary adverse event `AE`, after accounting for measured baseline differences in age, race, pain level, and baseline LDL?

## Secondary Research Questions

1. How different are the two cohorts at baseline with respect to age, race, pain level, and LDL, and do those differences indicate meaningful confounding risk?
2. Is the cohort-adverse event association consistent across clinically relevant subgroups defined by age, race, baseline pain level, or LDL?
3. Which measured baseline characteristics are associated with adverse event risk, and do they explain part of the crude difference between cohorts?

## Questions Not Appropriate for This Dataset

- Time-to-event effectiveness or safety questions, because no index dates, event dates, censoring dates, or follow-up time are available.
- Dose-response, duration-response, adherence, switching, or persistence questions, because exposure intensity and longitudinal treatment data are unavailable.
- Incidence-rate questions, because person-time cannot be calculated.
- Broad clinical generalizability claims, because the source population, eligibility criteria, care setting, and cohort definitions are not yet described in the data file.

## OHDSI Framing Decisions and Assumptions

- `COHORT_ID` is treated as the target-comparator cohort indicator, with `1` as the target cohort and `0` as the comparator cohort, pending confirmation from source documentation.
- `AE` is treated as the binary adverse event outcome measured during a fixed analytic window, pending confirmation from source documentation.
- `AGE`, `RACE`, `PAIN_LEVEL`, and `LDL_I` are treated as baseline covariates available for confounding assessment and adjustment.
- Each `PERSON_ID` appears once in the analytic dataset, so the unit of analysis is the person-level record.
- Because variable labels and clinical context are absent, the primary research question is intentionally framed as an association/comparative risk question rather than a causal claim at this stage.

## Step 2 Completion Check

- Appropriate primary and secondary research questions were identified from the available variables.
- Unsupported research questions were explicitly ruled out.
- Work product created: `step2_research_questions.md`.
