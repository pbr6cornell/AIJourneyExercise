results_dir <- "results"
output_path <- "step6_results_interpretation.md"

read_result <- function(file_name) {
  read.csv(file.path(results_dir, file_name), stringsAsFactors = FALSE, check.names = FALSE)
}

fmt_pct <- function(x, digits = 1) {
  paste0(round(100 * x, digits), "%")
}

fmt_num <- function(x, digits = 2) {
  format(round(x, digits), nsmall = digits, trim = TRUE, scientific = FALSE)
}

fmt_ci <- function(estimate, lower, upper, digits = 2) {
  paste0(fmt_num(estimate, digits), " (95% CI ", fmt_num(lower, digits), " to ", fmt_num(upper, digits), ")")
}

data_quality <- read_result("data_quality_checks.csv")
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
worst_weighted_balance <- balance[which.max(balance$abs_weighted_smd), ]

quality_rows <- apply(data_quality, 1, function(row) paste(row["check"], row["result"], row["value"], sep = " | "))
balance_rows <- apply(balance, 1, function(row) {
  paste(
    row["variable"],
    row["level"],
    fmt_num(as.numeric(row["abs_unweighted_smd"]), 3),
    fmt_num(as.numeric(row["abs_weighted_smd"]), 3),
    sep = " | "
  )
})

age0 <- baseline[baseline$variable == "AGE" & baseline$cohort == 0, ]
age1 <- baseline[baseline$variable == "AGE" & baseline$cohort == 1, ]
pain0 <- baseline[baseline$variable == "PAIN_LEVEL" & baseline$cohort == 0, ]
pain1 <- baseline[baseline$variable == "PAIN_LEVEL" & baseline$cohort == 1, ]
ldl0 <- baseline[baseline$variable == "LDL_I" & baseline$cohort == 0, ]
ldl1 <- baseline[baseline$variable == "LDL_I" & baseline$cohort == 1, ]

subgroup_lines <- character(0)
for (variable in unique(subgroups$subgroup_variable)) {
  variable_data <- subgroups[subgroups$subgroup_variable == variable, ]
  for (level in unique(variable_data$subgroup_level)) {
    level_data <- variable_data[variable_data$subgroup_level == level, ]
    subgroup_0 <- level_data[level_data$COHORT_ID == 0, ]
    subgroup_1 <- level_data[level_data$COHORT_ID == 1, ]
    subgroup_lines <- c(
      subgroup_lines,
      paste0(
        "- ", variable, " = ", level, ": target risk ", fmt_pct(subgroup_1$risk, 1),
        " (", subgroup_1$events, "/", subgroup_1$n, ") vs comparator risk ", fmt_pct(subgroup_0$risk, 1),
        " (", subgroup_0$events, "/", subgroup_0$n, ")"
      )
    )
  }
}

