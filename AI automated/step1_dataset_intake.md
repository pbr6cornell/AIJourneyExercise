# Step 1: Dataset Intake

Date completed: 2026-09-22

## Source File

- File: `analytic_dataset.csv`
- Absolute path: `C:/Users/PRyan4/OneDrive - JNJ/OHDSI/AI help or hurt journey/AI automated/analytic_dataset.csv`
- Rows: 57576
- Columns: 7

## Decisions and Assumptions

- The CSV was read with base R `read.csv()` using `stringsAsFactors = FALSE` to preserve text fields for later recoding decisions.
- Original column names were preserved with `check.names = FALSE`.
- Blank character fields were treated as missing for the intake summary.
- No analysis-ready transformations were applied in this step.

## Column Summary

column | class | missing | missing_percent | unique_values | examples
--- | --- | --- | --- | --- | ---
COHORT_ID | integer | 0 | 0 |     2 | 0; 1
PERSON_ID | integer | 0 | 0 | 57576 | 115743; 149648; 134288; 180972; 174582
AGE | integer | 0 | 0 |    80 | 61; 85; 76; 44; 87
RACE | character | 0 | 0 |     3 | W; O; B
PAIN_LEVEL | numeric | 0 | 0 |   976 | 3.84; 5.69; 2.42; 7.24; 9.41
LDL_I | integer | 0 | 0 |   244 | 86; 123; 184; 107; 138
AE | integer | 0 | 0 |     2 | 0; 1

## First Six Rows

```
  COHORT_ID PERSON_ID AGE RACE PAIN_LEVEL LDL_I AE
1         0    115743  61    W       3.84    86  0
2         0    149648  85    O       5.69   123  0
3         0    134288  76    W       2.42   184  0
4         0    180972  44    W       7.24   107  0
5         0    174582  87    O       9.41   138  0
6         0    125791  45    O       7.97    91  1
```

## Step 1 Completion Check

- `analytic_dataset.csv` was successfully read into R.
- Dataset structure, missingness, example values, and first rows were documented.
- Work product created: `step1_dataset_intake.md`.
