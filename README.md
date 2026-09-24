# Fossil climate suitability, one decision at a time

A teaching workflow in R for dated Northern Hemisphere fossil occurrences and
the Armstrong et al. palaeoclimate archive. MaxEnt is the main statistical model;
a multivariate Gaussian envelope is a comparison, not a second probability scale.

**Start with the synthetic tutorial below. Do not start by running every script.**
At each stage: run, inspect the outputs, write down your reasoning, then continue.
This is a research starting point, not automatic evidence for an extinction cause.

## What question does this answer?

Given the climates associated with a species' fossils, where and when was similar
climate available within our study area? We map climatic suitability, mask ice and
ocean, and summarize suitable land through time. We do **not** estimate abundance,
prove occupation, model dispersal/connectivity, or explain extinction by ourselves.

There are three different geographic choices:

1. **Study domain:** the rectangle where we extract climate and project the model.
   Choose it before fitting. It must be justified for the species, not selected
   because it gives an attractive result.
2. **Background domain:** in this basic workflow, random ice-free land cells from
   that same rectangle, at projection times overlapping fossil ages. These are
   available environments, **not confirmed absences**.
3. **Reporting regions:** optional bands or polygons chosen after fitting to
   summarize the same predictions. A West/East split does not fit separate models.

If the study domain covers all Eurasia, the whole-domain line is Eurasia-wide.
The example rectangle is **not all Eurasia**. Change it for your study and label
plots accurately. A species' exact historical distribution need not be known,
but an implausibly broad background can distort the contrast used by MaxEnt.

The Armstrong archive covers the entire Northern Hemisphere (`-180` to `179.5`
degrees longitude and `0` to `89.5` degrees north), and MEGA14C contains both
Eurasian and North American fossils. The study domain is therefore species- and
question-specific, not always Eurasia. For example:

- **Cave hyena or giant deer:** use a Eurasian domain that contains all accepted
  fossils and the broader area plausibly accessible to the populations studied.
- **Dire wolf, American mastodon or Columbian mammoth:** use a North American
  domain rather than including inaccessible Eurasian environments as background.
- **Woolly mammoth or another Holarctic species:** use a Holarctic domain if the
  question concerns the whole species, or justify separate continental analyses
  if the question concerns regional populations.

These domains are not reconstructed species-range polygons. They define the area
whose available climates are contrasted with fossil climates. In this workflow,
the random-background and projection domains are the same rectangle. Expanding it
to another continent can change MaxEnt fit and validation even when the fossil
records do not change. Choose and document it before examining predictions.

## Requirements and setup

Use R >= 4.3. Run terminal commands from this repository's root, not from `steps/`.
The scripts use `maxnet` (MaxEnt in R), so Java and a separate MaxEnt jar are not
needed. `sf` is optional, only for custom polygon files.

On this server the repository is currently at:

```bash
cd /home/people/micwe/Biodiversity_Extinction/PalaeoEcoModelling
Rscript steps/00_setup.R
```

The setup script installs missing R packages into `.R-library/`. It needs internet
access and may require system libraries/compiler support. On a cluster, install
packages once on an allowed login/setup node, not in every compute job. Do not
upload `.R-library/` or climate NetCDFs to GitHub. Versions used by each run are
written to its stage summaries. The current repo is local, not published online.

## Work through the tutorial one step at a time

The demo uses **invented fossils and climate** in the same file layout as the real
analysis. It is deliberately small and covers only 0-2.5 ka. It teaches the
workflow, but its apparent ecological patterns have no biological meaning.

Do not paste all the commands into the terminal together. Run one step, inspect
its outputs, record your reasoning, and only then run the next step.

The commands below are written as if you are in the repository root. You may
also invoke a step from a nested directory with paths such as
`Rscript ../steps/01_fossils.R ../config/demo.R`; the workflow locates the
repository automatically. Paths declared inside a configuration file, including
output paths, are still interpreted relative to the repository root.

In the tutorial, every filename listed under **Inspect** is inside that step's
`outputs/demo/` folder. For a real project, replace `demo` with the output directory
you set in `config/local.R`.

### Step 0a: check the R environment

**Why:** the analysis depends on several R packages. This checks whether they are
available and installs missing packages into this project's `.R-library/`.

**Run:**

```bash
Rscript steps/00_setup.R
```

