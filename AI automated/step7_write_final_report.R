results_dir <- "results"
output_path <- "step7_final_study_report.md"

read_result <- function(file_name) {
  read.csv(file.path(results_dir, file_name), stringsAsFactors = FALSE, check.names = FALSE)
}

fmt_num <- function(x, digits = 2) {
  format(round(as.numeric(x), digits), nsmall = digits, trim = TRUE, scientific = FALSE)
}

fmt_pct <- function(x, digits = 1) {
  paste0(fmt_num(100 * as.numeric(x), digits), "%")
}

fmt_ci <- function(estimate, lower, upper, digits = 2) {
  paste0(fmt_num(estimate, digits), " (95% CI ", fmt_num(lower, digits), " to ", fmt_num(upper, digits), ")")
}

baseline <- read_result("table1_baseline_characteristics.csv")
crude <- read_result("table2_crude_outcomes.csv")
ps_diag <- read_result("table3_ps_diagnostics.csv")
balance <- read_result("table4_covariate_balance.csv")
adjusted <- read_result("table5_adjusted_model.csv")
weighted <- read_result("table6_weighted_effects.csv")
trimmed <- read_result("table6b_weighted_effects_trimmed_sensitivity.csv")
subgroups <- read_result("table7_subgroup_summaries.csv")

target <- crude[crude$COHORT_ID == 1, ]
comparator <- crude[crude$COHORT_ID == 0, ]
cohort_term <- adjusted[adjusted$term == "COHORT_ID", ]
weighted_lookup <- setNames(weighted$estimate, weighted$measure)
weighted_lower <- setNames(weighted$ci_lower, weighted$measure)
weighted_upper <- setNames(weighted$ci_upper, weighted$measure)
overall_ps <- ps_diag[ps_diag$COHORT_ID == "overall", ]
target_ps <- ps_diag[ps_diag$COHORT_ID == "1", ]
max_unweighted_smd <- max(balance$abs_unweighted_smd, na.rm = TRUE)
max_weighted_smd <- max(balance$abs_weighted_smd, na.rm = TRUE)
worst_balance <- balance[which.max(balance$abs_weighted_smd), ]

continuous_row <- function(variable, label) {
  row0 <- baseline[baseline$variable == variable & baseline$cohort == 0, ]
  row1 <- baseline[baseline$variable == variable & baseline$cohort == 1, ]
  paste(
    label,
    paste0(fmt_num(row0$mean, 1), " (SD ", fmt_num(row0$sd, 1), ")"),
    paste0(fmt_num(row1$mean, 1), " (SD ", fmt_num(row1$sd, 1), ")"),
    sep = " | "
  )
}

race_rows <- vapply(sort(unique(baseline$level[baseline$variable == "RACE"])), function(level) {
  row0 <- baseline[baseline$variable == "RACE" & baseline$level == level & baseline$cohort == 0, ]
  row1 <- baseline[baseline$variable == "RACE" & baseline$level == level & baseline$cohort == 1, ]
  paste(
    paste0("Race ", level),
    paste0(row0$count, " (", fmt_num(row0$percent, 1), "%)"),
    paste0(row1$count, " (", fmt_num(row1$percent, 1), "%)"),
    sep = " | "
  )
}, character(1))

table1_lines <- c(
  "Characteristic | Comparator (`COHORT_ID = 0`) | Target (`COHORT_ID = 1`)",
  "--- | ---: | ---:",
  continuous_row("AGE", "Age, mean (SD)"),
  continuous_row("PAIN_LEVEL", "Pain level, mean (SD)"),
  continuous_row("LDL_I", "LDL, mean (SD)"),
  race_rows
)

