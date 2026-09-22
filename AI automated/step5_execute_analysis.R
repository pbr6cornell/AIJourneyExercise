input_path <- "analytic_dataset.csv"
results_dir <- "results"
summary_path <- "step5_analysis_execution_summary.md"
set.seed(20260922)

required_columns <- c("COHORT_ID", "PERSON_ID", "AGE", "RACE", "PAIN_LEVEL", "LDL_I", "AE")
bootstrap_reps <- 200

if (!dir.exists(results_dir)) {
  dir.create(results_dir, recursive = TRUE)
}

dataset <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)

missing_value <- function(x) {
  is.na(x) | (is.character(x) & trimws(x) == "")
}

check_row <- function(check, result, value, action) {
  data.frame(
    check = check,
    result = result,
    value = as.character(value),
    action = action,
    stringsAsFactors = FALSE
  )
}

missing_columns <- setdiff(required_columns, names(dataset))
checks <- rbind(
  check_row("Required columns present", length(missing_columns) == 0, paste(missing_columns, collapse = "; "), "Stop if false"),
  check_row("Input row count", nrow(dataset) > 0, nrow(dataset), "Stop if false")
)

if (length(missing_columns) > 0) {
  write.csv(checks, file.path(results_dir, "data_quality_checks.csv"), row.names = FALSE)
  stop("Missing expected columns: ", paste(missing_columns, collapse = ", "))
}

dataset <- dataset[, required_columns]
complete_required <- apply(dataset, 1, function(row) !any(is.na(row) | trimws(as.character(row)) == ""))
duplicate_person_ids <- sum(duplicated(dataset$PERSON_ID))
cohort_values_valid <- all(dataset$COHORT_ID %in% c(0, 1))
ae_values_valid <- all(dataset$AE %in% c(0, 1))

checks <- rbind(
  checks,
  check_row("Required fields complete", all(complete_required), sum(!complete_required), "Exclude incomplete records if any"),
  check_row("PERSON_ID unique", duplicate_person_ids == 0, duplicate_person_ids, "Stop if false"),
  check_row("COHORT_ID values limited to 0/1", cohort_values_valid, paste(sort(unique(dataset$COHORT_ID)), collapse = "; "), "Stop if false"),
  check_row("AE values limited to 0/1", ae_values_valid, paste(sort(unique(dataset$AE)), collapse = "; "), "Stop if false")
)

if (!all(complete_required)) {
  dataset <- dataset[complete_required, ]
}

write.csv(checks, file.path(results_dir, "data_quality_checks.csv"), row.names = FALSE)

if (duplicate_person_ids > 0 || !cohort_values_valid || !ae_values_valid) {
  stop("Data quality checks failed. See results/data_quality_checks.csv.")
}

dataset$COHORT_ID <- as.integer(dataset$COHORT_ID)
dataset$AE <- as.integer(dataset$AE)
dataset$RACE <- factor(dataset$RACE)

weighted_mean <- function(x, w) {
  sum(w * x) / sum(w)
}

weighted_var <- function(x, w) {
  mean_x <- weighted_mean(x, w)
  sum(w * (x - mean_x)^2) / sum(w)
}

continuous_smd <- function(x, cohort, weights = NULL) {
  if (is.null(weights)) {
    mean_1 <- mean(x[cohort == 1])
    mean_0 <- mean(x[cohort == 0])
    var_1 <- var(x[cohort == 1])
    var_0 <- var(x[cohort == 0])
  } else {
    mean_1 <- weighted_mean(x[cohort == 1], weights[cohort == 1])
    mean_0 <- weighted_mean(x[cohort == 0], weights[cohort == 0])
    var_1 <- weighted_var(x[cohort == 1], weights[cohort == 1])
    var_0 <- weighted_var(x[cohort == 0], weights[cohort == 0])
  }
  (mean_1 - mean_0) / sqrt((var_1 + var_0) / 2)
}

binary_smd <- function(indicator, cohort, weights = NULL) {
  if (is.null(weights)) {
    p_1 <- mean(indicator[cohort == 1])
    p_0 <- mean(indicator[cohort == 0])
  } else {
    p_1 <- weighted_mean(indicator[cohort == 1], weights[cohort == 1])
    p_0 <- weighted_mean(indicator[cohort == 0], weights[cohort == 0])
  }
  pooled <- (p_1 + p_0) / 2
  if (pooled %in% c(0, 1)) {
    return(0)
  }
  (p_1 - p_0) / sqrt(pooled * (1 - pooled))
}

