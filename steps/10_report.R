script_file <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[[1]]))
source(file.path(dirname(script_file), "..", "R", "bootstrap.R"))
source(file.path(getOption("palaeo.repo_root"),"R","common.R")); p<-load_project(); prev<-require_step(p,"09_regions"); step<-"10_report"
folders<-list.dirs(p$output_dir,recursive=FALSE,full.names=TRUE)
lines<-c(paste0("# Analysis record: ",p$name),"",if(p$synthetic)"SYNTHETIC DEMONSTRATION ONLY." else "Draft analysis record: review before writing manuscript methods.","",paste("Generated:",Sys.time()),"","## Decisions")
for(folder in folders) {
  f<-file.path(folder,"provenance.rds"); if(!file.exists(f)||basename(folder)==step)next
  require_step(p,basename(folder)); a<-readRDS(f)
  lines<-c(lines,"",paste("###",basename(folder)),"```r",capture.output(dput(a$settings)),"```", "",paste0("Outputs: `",folder,"`"))
}
lines<-c(lines,"","## Limits to report","- Fossil occurrences describe observed climate associations, not the full physiological niche.","- Random background is not confirmed absence and does not correct fossil-collection bias.","- Ten age alternatives are one fossil's uncertainty, not ten independent observations.","- Spatial tuning folds are not an independent final evaluation.","- Ice masking, fixed-domain and predictor choices affect inferred suitable area.","- Suitable climate is not proof of occupation, connectivity, or an extinction mechanism.","- Compare MaxEnt with Gaussian qualitatively: their raw scores differ.","- Document calibration exclusions, sample sizes, region boundaries and novel-climate warnings.")
writeLines(lines,out(p,step,"analysis_record.md"))
complete_step(p,step,prev,list(),"Analysis record exported. Read the limitations and retain all stage outputs with your manuscript archive.")
