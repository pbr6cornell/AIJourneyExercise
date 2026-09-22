input_path <- "analytic_dataset.csv"
output_path <- "step2_research_questions.md"

dataset <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)

required_columns <- c("COHORT_ID", "PERSON_ID", "AGE", "RACE", "PAIN_LEVEL", "LDL_I", "AE")
missing_columns <- setdiff(required_columns, names(dataset))
if (length(missing_columns) > 0) {
  stop("Missing expected columns: ", paste(missing_columns, collapse = ", "))
}

cohort_counts <- table(dataset$COHORT_ID)
ae_table <- with(dataset, table(COHORT_ID, AE))
ae_rates <- with(dataset, tapply(AE, COHORT_ID, mean))
continuous_summary <- aggregate(
  cbind(AGE, PAIN_LEVEL, LDL_I) ~ COHORT_ID,
  data = dataset,
  FUN = function(x) round(mean(x), 2)
)
race_percent <- round(100 * prop.table(with(dataset, table(COHORT_ID, RACE)), 1), 1)

format_count <- function(value) {
  format(value, big.mark = ",", scientific = FALSE, trim = TRUE)
}

cohort_rows <- vapply(names(cohort_counts), function(cohort) {
  ae0 <- if ("0" %in% colnames(ae_table)) ae_table[cohort, "0"] else 0
  ae1 <- if ("1" %in% colnames(ae_table)) ae_table[cohort, "1"] else 0
  paste(
    cohort,
    format_count(cohort_counts[[cohort]]),
    format_count(ae1),
    paste0(round(100 * ae_rates[[cohort]], 2), "%"),
    format_count(ae0),
    sep = " | "
  )
}, character(1))

continuous_rows <- apply(continuous_summary, 1, function(row) {
  paste(row, collapse = " | ")
})

race_rows <- apply(race_percent, 1, function(row) {
  paste(names(row), paste0(row, "%"), sep = ": ", collapse = "; ")
})
race_rows <- paste(names(race_rows), race_rows, sep = " | ")

writeLines(c(
  "# Step 2: Research Questions",
  "",
  paste0("Date completed: ", Sys.Date()),
  "",
  "## Data Signals Used",
  "",
  "The available analysis variables support questions about a binary cohort contrast, baseline covariates, and a binary adverse event outcome. They do not support questions requiring treatment dates, outcome dates, censoring dates, longitudinal exposure patterns, dose, duration, or follow-up time.",
  "",
  "### Cohort and Outcome Counts",
  "",
  "COHORT_ID | persons | AE events | crude AE risk | non-events",
  "--- | ---: | ---: | ---: | ---:",
  cohort_rows,
  "",
  "### Mean Baseline Covariates by Cohort",
  "",
  "COHORT_ID | AGE | PAIN_LEVEL | LDL_I",
  "--- | ---: | ---: | ---:",
  continuous_rows,
  "",
  "### Race Distribution by Cohort",
  "",
  "COHORT_ID | race distribution",
  "--- | ---",
  race_rows,
  "",
  "## Primary Research Question",
  "",
  "Among patients represented in the analytic dataset, is membership in `COHORT_ID = 1`, compared with `COHORT_ID = 0`, associated with a different risk of the binary adverse event `AE`, after accounting for measured baseline differences in age, race, pain level, and baseline LDL?",
  "",
  "## Secondary Research Questions",
  "",
  "1. How different are the two cohorts at baseline with respect to age, race, pain level, and LDL, and do those differences indicate meaningful confounding risk?",
  "2. Is the cohort-adverse event association consistent across clinically relevant subgroups defined by age, race, baseline pain level, or LDL?",
  "3. Which measured baseline characteristics are associated with adverse event risk, and do they explain part of the crude difference between cohorts?",
  "",
  "## Questions Not Appropriate for This Dataset",
  "",
  "- Time-to-event effectiveness or safety questions, because no index dates, event dates, censoring dates, or follow-up time are available.",
  "- Dose-response, duration-response, adherence, switching, or persistence questions, because exposure intensity and longitudinal treatment data are unavailable.",
  "- Incidence-rate questions, because person-time cannot be calculated.",
  "- Broad clinical generalizability claims, because the source population, eligibility criteria, care setting, and cohort definitions are not yet described in the data file.",
  "",
  "## OHDSI Framing Decisions and Assumptions",
  "",
  "- `COHORT_ID` is treated as the target-comparator cohort indicator, with `1` as the target cohort and `0` as the comparator cohort, pending confirmation from source documentation.",
  "- `AE` is treated as the binary adverse event outcome measured during a fixed analytic window, pending confirmation from source documentation.",
  "- `AGE`, `RACE`, `PAIN_LEVEL`, and `LDL_I` are treated as baseline covariates available for confounding assessment and adjustment.",
  "- Each `PERSON_ID` appears once in the analytic dataset, so the unit of analysis is the person-level record.",
  "- Because variable labels and clinical context are absent, the primary research question is intentionally framed as an association/comparative risk question rather than a causal claim at this stage.",
  "",
  "## Step 2 Completion Check",
  "",
  "- Appropriate primary and secondary research questions were identified from the available variables.",
  "- Unsupported research questions were explicitly ruled out.",
  "- Work product created: `step2_research_questions.md`."
), output_path)

cat("Step 2 complete.\n")
cat("Wrote:", output_path, "\n")