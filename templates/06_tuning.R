# A small comparison of smooth MaxEnt models; regularization discourages overfit.
decision <- list(
  feature_classes = c("l","lq","lqp"), regmult = c(1,2,4),
  omission_quantile = 0.10,
  reviewed = FALSE, rationale = ""
)
