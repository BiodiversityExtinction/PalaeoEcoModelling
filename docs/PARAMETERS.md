# Parameter guide

Every scientific decision file contains an R object called `decision`, with
`reviewed` and `rationale`. Set `reviewed=TRUE` only after inspecting the previous
stage. `rationale` is your plain-language explanation, not an automatic approval.
R strings need quotes; decimal points are dots; ages are positive years before
1950. `ka` means thousands of years. `10L` is R's integer notation.

## Project file: paths and housekeeping

| Field | Meaning and what to set |
|---|---|
| `name` | Short analysis name printed on figures. Use species/run-specific names. |
| `fossil_file` | Path to your standardized CSV. Relative paths start in the directory where you launch `Rscript`. |
| `output_dir` | Where generated plots, tables and RDS files go. One directory per analysis. |
| `decisions_dir` | Where progressively created, reviewed R decision files go. Do not share this between different studies. |
| `climate_dirs` | Named directories `tas`, `pr`, `sftlf`, `sftgif`. They mean temperature, total precipitation, land fraction, ice fraction. File patterns are fixed by this archive adapter. |
| `fraction_divisor` | Divide raw land/ice values by this number to get 0-1 fractions. Use 1 for our Armstrong files, even though units metadata says percent. For a genuinely 0-100 archive use 100 only after verification. |
| `seed` | Reproducible random seed for each stage. Same inputs/settings/environment give the same draws. Change only for a documented sensitivity run. |
| `synthetic` | TRUE for invented teaching data, FALSE for real fossils. Controls conspicuous plot labelling, not the underlying model. |

All relative project paths use the launch directory. This lets many students run
one shared installation while keeping their inputs, decisions and outputs in
separate working directories. Absolute paths, such as the shared Armstrong
archive paths, are used unchanged.

## 02: calibration

| Parameter | Meaning |
|---|---|
| `curve` | Currently only `"intcal20"` is supported: Northern Hemisphere terrestrial carbon. Marine reservoirs, Southern Hemisphere specimens or other chronologies require a reviewed extension, not simply changing this string. |
| `age_points` | Number of evenly spaced calendar ages including endpoints of each interval; 10 is the proposed simple choice. These represent one fossil, not ten independent fossils. |
| `boundary_policy` | `"exclude"` removes dates with >=0.5% of calibrated probability in the oldest 100 years of the supported 55 ka range. `"keep_flagged"` keeps them, explicitly flagged; it does not repair truncation. Prefer excluding unresolved boundary cases. |

Raw radiocarbon dates get a central equal-tailed 95.4% interval (2.3-97.7%
quantiles). This is not an OxCal highest-density interval, and a multimodal
distribution can have gaps inside it. Supplied calibrated ranges are not
recalibrated. Full raw-date calibration densities are saved; evenly spaced age
alternatives intentionally do not use those probability weights.

## 03: climate extraction and domain

| Parameter | Meaning |
|---|---|
| `extent` | Named `xmin,xmax,ymin,ymax` in longitude/latitude degrees. Rectangular study AND background domain; all included fossils must be inside. Northern Hemisphere only; no antimeridian-crossing rectangle. Broad regions are not known species ranges. |
| `projection_ages_ka` | Explicit ages at which to project and summarize. `seq(59,1,by=-1)` means 1 kyr spacing; not interpolation from a coarser map. Choose files that exist and times relevant to your question. More slices cost time/memory. |
| `average_years` | Number of consecutive years used to form 12 monthly climatological means before calculating predictors; 10 is the example. Near a file edge the window is shifted to stay inside that file, not extended across archives. |
| `extraction` | `"focal_cell"` uses the fossil's nearest cell; `"mean_3x3"` averages monthly climates across its available 3x3 neighbourhood before deriving predictors. The same operation is used for backgrounds and projections. Not a GPS-error model or an assumed home range. |
| `land_threshold` | Cell must have land fraction >= this threshold, usually 0.5, to count as land. It is a binary decision, not fractional coastal-area weighting. |
| `ice_threshold` | Land with ice fraction >= this threshold, usually 0.5, is unsuitable. Other cells are treated as ice-free for extraction. Fractions below the threshold are not subtracted proportionally. |

