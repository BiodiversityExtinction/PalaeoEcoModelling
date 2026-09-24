# Developer/instructor test: explicitly approves SYNTHETIC decisions only.
# Students should follow README.md instead of using this shortcut.
script_file <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[[1]]))
source(file.path(dirname(script_file), "..", "R", "bootstrap.R"))
source(file.path(getOption("palaeo.repo_root"),"R","common.R"))
run<-function(script,config=NULL) {
  status<-system2(file.path(R.home("bin"),"Rscript"),c(script,config))
  if(status!=0)stop("Failed: ",script)
}
run(repo_file("examples","make_demo.R"))
dir.create("decisions/demo",recursive=TRUE,showWarnings=FALSE)
for(f in list.files(repo_file("examples","demo_decisions"),full.names=TRUE)) {
  target<-file.path("decisions/demo",basename(f))
  if(file.exists(target))stop("This test refuses to overwrite existing demo decisions: ",target,". Use a fresh checkout or run individual steps.")
  lines<-readLines(f); lines<-gsub('reviewed=FALSE','reviewed=TRUE',lines,fixed=TRUE)
  lines<-gsub('rationale=""','rationale="Approved synthetic smoke-test settings; no scientific inference."',lines,fixed=TRUE)
  writeLines(lines,target)
}
for(f in list.files(repo_file("steps"),pattern="^[0-9].*\\.R$",full.names=TRUE)[-1])run(f,repo_file("config","demo.R"))
source(repo_file("R","models.R")); source(repo_file("R","regions.R"))
z<-readRDS("outputs/demo/05_design/design.rds")
stopifnot(all(vapply(split(z$presence$fold,z$presence$site_id),function(x)length(unique(x))==1,logical(1))))
stopifnot(all(abs(tapply(z$age_rows$weight,z$age_rows$record_id,sum)-1)<1e-8))
grid<-readRDS("outputs/demo/03_climate/grid.rds"); m<-readRDS("outputs/demo/07_models/models.rds")
for(type in names(m$results))stopifnot(all(m$results[[type]]$score[grid$state=="ice"]==0))
area<-read.csv("outputs/demo/07_models/suitable_area.csv")
stopifnot(all(is.finite(area$suitable_pct)),all(area$suitable_pct>=0 & area$suitable_pct<=100))
# A band boundary belongs to exactly one region, including the upper endpoint.
stopifnot(identical(assign_regions(data.frame(longitude=c(-10,50,130)),list(mode="longitude_bands",breaks=c(-10,50,130),region_names=c("W","E"))),c("W","E","E")))
message("PASS: end-to-end demo, site folds, fossil weights, ice masking, area percentages and region boundaries.")