**What happens:** no fossils or climate are analysed. R prints the package
versions that will be used. If installation fails, resolve that before proceeding.

**Do not continue until:** the final line says the core packages are available.

### Step 0b: create the synthetic input data

**Why:** this gives you harmless practice data before you work with real fossils.

**Run:**

```bash
Rscript examples/make_demo.R
```

**What happens:** R creates a standardized fossil CSV and small synthetic NetCDF
climate files under `examples/generated/`. The files follow the structure expected
by the real workflow. Existing synthetic files are regenerated deterministically.

**Inspect:** open `examples/generated/fossils.csv`. Find the raw radiocarbon age,
its laboratory error, coordinates, `include`, source and exclusion columns. Notice
that one row is already excluded and one uses a supplied calibrated interval.

**Do not continue until:** you can distinguish `age_14c_bp` from a calendar-age
range (`cal_young_bp` to `cal_old_bp`).

### Step 1: validate and map the fossil records

**Question:** are the records suitable inputs before any ecological model is run?

**Run:**

```bash
Rscript steps/01_fossils.R config/demo.R
```

**What happens:** the script checks required columns, coordinates, date fields,
specimen IDs, locality IDs and exclusion reasons. It rejects duplicated included
specimens and inconsistent coordinates within a locality. It does not decide
taxonomy or dating quality for you. It then maps the accepted records.

**Inspect:**

- `outputs/demo/01_fossils/audit.csv` contains every input row and any validation issue.
- `outputs/demo/01_fossils/accepted.csv` contains the records entering calibration.
- `outputs/demo/01_fossils/occurrences.pdf` shows their geographic distribution.

**Think about:** does the map match the expected geography? Are multiple database
rows actually the same specimen? Are all included dates directly associated with
the fossil and supported by acceptable pretreatment?

**Do not continue until:** you understand every exclusion and have checked the
source data, not just whether the script completed.

### Step 2: calibrate dates and represent age uncertainty

**Question:** when could each fossil actually have lived in calendar years?

**Run once:**

```bash
Rscript steps/02_calibrate.R config/demo.R
```

**What happens on the first run:** the script creates
`decisions/demo/02_calibration.R` and intentionally stops. This is expected, not
an error. Open that file and decide which calibration settings to use. Read the
comments and [parameter guide](docs/PARAMETERS.md), then edit, for example:

```r
reviewed = TRUE,
rationale = "I chose IntCal20 for Northern Hemisphere terrestrial samples; ten ages explore each central 95.4% interval."
```

Keep those entries inside the existing `decision <- list(...)` and run the same
command again.

**What happens after approval:** raw radiocarbon ages are calibrated with IntCal20.
The central 95.4% calendar interval and median are recorded. Ten evenly spaced age
alternatives are generated across each retained interval. These alternatives
belong to one fossil; they are not ten independent fossils. Supplied calendar
ranges are retained rather than calibrated again.

**Inspect:**

- `calibration_audit.csv` shows calibrated limits and boundary warnings.
- `age_intervals.pdf` compares uncertainty among fossils.
- `example_densities.pdf` shows why calibrated ages may be multimodal.
- `ages.csv` contains the ten age alternatives used in climate extraction.

**Do not continue until:** boundary-truncated dates and unusual intervals have
been checked, and you can explain why an uncertain fossil remains one observation.

### Step 3: extract climate and construct the projection grid

**Question:** what climates correspond to each possible fossil age, and what
climates were available across the study domain through time?

**Run once:**

```bash
Rscript steps/03_climate.R config/demo.R
```

The first run creates `decisions/demo/03_climate.R` and stops. In that file you
must define the geographic study domain, projection time points, temporal averaging
window, focal-cell versus 3x3 extraction, and land/ice thresholds. Write a
rationale, set `reviewed=TRUE`, and rerun the command.

**What happens after approval:** for every fossil age alternative, the script
reads monthly temperature and total precipitation, averages the chosen number of
years, and calculates eight annual/seasonal climate summaries. It applies the same
climate calculation to every projection cell and time. Ocean and sufficiently
ice-covered cells cannot provide occurrence climate; ice is unavailable habitat.
With 3x3 extraction, available neighbours are averaged, but an ocean/ice central
cell is not moved to a nearby cell.

**Inspect:**