The archive covers the whole Northern Hemisphere, but the model domain should
match the focal taxon and question. A Eurasian cave-hyena or giant-deer study can
use a Eurasian rectangle; a dire-wolf, mastodon or Columbian-mammoth study should
use North America; a whole-species woolly-mammoth analysis may require a Holarctic
domain. This is an accessible/background region, not a known range polygon. In
this workflow it is also the projection region, so changing it changes both the
random background and mapped results. Decide before looking at predictions.

At the original 0.5-degree resolution a 3x3 neighbourhood spans about 1.5 degrees
each way, approximately `27,800 * cos(latitude)` square km. It is much larger
than a precise fossil locality and its size varies with latitude. A focal cell
is approximately `3,091 * cos(latitude)` square km. These are approximations,
not measured habitat areas. Coordinate uncertainty is retained but not propagated
by this version; large/unknown uncertainties need review and sensitivity analysis.

Fossil age rows that fall on ocean, ice or missing climate are excluded and
audited; a partially retained fossil's mean uses only its surviving alternatives.
Check whether exclusions systematically remove one region or time period.

## 04 and 05: candidate predictors and model design

Eight candidates are calculated from monthly climatology:

| Name | Definition | Units |
|---|---|---|
| `temp_mean` | Mean of 12 monthly temperatures | degrees C |
| `temp_coldest` | Minimum monthly temperature | degrees C |
| `temp_warmest` | Maximum monthly temperature | degrees C |
| `temp_seasonality` | Population SD of 12 monthly temperatures, **not multiplied by 100** | degrees C |
| `precip_mean` | Mean of 12 monthly mean daily precipitation rates | mm/day |
| `precip_summer` | Mean of June, July and August rates | mm/day |
| `precip_winter` | Mean of December, January and February rates | mm/day |
| `precip_seasonality` | Population SD of 12 monthly precipitation rates, **not a coefficient of variation** | mm/day |

The package derives these from temperature and total precipitation, not from
separate snow or radiation predictors. Other archive variables exist but are not
silently included. Adding them requires extending extraction/validation and
providing an ecological reason. The mean rates weight months equally; they are
not calendar-day-weighted annual totals.

| Parameter | Meaning |
|---|---|
| `predictors` | Character vector of at least two names above. Choose a small biologically interpretable subset after viewing correlations; avoid strong redundancy, e.g. absolute Spearman rho >0.7, unless justified. No automatic significance-based selection. |
| `background_n` | Requested total random background cells across selected times, not per time. Times receive approximately equal allocation; cells within a time are sampled proportional to cos(latitude), without replacement. The actual total may be smaller if the grid is small. |
| `block_km` | Approximate square spatial block width in km using longitude scaled at the mean fossil latitude. 750 is a starting value, not an optimized universal separation distance. Inspect the map. |
| `folds` | Number of held-out spatial groups, usually four if enough sites exist. Whole blocks stay together and all ages/specimens from a site stay together. Blocks are balanced approximately by site count; distant blocks can share a fold. This is not a buffered spatial CV or an East/West split. |

Background uses projection times within the retained fossil age range. If no
projection time falls inside, the nearest to the age-range midpoint is used.
It does not precisely match the sampling intensity of fossils through time and
does not correct collection/preservation bias. This simple random design must be
stated as a limitation, not described as target-group background.

Exact duplicate predictor vectors are removed **within each fossil**, not across
different fossils. `unique_age_climates.csv` records their normalized weights.
Model ensembles draw one alternative per fossil per fit; weights are not secretly
fed to MaxEnt as though it supported weighted independent fossil counts.

## 06: tune MaxEnt

| Parameter | Meaning |
|---|---|
| `feature_classes` | Candidate sets: `l` = linear, `lq` = linear+quadratic, `lqp` adds products/interactions, `lqh` adds hinges, `lqph` adds both. More flexibility is not automatically better with sparse fossils. |
| `regmult` | Positive regularization multipliers; higher generally penalizes complexity more. The candidate grid tests every feature-set/multiplier combination. |
| `omission_quantile` | Lower quantile of training site scores used as a presence threshold. 0.1 is a 10th-percentile rule, allowing about 10% training omission (ties can change it). It is not a fixed 0.1 suitability score. |