summarize_continuous <- function(data, variable) {
  do.call(rbind, lapply(c(0, 1), function(cohort) {
    x <- data[data$COHORT_ID == cohort, variable]
    data.frame(
      variable = variable,
      level = "continuous",
      cohort = cohort,
      n = length(x),
      mean = mean(x),
      sd = sd(x),
      median = median(x),
      q1 = unname(quantile(x, 0.25)),
      q3 = unname(quantile(x, 0.75)),
      min = min(x),
      max = max(x),
      count = NA_integer_,
      percent = NA_real_,
      stringsAsFactors = FALSE
    )
  }))
}

summarize_categorical <- function(data, variable) {
  do.call(rbind, lapply(c(0, 1), function(cohort) {
    subset_data <- data[data$COHORT_ID == cohort, ]
    counts <- table(subset_data[[variable]])
    data.frame(
      variable = variable,
      level = names(counts),
      cohort = cohort,
      n = nrow(subset_data),
      mean = NA_real_,
      sd = NA_real_,
      median = NA_real_,
      q1 = NA_real_,
      q3 = NA_real_,
      min = NA_real_,
      max = NA_real_,
      count = as.integer(counts),
      percent = as.numeric(100 * counts / nrow(subset_data)),
      stringsAsFactors = FALSE
    )
  }))
}

table1 <- rbind(
  summarize_continuous(dataset, "AGE"),
  summarize_continuous(dataset, "PAIN_LEVEL"),
  summarize_continuous(dataset, "LDL_I"),
  summarize_categorical(dataset, "RACE")
)
write.csv(table1, file.path(results_dir, "table1_baseline_characteristics.csv"), row.names = FALSE)

outcome_by_cohort <- aggregate(AE ~ COHORT_ID, dataset, function(x) c(events = sum(x), n = length(x), risk = mean(x)))
table2 <- data.frame(
  COHORT_ID = outcome_by_cohort$COHORT_ID,
  events = outcome_by_cohort$AE[, "events"],
  n = outcome_by_cohort$AE[, "n"],
  risk = outcome_by_cohort$AE[, "risk"],
  non_events = outcome_by_cohort$AE[, "n"] - outcome_by_cohort$AE[, "events"],
  stringsAsFactors = FALSE
)
crude_model <- glm(AE ~ COHORT_ID, data = dataset, family = binomial())
crude_or <- exp(coef(crude_model)["COHORT_ID"])
crude_ci <- exp(confint.default(crude_model)["COHORT_ID", ])
table2$crude_risk_difference_target_minus_comparator <- table2$risk[table2$COHORT_ID == 1] - table2$risk[table2$COHORT_ID == 0]
table2$crude_risk_ratio_target_vs_comparator <- table2$risk[table2$COHORT_ID == 1] / table2$risk[table2$COHORT_ID == 0]
table2$crude_odds_ratio_target_vs_comparator <- crude_or
table2$crude_or_ci_lower <- crude_ci[1]
table2$crude_or_ci_upper <- crude_ci[2]
write.csv(table2, file.path(results_dir, "table2_crude_outcomes.csv"), row.names = FALSE)

ps_model <- glm(COHORT_ID ~ AGE + RACE + PAIN_LEVEL + LDL_I, data = dataset, family = binomial())
dataset$propensity_score <- pmin(pmax(predict(ps_model, type = "response"), 1e-6), 1 - 1e-6)
dataset$iptw <- ifelse(dataset$COHORT_ID == 1, 1 / dataset$propensity_score, 1 / (1 - dataset$propensity_score))

