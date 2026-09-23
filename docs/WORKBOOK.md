# Student checkpoint notes

Keep a copy of these questions with your answers. A technically successful run
is only the beginning of interpreting an ecological model.

## Fossils and chronology

1. What taxon/population and time interval are you investigating?
2. How many independent specimens and localities remain after your quality filter?
3. Are coordinates actual collection sites or broad locality estimates?
4. Which dates are direct, which are contextual, and which were redated?
5. What does the calibrated density show that a single mean age hides?
6. Did calibration-boundary or climate-mask exclusions alter regional coverage?

## Climate and design

1. Why is your study/background domain plausible for this species?
2. Why focal cell or 3x3? How large is the latter at your fossil latitudes?
3. Which candidate variables are correlated? Why retain your selected subset?
4. Could uneven fossil collection explain an apparent climate preference?
5. What is a background point, and why is it not a fossil absence?
6. How many localities are in each fold? Can nearby sites straddle block edges?

## Models and uncertainty

1. Does a more complex MaxEnt model improve all folds, or only one?
2. Which variables reduce held-out skill when shuffled? Is this causal evidence?
3. Where do MaxEnt and Gaussian disagree, and do their raw scores mean the same thing?
4. Is the mean-climate baseline similar to the sampled-age ensemble?
5. Why are ten dates for one fossil not ten independent fossils?
6. Which sources of uncertainty are missing from the sensitivity ribbons?
7. Are projections outside the training climate ranges? What does clamping do?

## Regional interpretation

1. Do the reporting regions correspond to your biological question, rather than
   boundaries selected to maximize a contrast?
2. Does the whole-domain line really represent all Eurasia, or a smaller rectangle?
3. Is suitable area changing because of climate, ice retreat, coastlines or a
   threshold? Which plots help separate these possibilities?
4. Do climate changes coincide with suitability changes? Why is coincidence not
   sufficient to attribute extinction?
5. What observations could independently test a predicted refugium or recovery?

## Before writing results

Show your supervisor the fossil map, exclusion audit, fold map, held-out scores,
predictor diagnostics, suitability time series with uncertainty and selected
maps. Report limitations alongside the finding. A defensible result can be
"little evidence of climatic habitat contraction"; a model need not reproduce an
extinction to be informative.
