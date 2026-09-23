# Developer/instructor test: explicitly approves SYNTHETIC decisions only.
# Students should follow README.md instead of using this shortcut.
source("R/common.R")
run<-function(script,config=NULL) {
  status<-system2(file.path(R.home("bin"),"Rscript"),c(script,config))
  if(status!=0)stop("Failed: ",script)
}
run("examples/make_demo.R")
dir.create("decisions/demo",recursive=TRUE,showWarnings=FALSE)
for(f in list.files("examples/demo_decisions",full.names=TRUE)) {
  target<-file.path("decisions/demo",basename(f))
  if(file.exists(target))stop("This test refuses to overwrite existing demo decisions: ",target,". Use a fresh checkout or run individual steps.")
  lines<-readLines(f); lines<-gsub('reviewed=FALSE','reviewed=TRUE',lines,fixed=TRUE)
  lines<-gsub('rationale=""','rationale="Approved synthetic smoke-test settings; no scientific inference."',lines,fixed=TRUE)
  writeLines(lines,target)
}
for(f in list.files("steps",pattern="^[0-9].*\\.R$",full.names=TRUE)[-1])run(f,"config/demo.R")
source("R/models.R"); source("R/regions.R")
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
