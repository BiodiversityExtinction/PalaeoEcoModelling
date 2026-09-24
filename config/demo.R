# Demo inputs are shared; relative outputs and decisions go to the launch directory.
repo_root <- getOption("palaeo.repo_root")
if (is.null(repo_root)) stop("Run this configuration through a numbered workflow step.")
project <- list(
  name = "synthetic_tutorial",
  fossil_file = file.path(repo_root,"examples","generated","fossils.csv"),
  output_dir = "outputs/demo",
  decisions_dir = "decisions/demo",
  climate_dirs = c(
    tas = file.path(repo_root,"examples","generated","climate","temp_nc"),
    pr = file.path(repo_root,"examples","generated","climate","precip_nc"),
    sftlf = file.path(repo_root,"examples","generated","climate","landmask_nc"),
    sftgif = file.path(repo_root,"examples","generated","climate","icefrac_nc")
  ),
  fraction_divisor = 1, # Actual Armstrong fractions are 0-1 despite '%' metadata.
  seed = 1241,
  synthetic = TRUE
)
