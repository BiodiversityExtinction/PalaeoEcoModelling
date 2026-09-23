# Regions summarize predictions. They do not refit or restrict the models.
decision <- list(
  mode = "longitude_bands", # 'whole', 'longitude_bands', 'latitude_bands', 'polygons'
  breaks = c(-15,50,132), names = c("West","East"),
  polygon_file = "", name_column = "region", # Used only for mode='polygons'.
  map_ages_ka = c(21.25,13.75,8.75,1.25), # Must exist among projection times.
  reviewed = FALSE, rationale = ""
)
