# Complete AFTER inspecting 04_variables. No automatic deletion of predictors.
decision <- list(
  predictors = c("temp_warmest","temp_seasonality","precip_summer","precip_winter"),
  background_n = 12000L, # Total across fossil-age-supported projection times.
  block_km = 750, folds = 4L,
  reviewed = FALSE, rationale = ""
)