- `extraction_status.pdf` maps land, ice, ocean and failed fossil extractions.
- `failed_extractions.csv` identifies age alternatives that could not be used.
- `counts.pdf` shows how many alternatives survived for each fossil.
- `fossil_means.csv` gives one mean climate vector per retained fossil.
- `climate_catalogue.csv` records which external NetCDF files were found.

**Do not continue until:** every failed extraction is understood and exclusions
do not silently remove an important time period or geographic group.

### Step 4: explore candidate climate variables

**Question:** which climate variables contain distinct information and make
ecological sense for this species?

**Run:**

```bash
Rscript steps/04_variables.R config/demo.R
```

**What happens:** no model is fitted and no variable is automatically selected.
The script calculates correlations among the eight fossil-climate summaries and
plots each variable against fossil age. This helps identify redundant predictors
and geographic/sampling patterns that could look like temporal trends.

**Inspect:**

- `correlations.pdf` and `correlations.csv` show pairwise Spearman correlations.
- `fossil_climate_through_time.pdf` shows the climate attached to individual fossils.

**Think about:** a correlation above about |0.7| warns that predictors may be
redundant. Statistical distinctness is not enough: each selected variable needs a
biological rationale. A trend at sampled fossils can also arise because collecting
locations change through time.

**Do not continue until:** you have proposed a small predictor set and can justify
each variable without referring to the eventual model result.

### Step 5: choose predictors, random background and spatial folds

**Question:** against which available environments will occurrences be contrasted,
and how will spatially close localities be kept out of opposite validation sets?

**Run once:**

```bash
Rscript steps/05_background_folds.R config/demo.R
```

The first run creates `decisions/demo/05_design.R` and stops. Select the predictors
you justified in step 4, the total random-background sample size, approximate block
width and number of folds. Add your rationale, set `reviewed=TRUE`, and rerun.

**What happens after approval:** random background cells are sampled from ice-free
land in the study domain at projection times supported by the fossils. They are
available environments, not known absences. Fossil sites and background cells are
assigned to spatial blocks and folds. All records from one locality stay in one
fold. Exact duplicate age-climate vectors are removed within each fossil; remaining
age alternatives have weights summing to one per fossil.

**Inspect:**

- `background_and_folds.pdf` shows background points, fossil sites and fold colours.
- `folds.csv` gives each fossil's block and fold.
- `background.csv` records the sampled environmental background.
- `unique_age_climates.csv` records deduplicated age alternatives and weights.

**Do not continue until:** every fold contains enough independent localities and
the background domain represents the geographic question you intend to ask.

### Step 6: tune MaxEnt complexity using held-out spatial folds

**Question:** how flexible does the MaxEnt model need to be without merely fitting
the sampled localities too closely?

**Run once:**

```bash
Rscript steps/06_tune.R config/demo.R
```

The first run creates `decisions/demo/06_tuning.R` and stops. Specify candidate
feature classes, regularization multipliers and the omission quantile. Approve the
decision and rerun.

**What happens after approval:** using one mean climate vector per fossil, each
candidate MaxEnt model is repeatedly fitted to all spatial folds except one and
evaluated on the held-out fold. It reports AUC, omission, background-based TSS and
a binned Boyce-style score. These values compare settings under this background
design; they are not an independent final performance test.

**Inspect:**

- `tuning.pdf` shows held-out AUC for every fold and candidate.
- `held_out_metrics.csv` contains all metrics, including poorly performing folds.

**Think about:** prefer a simpler model when added complexity gives little or
inconsistent improvement. Do not select a setting from mean AUC alone.

**Do not continue until:** you have selected one candidate that was actually tested
and can explain the trade-off between fit, omission and complexity.

### Step 7: fit the baseline MaxEnt and Gaussian models

**Question:** using one mean climate per fossil, what spatial and temporal pattern
does each modelling approach infer?

**Run once:**

```bash
Rscript steps/07_models.R config/demo.R
```

The first run creates `decisions/demo/07_models.R` and stops. Enter the MaxEnt
feature class and regularization multiplier selected from step 6, add your
rationale, approve it, and rerun.

**What happens after approval:** the final baseline MaxEnt model and a multivariate
Gaussian climate envelope are fitted to the same fossil means and background.
Each gets its own training-presence threshold, so their raw scores are not directly
comparable probabilities. Both are projected to every time slice; ice receives
zero suitability. Predictor permutation importance, one-variable response curves,
held-out metrics, thresholded suitable area and simple novel-climate warnings are
also calculated.

