repo_root <- getOption("palaeo.repo_root")
if (is.null(repo_root)) stop("Repository bootstrap was not loaded.")
repo_file <- function(...) file.path(repo_root, ...)
local_library <- repo_file(".R-library")
if (dir.exists(local_library)) .libPaths(c(local_library, .libPaths()))
suppressPackageStartupMessages({library(ggplot2); library(patchwork)})
options(stringsAsFactors = FALSE)

load_project <- function() {
  config_file <- getOption("palaeo.config_file")
  if (is.null(config_file)) stop("Supply a project file, e.g. config/demo.R")
  e <- new.env(parent = baseenv()); sys.source(config_file, e)
  p <- e$project
  required <- c("name", "fossil_file", "output_dir", "decisions_dir", "climate_dirs", "seed", "synthetic", "fraction_divisor")
  if (!all(required %in% names(p))) stop("Missing project fields: ", paste(setdiff(required, names(p)), collapse=", "))
  p$config_file <- config_file; set.seed(p$seed)
  dir.create(p$output_dir, recursive=TRUE, showWarnings=FALSE)
  dir.create(p$decisions_dir, recursive=TRUE, showWarnings=FALSE)
  p
}
out <- function(p, step, file=NULL) {
  d <- file.path(p$output_dir, step); dir.create(d, recursive=TRUE, showWarnings=FALSE)
  if (is.null(file)) d else file.path(d, file)
}
table_out <- function(p, step, name, x) write.csv(x, out(p, step, paste0(name,".csv")), row.names=FALSE, na="")
plot_out <- function(p, step, name, g, w=10, h=6) {
  g <- g + plot_annotation(caption=if (p$synthetic) "SYNTHETIC TEACHING DATA: no biological interpretation" else p$name)
  for (ext in c("pdf", "png")) ggsave(out(p, step, paste0(name,".",ext)),g,width=w,height=h,dpi=180,bg="white")
}
theme_set(theme_bw(base_size=11, base_family="serif") + theme(legend.position="top",panel.grid.minor=element_blank()))
complete_step <- function(p, step, inputs, settings, notes) {
  script <- getOption("palaeo.script_file", character())
  code <- c(script,list.files(repo_file("R"),pattern="[.]R$",full.names=TRUE),repo_file("templates","fossils.csv"))
  inputs <- unique(c(p$config_file,code,inputs))
  inputs <- inputs[file.exists(inputs)]
  saveRDS(list(input_md5=tools::md5sum(inputs),settings=settings,date=Sys.time(),session=sessionInfo()),out(p,step,"provenance.rds"))
  writeLines(c(notes,"",capture.output(sessionInfo())),out(p,step,"summary.txt"))
  message("Completed ",step,". Inspect ",out(p,step)," before continuing.")
}
require_step <- function(p, step) {
  f <- out(p,step,"provenance.rds")
  if (!file.exists(f)) stop("Run and inspect step ", step, " first.")
  check <- function(path) {
    old <- readRDS(path)$input_md5
    now <- tools::md5sum(names(old))
    if (anyNA(now) || !identical(unname(old),unname(now))) stop("Inputs changed since ",dirname(path),". Rerun it and dependent steps.")
    for (parent in names(old)[basename(names(old))=="provenance.rds"]) check(parent)
  }
  check(f)
  f
}
decision <- function(p, name) {
  f <- file.path(p$decisions_dir,paste0(name,".R"))
  if (!file.exists(f)) {
    template <- repo_file(if (p$synthetic) file.path("examples","demo_decisions") else "templates",paste0(name,".R"))
    file.copy(template,f)
    stop("Decision template created: ",f,". Read its comments, edit it, explain your choice, then rerun this step.")
  }
  e <- new.env(parent=baseenv()); sys.source(f,e); d <- e$decision
  if (!isTRUE(d$reviewed) || !is.character(d$rationale) || !nzchar(trimws(d$rationale)))
    stop("Review ",f,"; add rationale and set reviewed=TRUE.")
  attr(d,"file") <- normalizePath(f); d
}
decision_file <- function(d) attr(d,"file")
read_output <- function(p,step,name) readRDS(out(p,step,paste0(name,".rds")))
write_output <- function(p,step,name,x) saveRDS(x,out(p,step,paste0(name,".rds")))
population_sd <- function(x) sqrt(mean((x-mean(x))^2))
predictor_names <- c("temp_mean", "temp_coldest", "temp_warmest", "temp_seasonality", "precip_mean", "precip_summer", "precip_winter", "precip_seasonality")
predictor_labels <- c(temp_mean="Annual temperature (C)",temp_coldest="Coldest month (C)",temp_warmest="Warmest month (C)",temp_seasonality="Temperature seasonality (C SD)",precip_mean="Annual mean precipitation (mm/day)",precip_summer="JJA precipitation (mm/day)",precip_winter="DJF precipitation (mm/day)",precip_seasonality="Precipitation seasonality (mm/day SD)")
climate_metrics <- function(t,p) c(temp_mean=mean(t),temp_coldest=min(t),temp_warmest=max(t),temp_seasonality=population_sd(t),precip_mean=mean(p),precip_summer=mean(p[6:8]),precip_winter=mean(p[c(12,1,2)]),precip_seasonality=population_sd(p))
country_lines <- function() {
  world <- map_data("world")
  # Explicit mapped groups survive faceting; split any antimeridian jumps.
  world$line_group <- cumsum(c(TRUE,diff(world$group)!=0 | abs(diff(world$long))>180))
  geom_path(data=world,aes(long,lat,group=line_group),inherit.aes=FALSE,colour="grey45",linewidth=.2)
}
point_map <- function(x, colour="taxon", title="Fossil localities") {
  ggplot() + country_lines() +
    geom_point(data=x,aes(x=longitude,y=latitude,colour=.data[[colour]]),size=2) +
    coord_quickmap(xlim=range(x$longitude)+c(-8,8),ylim=pmax(-85,pmin(85,range(x$latitude)+c(-5,5)))) + labs(title=title)
}