Reported metrics: presence-background AUC, omission, background-based TSS and a
simple **binned Boyce-style Spearman score** using ten background-quantile bins.
The latter is not a continuous Boyce implementation. All are conditional on the
background and site sample. AUC can look impressive with an overly broad domain.
Scores used for tuning are not an independent estimate of final model performance.

## 07: final baseline

`features` and `regmult` select one tested candidate from step 06. Record why,
considering fold-to-fold variability and simplicity rather than just the highest
mean AUC. Both model types use one mean climate vector per fossil for the baseline.
The Gaussian uses a regularized covariance matrix with a small diagonal ridge
for numerical stability. It is not fitted using confirmed absence records.

Predictive importance is the drop in held-out AUC after shuffling one predictor
jointly across the held-out presence/background rows, repeated five times per
fold. Negative values can occur. Correlated predictors can obscure importance.
Response curves vary one predictor while holding others at fossil medians;
some combinations may never occur in real climates.

Each model has its **own** training-site quantile threshold. MaxEnt cloglog and
Gaussian relative-density scores are not directly comparable calibrated
occurrence probabilities. Compare spatial/temporal patterns and thresholded area
with this qualification. Maps show continuous scores, not thresholded occupancy.

## 08: age and sampling sensitivity

| Parameter | Meaning |
|---|---|
| `replicates` | Number of full fits for each model. 5 in the demo only exercises the workflow; 30 is a starting research setting, not proof of convergence. Increase and check that conclusions/intervals stabilize. |
| `bootstrap_sites` | TRUE resamples whole localities with replacement after choosing an age per fossil. All fossils from a selected locality travel together. FALSE isolates age/background sensitivity more closely, but backgrounds are still redrawn. |

One unique age climate is drawn per fossil per replicate. Backgrounds are redrawn
with the same random design, and the threshold is recalculated in each fit.
The 2.5-97.5% envelope describes variability from these choices, **not a complete
confidence/credible interval**. It omits climate-model uncertainty, unsampled
preservation processes, physiological uncertainty and taxonomic error. Bootstrap
replicates with insufficient climate diversity can fail; do not hide such failures.

## 09: reporting, not refitting

| Parameter | Meaning |
|---|---|
| `mode` | `"whole"`, `"longitude_bands"`, `"latitude_bands"` or `"polygons"`. All summarize the same fitted model. |
| `breaks` | Increasing degree boundaries for bands, e.g. `c(-15,50,132)` for two longitude zones. A boundary belongs to the eastern/northern band; final upper endpoint is included. |
| `region_names` | One name per interval, e.g. `c("West","East")`. Use meaningful study-specific names. |
| `polygon_file` | For polygon mode only: GeoPackage/GeoJSON/shapefile readable by `sf`, with an explicit CRS. Needed sidecar files must accompany a shapefile. Broad polygons are geographic reporting zones, not estimated ranges. |
| `name_column` | Polygon attribute containing region names. Cells are assigned by their centres; overlaps/shared-boundary ambiguities stop the run rather than count twice. |
| `map_ages` | Desired maps in ka BP; nearest existing projection slices are used and written to `map_times.csv`. To obtain exact new times, change stage 03 and rerun downstream. |

Cells outside all regions are labelled `Unassigned`, never silently removed from
the whole-domain summary. Suitability percentages use latitude-weighted **land
including ice** as denominator. Ice is always unsuitable. The land denominator
can change with coastlines. Regional mean climates use ice-free land only; their
time trends can therefore include changing geographic coverage as ice retreats.
Ice cover is also plotted separately. Country outlines are modern orientation
guides, not palaeocoastlines. This version does not use partial-cell polygon area.

## 10: analysis record

No new parameter. The report collates the recorded settings and limitations; it
is not a submission-ready Methods section until you have checked the underlying
data, inspected diagnostics and described the study-specific decisions.
