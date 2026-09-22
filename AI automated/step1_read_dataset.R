input_path <- "analytic_dataset.csv"
output_path <- "step1_dataset_intake.md"

dataset <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)

is_missing_value <- function(x) {
  is.na(x) | (is.character(x) & trimws(x) == "")
}

summarize_column <- function(name, x) {
  missing <- is_missing_value(x)
  non_missing <- x[!missing]
  examples <- unique(as.character(non_missing))
  examples <- head(examples, 5)

  data.frame(
    column = name,
    class = paste(class(x), collapse = "/"),
    missing = sum(missing),
    missing_percent = round(100 * mean(missing), 1),
    unique_values = length(unique(non_missing)),
    examples = paste(examples, collapse = "; "),
    stringsAsFactors = FALSE
  )
}

column_summary <- do.call(
  rbind,
  Map(summarize_column, names(dataset), dataset)
)

writeLines(c(
  "# Step 1: Dataset Intake",
  "",
  paste0("Date completed: ", Sys.Date()),
  "",
  "## Source File",
  "",
  paste0("- File: `", input_path, "`"),
  paste0("- Absolute path: `", normalizePath(input_path, winslash = "/"), "`"),
  paste0("- Rows: ", nrow(dataset)),
  paste0("- Columns: ", ncol(dataset)),
  "",
  "## Decisions and Assumptions",
  "",
  "- The CSV was read with base R `read.csv()` using `stringsAsFactors = FALSE` to preserve text fields for later recoding decisions.",
  "- Original column names were preserved with `check.names = FALSE`.",
  "- Blank character fields were treated as missing for the intake summary.",
  "- No analysis-ready transformations were applied in this step.",
  "",
  "## Column Summary",
  "",
  paste(c("column", "class", "missing", "missing_percent", "unique_values", "examples"), collapse = " | "),
  paste(rep("---", 6), collapse = " | "),
  apply(column_summary, 1, function(row) paste(row, collapse = " | ")),
  "",
  "## First Six Rows",
  "",
  "```",
  paste(capture.output(print(utils::head(dataset, 6))), collapse = "\n"),
  "```",
  "",
  "## Step 1 Completion Check",
  "",
  "- `analytic_dataset.csv` was successfully read into R.",
  "- Dataset structure, missingness, example values, and first rows were documented.",
  "- Work product created: `step1_dataset_intake.md`."
), output_path)

cat("Read complete.\n")
cat("Rows:", nrow(dataset), "\n")
cat("Columns:", ncol(dataset), "\n")
cat("Wrote:", output_path, "\n")