# Run commands from the repository root. All paths are relative to that root.
project <- list(
  name = "synthetic_tutorial",
  fossil_file = "examples/generated/fossils.csv",
  output_dir = "outputs/demo",
  decisions_dir = "decisions/demo",
  climate_dirs = c(
    tas = "examples/generated/climate/temp_nc",
    pr = "examples/generated/climate/precip_nc",
    sftlf = "examples/generated/climate/landmask_nc",
    sftgif = "examples/generated/climate/icefrac_nc"
  ),
  fraction_divisor = 1, # Actual Armstrong fractions are 0-1 despite '%' metadata.
  seed = 1241,
  synthetic = TRUE
)
