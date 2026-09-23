# Run from the repository root: Rscript steps/00_setup.R
dir.create(".R-library", showWarnings = FALSE)
.libPaths(c(normalizePath(".R-library"), .libPaths()))
packages <- c("ggplot2", "maps", "patchwork", "rcarbon", "ncdf4", "maxnet")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org", lib = ".R-library")
stopifnot(all(vapply(packages, requireNamespace, logical(1), quietly = TRUE)))
cat("Core packages available. sf is optional for custom GeoJSON polygons.\n")
print(sapply(packages, function(p) as.character(packageVersion(p))))
