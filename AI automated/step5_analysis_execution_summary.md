# Step 5: Analysis Execution Summary

Date completed: 2026-09-22

## Execution Status

The protocol-specified analysis code was developed, tested through built-in data quality checks, and executed in R.

## Inputs

- Source dataset: `analytic_dataset.csv`
- Analysis rows used: 57576
- Bootstrap replicates requested for weighted effects: 200
- Bootstrap replicates successful: 200

## Code and Output Files

- Analysis script: `step5_execute_analysis.R`
- Data quality checks: `results/data_quality_checks.csv`
- Baseline characteristics: `results/table1_baseline_characteristics.csv`
- Crude outcomes: `results/table2_crude_outcomes.csv`
- Propensity score diagnostics: `results/table3_ps_diagnostics.csv`
- Covariate balance: `results/table4_covariate_balance.csv`
- Adjusted outcome model: `results/table5_adjusted_model.csv`
- Weighted effects: `results/table6_weighted_effects.csv`
- Trimmed sensitivity analysis: `results/table6b_weighted_effects_trimmed_sensitivity.csv`
- Subgroup summaries: `results/table7_subgroup_summaries.csv`
- Propensity overlap figure: `results/figure1_propensity_overlap.png`
- Covariate balance figure: `results/figure2_covariate_balance.png`

## Diagnostics Snapshot

- Maximum absolute weighted standardized mean difference: 0.1739
- Maximum inverse probability weight: 25.0461
- Propensity-score trimming sensitivity triggered: TRUE

## Step 5 Completion Check

- Study code was developed in R.
- Data quality checks were executed before modeling.
- Protocol-specified descriptive, propensity-score, outcome-regression, weighted-effect, diagnostic, figure, and subgroup outputs were created.
- Work product created: `step5_execute_analysis.R`, `step5_analysis_execution_summary.md`, and the `results/` directory.
