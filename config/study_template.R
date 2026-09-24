# Copy into your working directory, then edit the paths and name for YOUR species.
# Relative paths are interpreted from the directory where you launch Rscript.
project <- list(
  name = "my_species",
  fossil_file = "data/input/fossils.csv",
  output_dir = "outputs/my_species",
  decisions_dir = "decisions/my_species",
  climate_dirs = c(
    tas = "/net/well/pool/projects2/Biodiversity_Extinction/Armstrong_palaeoclimate/armstrong_full/temp_nc",
    pr = "/net/well/pool/projects2/Biodiversity_Extinction/Armstrong_palaeoclimate/armstrong_full/precip_nc",
    sftlf = "/net/well/pool/projects2/Biodiversity_Extinction/Armstrong_palaeoclimate/armstrong_starter/landmask_nc",
    sftgif = "/net/well/pool/projects2/Biodiversity_Extinction/Armstrong_palaeoclimate/armstrong_full/icefrac_nc"
  ),
  fraction_divisor = 1,
  seed = 1241,
  synthetic = FALSE
)