**Inspect:**

- `suitability_through_time.pdf` compares thresholded suitable area.
- `variable_contributions.pdf` shows held-out AUC loss after shuffling a variable.
- `response_curves.pdf` shows model responses with other variables held constant.
- `validation.csv` reports fold-level skill for both models.
- `novel_climate_cells.csv` flags projection cells beyond univariate training ranges.

**Do not continue until:** response shapes are ecologically plausible, poor folds
are acknowledged, and disagreement between MaxEnt and Gaussian is understood as
model sensitivity rather than a choice of the prettier result.

### Step 8: propagate dating and locality-sampling sensitivity

**Question:** would the suitability history change if fossils took different ages
within their uncertainty intervals or a somewhat different site sample were used?

**Run once:**

```bash
Rscript steps/08_uncertainty.R config/demo.R
```

The first run creates `decisions/demo/08_uncertainty.R` and stops. Choose the
number of ensemble fits and whether to bootstrap whole localities. Approve and
rerun. The demo's five replicates only test the code; they are not sufficient for
a research uncertainty analysis.

**What happens after approval:** each replicate selects one unique age-climate
alternative per fossil, optionally resamples whole sites, redraws random background,
refits both models and recalculates thresholds and suitable area. It does not put
all ten ages into one model as ten independent fossil occurrences.

**Inspect:**

- `suitability_uncertainty.pdf` shows median trajectories and 95% sensitivity envelopes.
- `area_intervals.csv` contains the plotted summaries.
- `area_replicates.csv` retains every individual trajectory.
- `sampled_fossils.csv` records the selected age and site draw in every replicate.

**Do not continue until:** increasing the replicate count gives reasonably stable
conclusions and you can state which major uncertainties are still omitted.

### Step 9: define reporting regions and make final plots

**Question:** how do suitability, climate and ice histories differ among meaningful
geographic reporting regions?

**Run once:**

```bash
Rscript steps/09_regions_plots.R config/demo.R
```

The first run creates `decisions/demo/09_regions.R` and stops. Choose whole-domain
reporting, longitude/latitude bands, or custom polygons, and select map times.
Approve the decision and rerun.

**What happens after approval:** no model is refitted. Existing cell-level
predictions are summarized for the whole model domain and your reporting regions.
The script also calculates area-weighted climate histories across ice-free land,
plots ice coverage separately, and makes maps with ice overlaid. Regional
boundaries therefore affect presentation and interpretation, not model training.

**Inspect:**

- `region_map.pdf` verifies exactly how each region was defined.
- `regional_suitability.pdf` compares regional suitable-land percentages.
- `regional_climate.pdf` shows all climate variables across each region and the whole domain.
- `ice_coverage_supplement.pdf` separates changing ice cover from climate suitability.
- `maps_maxent.pdf` and `maps_gaussian.pdf` show selected spatial predictions.
- `map_times.csv` reports the actual projection age used for each requested map.

**Do not continue until:** labels accurately describe the domain, boundaries were
chosen independently of attractive results, and maps do not show obvious artefacts.

### Step 10: export and read the analysis record

**Question:** can another person reconstruct what you chose and understand the
limits of the result?

**Run:**

```bash
Rscript steps/10_report.R config/demo.R
```

**What happens:** the script checks that all upstream outputs still match their
input files and source code. It compiles every recorded decision, software session
and key limitation into `outputs/demo/10_report/analysis_record.md`. It does not
automatically write a manuscript-ready Methods section.

**Do not finish until:** you have read the complete analysis record, answered the
[student workbook](docs/WORKBOOK.md), and can explain the workflow without simply
saying that MaxEnt produced the result.

Stages 01, 04 and 10 do not create decision files. All other analytical stages
pause on their first run. The terminal tells you the exact decision file and output
directory. Do not use `tests/run_demo.R` as the student workflow: it deliberately
approves synthetic choices to test the software without teaching the decisions.

## What to inspect at each stage

All plots are PDF **and** PNG; numerical results are CSV; intermediate data/models
are RDS. Each stage writes `summary.txt` and `provenance.rds`.

