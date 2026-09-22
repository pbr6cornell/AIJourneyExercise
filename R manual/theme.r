theme_data_only <- function(base_size = 12) {
  theme_void(base_size = base_size) +               # start from a blank base
    theme(
      panel.background   = element_blank(),        # no panel background
      panel.grid         = element_blank(),        # no grid lines
      panel.border       = element_blank(),        # no panel border
      axis.line          = element_blank(),        # no axis lines
      axis.ticks         = element_blank(),        # no ticks
      axis.text          = element_blank(),        # no tick labels
      axis.title         = element_blank(),        # no axis titles
      legend.position    = "none",                 # hide legend
      plot.background    = element_blank(),        # no plot background
      plot.title         = element_blank(),        # no title
      plot.subtitle      = element_blank(),
      plot.caption       = element_blank(),
      strip.background   = element_blank(),        # hide facet strip background
      strip.text         = element_blank(),        # hide facet labels
      plot.margin        = margin(0, 0, 0, 0)      # tighten margins
    )
}