weight_summary <- do.call(rbind, lapply(c(0, 1), function(cohort) {
  subset_data <- dataset[dataset$COHORT_ID == cohort, ]
  weights <- subset_data$iptw
  ps <- subset_data$propensity_score
  data.frame(
    COHORT_ID = cohort,
    n = nrow(subset_data),
    ps_min = min(ps),
    ps_q1 = unname(quantile(ps, 0.25)),
    ps_median = median(ps),
    ps_mean = mean(ps),
    ps_q3 = unname(quantile(ps, 0.75)),
    ps_max = max(ps),
    weight_min = min(weights),
    weight_q1 = unname(quantile(weights, 0.25)),
    weight_median = median(weights),
    weight_mean = mean(weights),
    weight_q3 = unname(quantile(weights, 0.75)),
    weight_max = max(weights),
    effective_sample_size = sum(weights)^2 / sum(weights^2),
    proportion_weight_gt_10 = mean(weights > 10),
    proportion_weight_gt_20 = mean(weights > 20),
    stringsAsFactors = FALSE
  )
}))
overall_weights <- dataset$iptw
weight_summary <- rbind(
  weight_summary,
  data.frame(
    COHORT_ID = "overall",
    n = nrow(dataset),
    ps_min = min(dataset$propensity_score),
    ps_q1 = unname(quantile(dataset$propensity_score, 0.25)),
    ps_median = median(dataset$propensity_score),
    ps_mean = mean(dataset$propensity_score),
    ps_q3 = unname(quantile(dataset$propensity_score, 0.75)),
    ps_max = max(dataset$propensity_score),
    weight_min = min(overall_weights),
    weight_q1 = unname(quantile(overall_weights, 0.25)),
    weight_median = median(overall_weights),
    weight_mean = mean(overall_weights),
    weight_q3 = unname(quantile(overall_weights, 0.75)),
    weight_max = max(overall_weights),
    effective_sample_size = sum(overall_weights)^2 / sum(overall_weights^2),
    proportion_weight_gt_10 = mean(overall_weights > 10),
    proportion_weight_gt_20 = mean(overall_weights > 20),
    stringsAsFactors = FALSE
  )
)
write.csv(weight_summary, file.path(results_dir, "table3_ps_diagnostics.csv"), row.names = FALSE)

balance_rows <- list()
for (variable in c("AGE", "PAIN_LEVEL", "LDL_I")) {
  balance_rows[[length(balance_rows) + 1]] <- data.frame(
    variable = variable,
    level = "continuous",
    unweighted_smd = continuous_smd(dataset[[variable]], dataset$COHORT_ID),
    weighted_smd = continuous_smd(dataset[[variable]], dataset$COHORT_ID, dataset$iptw),
    stringsAsFactors = FALSE
  )
}
for (level in levels(dataset$RACE)) {
  indicator <- as.integer(dataset$RACE == level)
  balance_rows[[length(balance_rows) + 1]] <- data.frame(
    variable = "RACE",
    level = level,
    unweighted_smd = binary_smd(indicator, dataset$COHORT_ID),
    weighted_smd = binary_smd(indicator, dataset$COHORT_ID, dataset$iptw),
    stringsAsFactors = FALSE
  )
}
table4 <- do.call(rbind, balance_rows)
table4$abs_unweighted_smd <- abs(table4$unweighted_smd)
table4$abs_weighted_smd <- abs(table4$weighted_smd)
write.csv(table4, file.path(results_dir, "table4_covariate_balance.csv"), row.names = FALSE)

adjusted_model <- glm(AE ~ COHORT_ID + AGE + RACE + PAIN_LEVEL + LDL_I, data = dataset, family = binomial())
adjusted_coef <- summary(adjusted_model)$coefficients
adjusted_ci <- confint.default(adjusted_model)
table5 <- data.frame(
  term = rownames(adjusted_coef),
  estimate_log_odds = adjusted_coef[, "Estimate"],
  std_error = adjusted_coef[, "Std. Error"],
  p_value = adjusted_coef[, "Pr(>|z|)"],
  odds_ratio = exp(adjusted_coef[, "Estimate"]),
  ci_lower = exp(adjusted_ci[, 1]),
  ci_upper = exp(adjusted_ci[, 2]),
  row.names = NULL,
  stringsAsFactors = FALSE
)
write.csv(table5, file.path(results_dir, "table5_adjusted_model.csv"), row.names = FALSE)

compute_weighted_effects <- function(data) {
  model <- glm(COHORT_ID ~ AGE + RACE + PAIN_LEVEL + LDL_I, data = data, family = binomial())
  ps <- pmin(pmax(predict(model, type = "response"), 1e-6), 1 - 1e-6)
  weights <- ifelse(data$COHORT_ID == 1, 1 / ps, 1 / (1 - ps))
  risk_1 <- weighted_mean(data$AE[data$COHORT_ID == 1], weights[data$COHORT_ID == 1])
  risk_0 <- weighted_mean(data$AE[data$COHORT_ID == 0], weights[data$COHORT_ID == 0])
  c(
    weighted_risk_target = risk_1,
    weighted_risk_comparator = risk_0,
    weighted_risk_difference = risk_1 - risk_0,
    weighted_risk_ratio = risk_1 / risk_0
  )
}