table2_lines <- c(
  "Measure | Estimate",
  "--- | ---:",
  paste("Comparator adverse event risk", paste0(comparator$events, "/", comparator$n, " (", fmt_pct(comparator$risk, 2), ")"), sep = " | "),
  paste("Target adverse event risk", paste0(target$events, "/", target$n, " (", fmt_pct(target$risk, 2), ")"), sep = " | "),
  paste("Crude risk difference", fmt_pct(target$crude_risk_difference_target_minus_comparator, 2), sep = " | "),
  paste("Crude risk ratio", fmt_num(target$crude_risk_ratio_target_vs_comparator, 2), sep = " | "),
  paste("Crude odds ratio", fmt_ci(target$crude_odds_ratio_target_vs_comparator, target$crude_or_ci_lower, target$crude_or_ci_upper, 2), sep = " | "),
  paste("Adjusted odds ratio", fmt_ci(cohort_term$odds_ratio, cohort_term$ci_lower, cohort_term$ci_upper, 2), sep = " | "),
  paste("Weighted risk difference", fmt_ci(weighted_lookup["weighted_risk_difference"], weighted_lower["weighted_risk_difference"], weighted_upper["weighted_risk_difference"], 3), sep = " | "),
  paste("Weighted risk ratio", fmt_ci(weighted_lookup["weighted_risk_ratio"], weighted_lower["weighted_risk_ratio"], weighted_upper["weighted_risk_ratio"], 2), sep = " | ")
)

balance_lines <- c(
  "Covariate | Level | Absolute SMD before weighting | Absolute SMD after weighting",
  "--- | --- | ---: | ---:",
  apply(balance, 1, function(row) {
    paste(
      row[["variable"]],
      row[["level"]],
      fmt_num(row[["abs_unweighted_smd"]], 3),
      fmt_num(row[["abs_weighted_smd"]], 3),
      sep = " | "
    )
  })
)

subgroup_summary <- do.call(rbind, lapply(unique(subgroups$subgroup_variable), function(variable) {
  variable_data <- subgroups[subgroups$subgroup_variable == variable, ]
  do.call(rbind, lapply(unique(variable_data$subgroup_level), function(level) {
    level_data <- variable_data[variable_data$subgroup_level == level, ]
    row0 <- level_data[level_data$COHORT_ID == 0, ]
    row1 <- level_data[level_data$COHORT_ID == 1, ]
    data.frame(
      subgroup = variable,
      level = level,
      comparator_risk = paste0(row0$events, "/", row0$n, " (", fmt_pct(row0$risk, 1), ")"),
      target_risk = paste0(row1$events, "/", row1$n, " (", fmt_pct(row1$risk, 1), ")"),
      stringsAsFactors = FALSE
    )
  }))
}))

subgroup_lines <- c(
  "Subgroup | Level | Comparator risk | Target risk",
  "--- | --- | ---: | ---:",
  apply(subgroup_summary, 1, function(row) paste(row, collapse = " | "))
)

