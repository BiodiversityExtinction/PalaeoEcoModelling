# This bootstrap makes the setup command safe to run from any directory.
script_file <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[[1]]))
source(file.path(dirname(script_file), "..", "R", "bootstrap.R"))
library_dir <- file.path(getOption("palaeo.repo_root"), ".R-library")
dir.create(library_dir, showWarnings = FALSE)
.libPaths(c(library_dir, .libPaths()))
packages <- c("ggplot2", "maps", "patchwork", "rcarbon", "ncdf4", "maxnet")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org", lib = library_dir)
stopifnot(all(vapply(packages, requireNamespace, logical(1), quietly = TRUE)))
cat("Core packages available. sf is optional for custom GeoJSON polygons.\n")
print(sapply(packages, function(p) as.character(packageVersion(p))))
