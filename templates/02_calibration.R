# Read docs/PARAMETERS.md. All calendar ages are cal BP (1950), not BCE.
decision <- list(
  curve = "intcal20", # Northern Hemisphere terrestrial radiocarbon only.
  age_points = 10L, # Equally spaced across central 95.4% calibrated interval.
  boundary_policy = "exclude", # 'exclude' or 'keep_flagged'; discuss old dates.
  reviewed = FALSE,
  rationale = ""
)