report <- c(
  "# Final Study Report",
  "",
  "## Title",
  "",
  "Comparative risk of adverse events among patients in target versus comparator cohorts in a de-identified observational analytic dataset",
  "",
  "## Abstract",
  "",
  "### Background",
  "",
  "A de-identified person-level observational dataset was evaluated to estimate whether membership in a target cohort was associated with adverse event risk compared with a comparator cohort. Because the dataset contained baseline covariates and a binary outcome but no time-to-event information, the study was designed as a retrospective comparative cohort analysis of binary risk.",
  "",
  "### Methods",
  "",
  paste0("The analysis included ", target$n + comparator$n, " patients: ", comparator$n, " in `COHORT_ID = 0` and ", target$n, " in `COHORT_ID = 1`. The outcome was binary adverse event `AE`. Baseline covariates were age, race, pain level, and LDL. The pre-specified analyses included descriptive summaries, crude risks, multivariable logistic regression, inverse probability of treatment weighting using a propensity score model, covariate balance diagnostics, weight diagnostics, and exploratory subgroup summaries."),
  "",
  "### Results",
  "",
  paste0("Crude adverse event risk was ", fmt_pct(target$risk, 2), " in the target cohort and ", fmt_pct(comparator$risk, 2), " in the comparator cohort. The adjusted odds ratio for target versus comparator cohort was ", fmt_ci(cohort_term$odds_ratio, cohort_term$ci_lower, cohort_term$ci_upper, 2), ". The propensity-score weighted risk difference was ", fmt_ci(weighted_lookup["weighted_risk_difference"], weighted_lower["weighted_risk_difference"], weighted_upper["weighted_risk_difference"], 3), ", and the weighted risk ratio was ", fmt_ci(weighted_lookup["weighted_risk_ratio"], weighted_lower["weighted_risk_ratio"], weighted_upper["weighted_risk_ratio"], 2), "."),
  "",
  "### Conclusions",
  "",
  "The target cohort was consistently associated with higher adverse event risk than the comparator cohort across crude, outcome-regression, and propensity-score weighted analyses. The evidence should be interpreted as an adjusted observational association, not definitive causal evidence, because clinical definitions, timing, follow-up, and unmeasured confounding controls were limited.",
  "",
  "## Background",
  "",
  "Observational patient-level data can support reliable evidence generation when the research question, design, diagnostics, and interpretation are aligned with the information available in the data. This study followed an OHDSI-style journey from dataset intake to protocol-specified estimation and interpretation. The available dataset supported a comparative binary outcome question but did not support time-to-event, incidence-rate, dose-response, or longitudinal treatment-pattern questions.",
  "",
  "The primary research question was whether `COHORT_ID = 1`, compared with `COHORT_ID = 0`, was associated with different adverse event risk after accounting for measured baseline differences in age, race, pain level, and LDL.",
  "",
  "## Methods",
  "",
  "### Data Source and Study Population",
  "",
  "The source file was `analytic_dataset.csv`, a de-identified analytic dataset with one row per patient. Data quality checks confirmed required columns were present, required fields were complete, `PERSON_ID` was unique, and both `COHORT_ID` and `AE` were valid binary variables. No records were excluded by data quality checks.",
  "",
  "### Study Design",
  "",
  "The study was a retrospective, person-level, active-comparator cohort study. `COHORT_ID = 1` was treated as the target cohort and `COHORT_ID = 0` as the comparator cohort. `AE` was treated as the binary adverse event outcome measured during an assumed comparable outcome assessment window.",
  "",
  "### Covariates",
  "",
  "Measured baseline covariates were `AGE`, `RACE`, `PAIN_LEVEL`, and `LDL_I`. `PERSON_ID` was used only as an identifier for uniqueness checks. Because source documentation was unavailable, all baseline covariates were assumed to be measured before or at cohort entry.",
  "",
  "### Statistical Analysis",
  "",
  "Crude event risks were calculated by cohort. Logistic regression was used to estimate the adjusted odds ratio for `COHORT_ID = 1` versus `COHORT_ID = 0`, adjusting for age, race, pain level, and LDL. A propensity score model for cohort membership was fit using the same measured covariates, and inverse probability of treatment weights were used to estimate weighted risks, risk difference, and risk ratio. Bootstrap intervals with 200 replicates were used for weighted effect uncertainty. Diagnostics included standardized mean differences before and after weighting, propensity-score overlap, weight distributions, effective sample size, and exploratory subgroup summaries.",
  "",
  "## Results",
  "",
  "### Study Population and Baseline Characteristics",
  "",
  paste0("The final analysis population included ", target$n + comparator$n, " patients. The target cohort was younger on average, had lower mean pain level, had higher mean LDL, and had a different race distribution than the comparator cohort."),
  "",
  "**Table 1. Baseline Characteristics**",
  "",
  table1_lines,
  "",
  "### Primary and Secondary Effect Estimates",
  "",
  "Crude, adjusted, and weighted analyses all showed higher adverse event risk in the target cohort.",
  "",
  "**Table 2. Main Effect Estimates**",
  "",
  table2_lines,
  "",
  "### Diagnostics",
  "",
  paste0("Covariate balance improved after weighting, with maximum absolute SMD decreasing from ", fmt_num(max_unweighted_smd, 3), " to ", fmt_num(max_weighted_smd, 3), ". The largest remaining imbalance was for ", worst_balance$variable, " (", worst_balance$level, "), with weighted absolute SMD ", fmt_num(worst_balance$abs_weighted_smd, 3), ". The overall propensity-score range was ", fmt_num(overall_ps$ps_min, 3), " to ", fmt_num(overall_ps$ps_max, 3), ". The maximum IPTW was ", fmt_num(overall_ps$weight_max, 2), ", and ", fmt_pct(target_ps$proportion_weight_gt_10, 2), " of target-cohort records had weights greater than 10."),
  "",
  "**Table 3. Covariate Balance Diagnostics**",
  "",
  balance_lines,
  "",
  "**Figure 1. Propensity Score Overlap**",
  "",
  "![Propensity score overlap](results/figure1_propensity_overlap.png)",
  "",
  "**Figure 2. Covariate Balance Before and After Weighting**",
  "",
  "![Covariate balance before and after weighting](results/figure2_covariate_balance.png)",
  "",
  "### Exploratory Subgroup Results",
  "",
  "The target cohort had higher crude adverse event risk than the comparator cohort in every summarized subgroup. These analyses were descriptive and were not designed as formal effect-modification tests.",
  "",
  "**Table 4. Exploratory Subgroup Crude Risks**",
  "",
  subgroup_lines,
  "",
  "## Discussion",
  "",
  "In this de-identified observational analytic dataset, target cohort membership was consistently associated with higher adverse event risk. The estimated absolute association was clinically interpretable: after propensity-score weighting, the target cohort had about 4.6 additional adverse events per 100 patients compared with the comparator cohort. The relative association was also consistent, with a weighted risk ratio of about 1.69 and an adjusted odds ratio of about 1.76.",
  "",
  "The consistency across crude, regression-adjusted, and propensity-score weighted analyses supports the internal coherence of the finding. However, the diagnostics argue for caution. Propensity-score weighting improved measured covariate balance, but LDL remained imbalanced beyond the conventional 0.10 standardized mean difference threshold. Some target-cohort records also had large weights, indicating influence concentration and possible positivity stress. Most importantly, only four measured covariates were available, and the dataset did not include dates, follow-up time, source cohort definitions, outcome ascertainment details, prior history, medication dose, or care setting. These limitations mean that residual and unmeasured confounding remain plausible.",
  "",
  "The appropriate interpretation is therefore that `COHORT_ID = 1` was associated with higher observed adverse event risk than `COHORT_ID = 0` in this analytic file. The study does not by itself establish that target cohort membership caused the higher risk.",
  "",
  "## Limitations",
  "",
  "- Cohort and outcome clinical definitions were not available in the file.",
  "- No dates, follow-up time, or censoring information were available, so hazards and incidence rates could not be estimated.",
  "- Only age, race, pain level, and LDL were available for confounding adjustment.",
  "- LDL remained imbalanced after weighting, suggesting residual measured confounding.",
  "- Some target-cohort records had high inverse probability weights, suggesting influence concentration.",
  "- Subgroup summaries were descriptive and not formal interaction analyses.",
  "- Generalizability cannot be judged because the source population and eligibility definitions were not provided.",
  "",
  "## Conclusions",
  "",
  "The study found a consistent adjusted observational association between target cohort membership and higher adverse event risk. The finding is suitable for internal decision support, hypothesis generation, and planning a more fully specified OHDSI network-style study, but it should not be disseminated as definitive causal evidence without additional source characterization, richer covariate capture, time-at-risk definitions, and empirical calibration or external validation.",
  "",
  "## Associated Output Files",
  "",
  "- Protocol: `step4_protocol_analysis_specification.md`",
  "- Analysis script: `step5_execute_analysis.R`",
  "- Results interpretation: `step6_results_interpretation.md`",
  "- Baseline table: `results/table1_baseline_characteristics.csv`",
  "- Crude outcomes: `results/table2_crude_outcomes.csv`",
  "- Propensity diagnostics: `results/table3_ps_diagnostics.csv`",
  "- Covariate balance: `results/table4_covariate_balance.csv`",
  "- Adjusted model: `results/table5_adjusted_model.csv`",
  "- Weighted effects: `results/table6_weighted_effects.csv`",
  "- Subgroup summaries: `results/table7_subgroup_summaries.csv`",
  "- Propensity overlap figure: `results/figure1_propensity_overlap.png`",
  "- Balance figure: `results/figure2_covariate_balance.png`",
  "",
  "## Step 7 Completion Check",
  "",
  "- A final publication-style study report was written with background, methods, results, discussion, limitations, conclusions, tables, and figures.",
  "- The report references the generated study tables and figures.",
  "- Work product created: `step7_final_study_report.md`."
)

writeLines(report, output_path)

cat("Step 7 complete.\n")
cat("Wrote:", output_path, "\n")