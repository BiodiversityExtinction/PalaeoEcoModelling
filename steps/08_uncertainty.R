script_file <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[[1]]))
source(file.path(dirname(script_file), "..", "R", "bootstrap.R"))
source("R/common.R"); source("R/models.R"); p<-load_project(); prev<-require_step(p,"07_models")
d<-decision(p,"08_uncertainty"); step<-"08_uncertainty"
stopifnot(d$replicates>=2,d$replicates==as.integer(d$replicates),is.logical(d$bootstrap_sites),length(d$bootstrap_sites)==1)
z<-read_output(p,"05_design","design"); baseline<-read_output(p,"07_models","models"); grid<-read_output(p,"03_climate","grid")
scores<-list(MaxEnt=matrix(NA_real_,nrow(grid),d$replicates),Gaussian=matrix(NA_real_,nrow(grid),d$replicates))
thresholds<-matrix(NA_real_,d$replicates,2,dimnames=list(NULL,names(scores))); summaries<-list(); draws<-list()
for(r in seq_len(d$replicates)) {
  message("Uncertainty replicate ",r,"/",d$replicates)
  sampled<-do.call(rbind,lapply(split(z$age_rows,z$age_rows$record_id),function(x)x[sample.int(nrow(x),1),,drop=FALSE]))
  sites<-unique(sampled$site_id)
  if(d$bootstrap_sites) {
    chosen<-sample(sites,length(sites),replace=TRUE)
    sampled<-do.call(rbind,lapply(seq_along(chosen),function(i) {
      x<-sampled[sampled$site_id==chosen[i],]; x$site_id<-paste0(x$site_id,"_draw",i); x
    }))
  }
  draws[[r]]<-data.frame(replicate=r,sampled[c("record_id","site_id","age_ka")])
  bg<-sample_background(grid,nrow(z$background),z$age_range)
  for(type in names(scores)) {
    fit<-fit_model(type,sampled,bg,z$vars,baseline$settings$features,baseline$settings$regmult)
    threshold<-as.numeric(quantile(site_scores(sampled,predict_model(fit,sampled)),baseline$q))
    scores[[type]][,r]<-projection(fit,grid); thresholds[r,type]<-threshold
    summaries[[length(summaries)+1]]<-cbind(model=type,replicate=r,area_summary(grid,scores[[type]][,r],threshold))
  }
}
write_output(p,step,"ensemble",list(scores=scores,thresholds=thresholds,settings=d))
table_out(p,step,"sampled_fossils",do.call(rbind,draws)); raw<-do.call(rbind,summaries); table_out(p,step,"area_replicates",raw)
bands<-do.call(rbind,lapply(split(raw,paste(raw$model,raw$age_ka)),function(x)data.frame(model=x$model[1],age_ka=x$age_ka[1],median=median(x$suitable_pct),low=quantile(x$suitable_pct,.025),high=quantile(x$suitable_pct,.975))))
table_out(p,step,"area_intervals",bands)
plot_out(p,step,"suitability_uncertainty",ggplot(bands,aes(age_ka,median,colour=model,fill=model))+geom_ribbon(aes(ymin=low,ymax=high),alpha=.15,colour=NA)+geom_line()+scale_x_reverse()+labs(x="Age (ka BP)",y="Suitable % of land",title="Median and central 95% sensitivity envelope (not confidence intervals)"))
complete_step(p,step,c(prev,decision_file(d)),d,c("Each fit samples ONE unique age-climate vector per fossil, not ten independent fossils.","Equal sampling of evenly spaced ages is an interval sensitivity analysis, not sampling the calibrated age posterior.","Site bootstrap, if enabled, adds sampling uncertainty; random backgrounds are redrawn.","Envelopes omit climate-model structural uncertainty, fossil detection bias and uncertainty about species identity.","A small ensemble is a smoke test; check interval stability with more replicates for research."))