interpretation <- c(
  "# Step 6: Interpretation of Study Results",
  "",
  paste0("Date completed: ", Sys.Date()),
  "",
  "## Data Quality and Analysis Population",
  "",
  paste0("The analysis included ", target$n + comparator$n, " patient-level records: ", comparator$n, " in the comparator cohort (`COHORT_ID = 0`) and ", target$n, " in the target cohort (`COHORT_ID = 1`). Required variables were complete, `PERSON_ID` was unique, and `COHORT_ID` and `AE` were limited to valid binary values."),
  "",
  "check | result | value",
  "--- | --- | ---",
  quality_rows,
  "",
  "## Baseline Summary",
  "",
  paste0("Before adjustment, the target cohort was younger on average than the comparator cohort (mean age ", fmt_num(age1$mean, 1), " vs ", fmt_num(age0$mean, 1), "), had lower mean pain level (", fmt_num(pain1$mean, 2), " vs ", fmt_num(pain0$mean, 2), "), and had higher mean LDL (", fmt_num(ldl1$mean, 1), " vs ", fmt_num(ldl0$mean, 1), "). Race distribution also differed, with a larger White proportion in the target cohort."),
  "",
  "These baseline differences support the protocol decision to use confounding adjustment rather than relying on crude comparisons alone.",
  "",
  "## Crude Outcome Results",
  "",
  paste0("Crude adverse event risk was ", fmt_pct(target$risk, 2), " in the target cohort and ", fmt_pct(comparator$risk, 2), " in the comparator cohort. The crude risk difference was ", fmt_pct(target$crude_risk_difference_target_minus_comparator, 2), ", and the crude risk ratio was ", fmt_num(target$crude_risk_ratio_target_vs_comparator, 2), "."),
  "",
  paste0("The crude odds ratio for the target versus comparator cohort was ", fmt_ci(target$crude_odds_ratio_target_vs_comparator, target$crude_or_ci_lower, target$crude_or_ci_upper, 2), "."),
  "",
  "## Adjusted Outcome Model",
  "",
  paste0("After adjustment for age, race, pain level, and LDL in logistic regression, the target cohort remained associated with higher odds of adverse event: adjusted odds ratio ", fmt_ci(cohort_term$odds_ratio, cohort_term$ci_lower, cohort_term$ci_upper, 2), ", p = ", format(cohort_term$p_value, scientific = TRUE, digits = 3), "."),
  "",
  "Measured covariates were also associated with adverse event risk in the adjusted model. Higher age, higher pain level, and higher LDL were associated with higher odds of adverse event, while the observed `RACE` categories had different risks relative to the model reference category.",
  "",
  "## Propensity Score Weighted Results",
  "",
  paste0("The propensity-score weighted target risk was ", fmt_pct(weighted_lookup["weighted_risk_target"], 2), " and the weighted comparator risk was ", fmt_pct(weighted_lookup["weighted_risk_comparator"], 2), ". The weighted risk difference was ", fmt_ci(weighted_lookup["weighted_risk_difference"], weighted_lower["weighted_risk_difference"], weighted_upper["weighted_risk_difference"], 3), ", and the weighted risk ratio was ", fmt_ci(weighted_lookup["weighted_risk_ratio"], weighted_lower["weighted_risk_ratio"], weighted_upper["weighted_risk_ratio"], 2), "."),
  "",
  paste0("The trimmed sensitivity analysis did not remove any records (`n_trimmed = ", unique(trimmed$n_trimmed), "`), so the trimmed weighted estimates were identical to the main weighted estimates."),
  "",
  "## Diagnostics Interpretation",
  "",
  paste0("Baseline balance improved after propensity-score weighting. The maximum absolute standardized mean difference decreased from ", fmt_num(max_unweighted_smd, 3), " before weighting to ", fmt_num(max_weighted_smd, 3), " after weighting."),
  "",
  paste0("However, the largest post-weighting imbalance remained above the conventional 0.10 threshold: ", worst_weighted_balance$variable, " (", worst_weighted_balance$level, ") had an absolute weighted SMD of ", fmt_num(worst_weighted_balance$abs_weighted_smd, 3), ". This means measured confounding was reduced but not fully resolved."),
  "",
  paste0("Propensity-score overlap was adequate in the sense that no records had scores below 0.01 or above 0.99. The observed propensity-score range was ", fmt_num(overall_ps$ps_min, 3), " to ", fmt_num(overall_ps$ps_max, 3), ". Weight diagnostics still show some influence concentration: the maximum IPTW was ", fmt_num(overall_ps$weight_max, 2), ", with ", fmt_pct(target_ps$proportion_weight_gt_10, 2), " of target-cohort records having weights greater than 10."),
  "",
  "variable | level | abs SMD before weighting | abs SMD after weighting",
  "--- | --- | ---: | ---:",
  balance_rows,
  "",
  "## Exploratory Subgroup Summary",
  "",
  "The target cohort had higher crude adverse event risk than the comparator cohort in every summarized subgroup. These subgroup results are descriptive only and should not be interpreted as formal effect-modification tests.",
  "",
  subgroup_lines,
  "",
  "## Overall Interpretation",
  "",
  "Across crude, multivariable-adjusted, and propensity-score weighted analyses, `COHORT_ID = 1` was consistently associated with higher adverse event risk than `COHORT_ID = 0`. The absolute weighted difference was about 4.6 additional adverse events per 100 patients, and the weighted relative risk was about 1.69.",
  "",
  "The direction and magnitude are internally consistent across methods, which strengthens the descriptive finding. Still, the result should be interpreted as an adjusted observational association rather than definitive causal evidence. The main reasons are limited covariate information, unknown source definitions for cohort and outcome, residual LDL imbalance after weighting, high weights for some target-cohort records, and absence of timing or follow-up information.",
  "",
  "## Step 6 Completion Check",
  "",
  "- Study results, diagnostics, and summary statistics were interpreted.",
  "- Data quality, crude results, adjusted regression, propensity-score weighted results, balance diagnostics, weight diagnostics, and subgroup summaries were reviewed.",
  "- Work product created: `step6_results_interpretation.md`."
)

writeLines(interpretation, output_path)

cat("Step 6 complete.\n")
cat("Wrote:", output_path, "\n")
cat("Adjusted OR:", fmt_num(cohort_term$odds_ratio, 3), "\n")
cat("Weighted RD:", fmt_num(weighted_lookup["weighted_risk_difference"], 4), "\n")
cat("Weighted RR:", fmt_num(weighted_lookup["weighted_risk_ratio"], 3), "\n")