weighted_effects <- compute_weighted_effects(dataset)
bootstrap_effects <- replicate(bootstrap_reps, {
  sampled <- dataset[sample(seq_len(nrow(dataset)), replace = TRUE), ]
  tryCatch(compute_weighted_effects(sampled), error = function(error) rep(NA_real_, 4))
})
bootstrap_effects <- t(bootstrap_effects)
colnames(bootstrap_effects) <- names(weighted_effects)
bootstrap_ci <- apply(bootstrap_effects, 2, function(x) {
  stats::quantile(x, probs = c(0.025, 0.975), na.rm = TRUE)
})
table6 <- data.frame(
  measure = names(weighted_effects),
  estimate = as.numeric(weighted_effects),
  ci_lower = as.numeric(bootstrap_ci[1, ]),
  ci_upper = as.numeric(bootstrap_ci[2, ]),
  bootstrap_reps_requested = bootstrap_reps,
  bootstrap_reps_successful = colSums(!is.na(bootstrap_effects)),
  stringsAsFactors = FALSE
)
write.csv(table6, file.path(results_dir, "table6_weighted_effects.csv"), row.names = FALSE)

dataset$age_group <- cut(dataset$AGE, breaks = c(-Inf, 49, 64, 74, Inf), labels = c("<50", "50-64", "65-74", "75+"), right = TRUE)
pain_breaks <- unique(quantile(dataset$PAIN_LEVEL, probs = c(0, 1 / 3, 2 / 3, 1), na.rm = TRUE))
dataset$pain_category <- cut(dataset$PAIN_LEVEL, breaks = pain_breaks, include.lowest = TRUE, labels = paste0("tertile_", seq_len(length(pain_breaks) - 1)))
dataset$ldl_category <- cut(dataset$LDL_I, breaks = c(-Inf, 99, 129, Inf), labels = c("<100", "100-129", "130+"), right = TRUE)

summarize_subgroup <- function(data, variable) {
  do.call(rbind, lapply(levels(factor(data[[variable]])), function(level) {
    subset_data <- data[as.character(data[[variable]]) == level, ]
    do.call(rbind, lapply(c(0, 1), function(cohort) {
      cohort_data <- subset_data[subset_data$COHORT_ID == cohort, ]
      data.frame(
        subgroup_variable = variable,
        subgroup_level = level,
        COHORT_ID = cohort,
        n = nrow(cohort_data),
        events = sum(cohort_data$AE),
        risk = ifelse(nrow(cohort_data) > 0, mean(cohort_data$AE), NA_real_),
        stringsAsFactors = FALSE
      )
    }))
  }))
}

table7 <- rbind(
  summarize_subgroup(dataset, "age_group"),
  summarize_subgroup(dataset, "RACE"),
  summarize_subgroup(dataset, "pain_category"),
  summarize_subgroup(dataset, "ldl_category")
)
write.csv(table7, file.path(results_dir, "table7_subgroup_summaries.csv"), row.names = FALSE)

png(file.path(results_dir, "figure1_propensity_overlap.png"), width = 900, height = 600)
hist(dataset$propensity_score[dataset$COHORT_ID == 0], breaks = 40, col = rgb(0.1, 0.4, 0.8, 0.45), border = "white", xlim = c(0, 1), main = "Propensity Score Overlap", xlab = "Propensity score")
hist(dataset$propensity_score[dataset$COHORT_ID == 1], breaks = 40, col = rgb(0.9, 0.3, 0.1, 0.45), border = "white", add = TRUE)
legend("topright", legend = c("COHORT_ID = 0", "COHORT_ID = 1"), fill = c(rgb(0.1, 0.4, 0.8, 0.45), rgb(0.9, 0.3, 0.1, 0.45)), border = NA)
dev.off()