| Stage / output folder | Your decision | Open before proceeding | Checkpoint |
|---|---|---|---|
| `01_fossils` | Which fossils belong in the study? | `audit.csv`, `accepted.csv`, `occurrences.pdf` | Taxonomy, quality, coordinates and redated specimens checked against sources? |
| `02_calibration` | Calibration and age alternatives | `calibration_audit.csv`, `age_intervals.pdf`, `example_densities.pdf` if raw dates exist | Any dates at the calibration boundary? Raw and calendar ages distinguished? |
| `03_climate` | Domain, projection times, focal/3x3, ice rule | `extraction_status.pdf`, `counts.pdf`, `failed_extractions.csv`, `fossil_means.csv` | Any fossils lost to ocean/ice/missing data? Why? |
| `04_variables` | Inspect before choosing predictors | `correlations.pdf`, `fossil_climate_through_time.pdf`, `correlations.csv` | Which variables are redundant and which have an ecological rationale? |
| `05_design` | Predictor subset, random background, folds | `background_and_folds.pdf`, `folds.csv`, `unique_age_climates.csv` | Enough independent localities in every held-out fold? |
| `06_tuning` | Candidate MaxEnt complexity | `tuning.pdf`, `held_out_metrics.csv` | Similar skill with a simpler model? Any poor folds hidden by averages? |
| `07_models` | Select an evaluated MaxEnt setting | `variable_contributions.pdf`, `response_curves.pdf`, `suitability_through_time.pdf`, `novel_climate_cells.csv` | Plausible responses? Agreement/disagreement with Gaussian? Extrapolation? |
| `08_uncertainty` | Number of fits and site bootstrap | `suitability_uncertainty.pdf`, `area_intervals.csv`, `sampled_fossils.csv` | Stable conclusions across sampled ages/sites? Enough fits for stable intervals? |
| `09_regions` | Reporting bands/polygons and map times | `region_map.pdf`, `regional_suitability.pdf`, `regional_climate.pdf`, `maps_maxent.pdf`, `maps_gaussian.pdf`, `ice_coverage_supplement.pdf` | Are region names and maps accurate? Do climate changes coincide with suitability changes? |
| `10_report` | Review methods/limitations | `analysis_record.md` | Can you explain each choice to your supervisor? |

See [the student workbook](docs/WORKBOOK.md) for short questions to answer at these
checkpoints. Do not infer climate causation from coincident lines alone.

## Your own species

1. Compile `data/input/fossils.csv` using the exact headers in
   `templates/fossils.csv`. Read [the data dictionary](docs/DATA_FORMAT.md).
   Filter MEGA14C and/or literature yourself, retaining provenance and exclusion
   reasons. There is no assumption that every record labelled `Crocuta` is a
   cave hyena. Resolve taxonomy and duplicate specimens before fitting.
2. Copy `config/study_template.R` to `config/local.R`. Set the species name, fossil
   path, output/decision paths and climate archive locations. These are logistics,
   not preselected scientific decisions. Different studies need separate paths.
3. Run `Rscript steps/01_fossils.R config/local.R`. Inspect its map and audit.
4. Follow the same sequence as the tutorial, substituting `config/local.R` for
   `config/demo.R`. New study decisions will be requested as you reach each stage.
5. Keep your decision files and results with your thesis. They are ignored by git
   by default to avoid accidentally publishing data; deliberately include a
   reviewed, shareable run configuration when preparing a research release.

**Do not copy cave-hyena regions or predictors without justification.** The
templates are starting values, not validated defaults for every species.
The workflow stops on dates lacking uncertainty or missing climate files; it does
not silently invent uncertainty or move coastal points inland.

The corresponding terminal start is:

```bash
cp config/study_template.R config/local.R
# Open config/local.R in your editor, then:
Rscript steps/01_fossils.R config/local.R
```

## Climate and fossil data

