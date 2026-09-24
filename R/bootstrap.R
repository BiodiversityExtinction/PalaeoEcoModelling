# Resolve repository-relative resources independently of the shell working directory.
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (!length(script_arg)) stop("Could not determine the numbered step script location.")
script_file <- normalizePath(sub("^--file=", "", script_arg[[1]]), mustWork = TRUE)

args <- commandArgs(trailingOnly = TRUE)
if (length(args)) {
  options(palaeo.config_file = normalizePath(args[[1]], mustWork = TRUE))
}

repo_root <- normalizePath(file.path(dirname(script_file), ".."), mustWork = TRUE)
options(
  palaeo.repo_root = repo_root,
  palaeo.script_file = script_file,
  palaeo.launch_dir = normalizePath(getwd(), mustWork = TRUE)
)