png(file.path(results_dir, "figure2_covariate_balance.png"), width = 900, height = 600)
plot_range <- range(c(table4$abs_unweighted_smd, table4$abs_weighted_smd, 0.1), na.rm = TRUE)
plot(seq_len(nrow(table4)), table4$abs_unweighted_smd, pch = 16, col = "gray30", ylim = plot_range, xaxt = "n", xlab = "Covariate", ylab = "Absolute standardized mean difference", main = "Covariate Balance Before and After Weighting")
points(seq_len(nrow(table4)), table4$abs_weighted_smd, pch = 16, col = "steelblue")
abline(h = 0.1, lty = 2, col = "firebrick")
axis(1, at = seq_len(nrow(table4)), labels = paste(table4$variable, table4$level, sep = ":"), las = 2, cex.axis = 0.75)
legend("topright", legend = c("Before weighting", "After weighting", "0.10 threshold"), pch = c(16, 16, NA), lty = c(NA, NA, 2), col = c("gray30", "steelblue", "firebrick"), bty = "n")
dev.off()

max_weight <- max(dataset$iptw)
max_weighted_smd <- max(table4$abs_weighted_smd, na.rm = TRUE)
trim_needed <- any(dataset$propensity_score < 0.01 | dataset$propensity_score > 0.99) || max_weight > 20

if (trim_needed) {
  trimmed <- dataset[dataset$propensity_score >= 0.01 & dataset$propensity_score <= 0.99, ]
  trimmed_effects <- compute_weighted_effects(trimmed)
  table6_trimmed <- data.frame(
    measure = names(trimmed_effects),
    estimate = as.numeric(trimmed_effects),
    n_after_trimming = nrow(trimmed),
    n_trimmed = nrow(dataset) - nrow(trimmed),
    stringsAsFactors = FALSE
  )
} else {
  table6_trimmed <- data.frame(
    measure = names(weighted_effects),
    estimate = as.numeric(weighted_effects),
    n_after_trimming = nrow(dataset),
    n_trimmed = 0,
    stringsAsFactors = FALSE
  )
}
write.csv(table6_trimmed, file.path(results_dir, "table6b_weighted_effects_trimmed_sensitivity.csv"), row.names = FALSE)

writeLines(c(
  "# Step 5: Analysis Execution Summary",
  "",
  paste0("Date completed: ", Sys.Date()),
  "",
  "## Execution Status",
  "",
  "The protocol-specified analysis code was developed, tested through built-in data quality checks, and executed in R.",
  "",
  "## Inputs",
  "",
  paste0("- Source dataset: `", input_path, "`"),
  paste0("- Analysis rows used: ", nrow(dataset)),
  paste0("- Bootstrap replicates requested for weighted effects: ", bootstrap_reps),
  paste0("- Bootstrap replicates successful: ", min(table6$bootstrap_reps_successful)),
  "",
  "## Code and Output Files",
  "",
  "- Analysis script: `step5_execute_analysis.R`",
  "- Data quality checks: `results/data_quality_checks.csv`",
  "- Baseline characteristics: `results/table1_baseline_characteristics.csv`",
  "- Crude outcomes: `results/table2_crude_outcomes.csv`",
  "- Propensity score diagnostics: `results/table3_ps_diagnostics.csv`",
  "- Covariate balance: `results/table4_covariate_balance.csv`",
  "- Adjusted outcome model: `results/table5_adjusted_model.csv`",
  "- Weighted effects: `results/table6_weighted_effects.csv`",
  "- Trimmed sensitivity analysis: `results/table6b_weighted_effects_trimmed_sensitivity.csv`",
  "- Subgroup summaries: `results/table7_subgroup_summaries.csv`",
  "- Propensity overlap figure: `results/figure1_propensity_overlap.png`",
  "- Covariate balance figure: `results/figure2_covariate_balance.png`",
  "",
  "## Diagnostics Snapshot",
  "",
  paste0("- Maximum absolute weighted standardized mean difference: ", round(max_weighted_smd, 4)),
  paste0("- Maximum inverse probability weight: ", round(max_weight, 4)),
  paste0("- Propensity-score trimming sensitivity triggered: ", trim_needed),
  "",
  "## Step 5 Completion Check",
  "",
  "- Study code was developed in R.",
  "- Data quality checks were executed before modeling.",
  "- Protocol-specified descriptive, propensity-score, outcome-regression, weighted-effect, diagnostic, figure, and subgroup outputs were created.",
  "- Work product created: `step5_execute_analysis.R`, `step5_analysis_execution_summary.md`, and the `results/` directory."
), summary_path)

cat("Step 5 complete.\n")
cat("Rows analyzed:", nrow(dataset), "\n")
cat("Maximum weighted SMD:", round(max_weighted_smd, 4), "\n")
cat("Maximum IPTW:", round(max_weight, 4), "\n")
cat("Wrote outputs to:", results_dir, "\n")