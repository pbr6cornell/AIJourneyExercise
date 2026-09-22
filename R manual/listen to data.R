library(ggplot2)

input_file <- "analytic_dataset.csv"

data <- read.csv(input_file, stringsAsFactors = FALSE)


ggplot(data) +
  aes(x = PAIN_LEVEL, y = LDL_I, color = RACE) +
  geom_point(alpha = 0.65, size = 1.5) +
  facet_wrap(vars(COHORT_ID)) +
  scale_color_manual(values = c(B = "navy", O = "orange", W = "white")) +
  theme_data_only()