MEGA14C is available through its
[Figshare dataset page](https://figshare.com/articles/dataset/MEGA14C_a_database_of_radiocarbon_dates_from_Holarctic_mammal_collagen_purified_with_high-quality_chemistry/27826200?file=60368048).
Consult its paper/data documentation, cite the version used and keep original
identifiers. A database quality category does not replace specimen-level review.
The full database is not redistributed here.

The Armstrong, Hopcroft and Valdes climate archive is available from the
[CEDA version 2 catalogue](https://catalogue.ceda.ac.uk/uuid/4ca242208e904efe830af45f1697f730/),
DOI `10.5285/4ca242208e904efe830af45f1697f730`. Read its access/licensing conditions
and cite the dataset and associated manuscript. This reader is specific to that
archive's monthly temperature/precipitation and annual masks, not arbitrary
NetCDFs. See [climate details](docs/CLIMATE.md).

Existing server locations are already in `config/study_template.R`:

```text
/net/well/pool/projects2/Biodiversity_Extinction/Armstrong_palaeoclimate/armstrong_full/temp_nc
/net/well/pool/projects2/Biodiversity_Extinction/Armstrong_palaeoclimate/armstrong_full/precip_nc
/net/well/pool/projects2/Biodiversity_Extinction/Armstrong_palaeoclimate/armstrong_full/icefrac_nc
/net/well/pool/projects2/Biodiversity_Extinction/Armstrong_palaeoclimate/armstrong_starter/landmask_nc
```

Read these shared data in place; do not copy hundreds of GB into your repo.
Outside this server, change the four directory paths. The landmask folder name
contains `starter`, but this workflow needs its **annual full-grid** files.
Decadal subset files are not interchangeable.

## Long jobs on Slurm

Create logs before submitting. Review each decision locally first; an unreviewed
decision makes the batch job stop rather than choose for you.

```bash
mkdir -p logs
sbatch slurm/run_step.sbatch steps/03_climate.R config/local.R
```

Wait for completion, read `logs/palaeo-step-JOBID.out`, inspect outputs, then submit
the next expensive stage if needed:

```bash
sbatch slurm/run_step.sbatch steps/06_tune.R config/local.R
sbatch slurm/run_step.sbatch steps/08_uncertainty.R config/local.R
```

These are **examples at different checkpoints**, not jobs to launch together.
Do not run two writers against the same output directory. The script requests
one CPU, 16 GB and 12 hours as editable examples; check your cluster partition,
account, R environment and memory needs. Finer time steps and larger domains
increase runtime and ensemble storage. No jobs are automatically submitted.

## Changing a decision, troubleshooting and reproducibility

- Changing a decision invalidates downstream results. Rerun that stage and all
  later stages. Input hashes detect changed scripts, shared R code, upstream
  configs/decisions/fossils;
  external climate archive contents are not hashed. Never overwrite the archive.
- For a focal-cell versus 3x3 comparison, create two project configs with different
  output and decision directories. Otherwise the second run replaces the first.
- If a fold has too few independent localities, inspect `folds.csv`; discuss a
  simpler predictor set, larger dataset or fewer folds rather than disabling
  validation to obtain a score. Eight fossils is a software guard, not a scientific
  minimum sample size.
- Missing packages: rerun `00_setup.R` in the same R environment used for jobs.
  `sf` may need GEOS/GDAL/PROJ. It is unnecessary for longitude/latitude bands.
- A stop saying a decision needs review is intentional, not a software failure.
- Uniform predictions or unstable Gaussian envelopes are warnings to investigate,
  not reasons to choose a prettier model. Raw scores from the two models should
  not be compared as though they share probability calibration.
- Synthetic outputs are labelled on every plot. Never mix them with study results.

For instructor/developer verification in a **fresh** working copy:

```bash
Rscript tests/run_demo.R
```

This runs all stages, refuses to replace existing demo decisions, and checks site
fold grouping, per-fossil age weights, ice masking, region endpoints and area
percentages. It is not validation of a species model or an exact reproduction of
the earlier cave-hyena analysis. The new workflow makes its assumptions explicit.

## Repository layout

```text
config/       Project paths/name/seed; no complete advance list of scientific choices
templates/    Standard fossil header and commented scientific decision templates
steps/        Numbered student-facing R scripts
R/            Shared implementation
examples/     Synthetic data generator and small teaching decision templates
docs/         Data, climate and parameter guides; student workbook
slurm/        Run one chosen stage on a cluster
tests/        Instructor/developer checks
decisions/    Created progressively for each study (local, ignored by git)
outputs/      Tables, plots, models and provenance (local, ignored by git)
```

No code licence has yet been granted. Until the owners add one, the public source
may be viewed but should not be assumed reusable. Before a stable release, review
the example/data redistribution terms, choose a licence and consider a release/DOI.
No licence for third-party data is implied by this repository.
