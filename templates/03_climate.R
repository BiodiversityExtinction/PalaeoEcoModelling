# Define the projection domain before seeing model predictions.
# This rectangle is a STUDY DOMAIN; use docs/PARAMETERS.md to justify it.
decision <- list(
  extent = c(xmin=-15,xmax=132,ymin=30,ymax=75),
  projection_ages_ka = seq(58.75,1.25,by=-2.5),
  average_years = 10L, # Average monthly values over this many years before bioclim.
  extraction = "mean_3x3", # 'focal_cell' or 'mean_3x3'; same rule for background.
  land_threshold = 0.5, ice_threshold = 0.5,
  reviewed = FALSE, rationale = ""
)
