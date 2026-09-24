script_file <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[[1]]))
source(file.path(dirname(script_file), "..", "R", "bootstrap.R"))
source("R/common.R"); source("R/models.R"); p<-load_project(); prev<-require_step(p,"06_tuning")
d<-decision(p,"07_models"); step<-"07_models"; z<-read_output(p,"05_design","design")
tuning<-read_output(p,"06_tuning","tuning"); q<-tuning$settings$omission_quantile
if(!any(tuning$metrics$features==d$features & tuning$metrics$regmult==d$regmult))stop("Choose a candidate evaluated in step 06.")
grid<-read_output(p,"03_climate","grid"); fits<-list(); results<-list(); importance<-list(); response<-list(); metrics<-list()
for(type in c("MaxEnt","Gaussian")) {
  fit<-fit_model(type,z$presence,z$background,z$vars,d$features,d$regmult); fits[[type]]<-fit
  threshold<-as.numeric(quantile(site_scores(z$presence,predict_model(fit,z$presence)),q))
  score<-projection(fit,grid)
  results[[type]]<-list(score=score,threshold=threshold)
  metrics[[type]]<-cbind(model=type,validation(type,z$presence,z$background,z$vars,d$features,d$regmult,q))
  for(k in sort(unique(z$presence$fold))) {
    train<-z$presence[z$presence$fold!=k,]; test<-z$presence[z$presence$fold==k,]
    train_bg<-z$background[z$background$fold!=k,]; bg<-z$background[z$background$fold==k,]
    held_fit<-fit_model(type,train,train_bg,z$vars,d$features,d$regmult)
    baseline<-evaluate(held_fit,train,test,bg,q)["auc"]
    joint<-rbind(test[z$vars],bg[z$vars])
    for(v in z$vars) for(r in seq_len(5)) {
      shuffled<-joint; shuffled[[v]]<-sample(shuffled[[v]])
      positive<-site_scores(test,predict_model(held_fit,shuffled[seq_len(nrow(test)),,drop=FALSE]))
      negative<-predict_model(held_fit,shuffled[nrow(test)+seq_len(nrow(bg)),,drop=FALSE])
      importance[[length(importance)+1]]<-data.frame(model=type,fold=k,variable=v,repeat_id=r,auc_drop=unname(baseline-auc(positive,negative)))
    }
  }
  for(v in z$vars) {
    reference<-as.data.frame(as.list(vapply(z$presence[z$vars],median,numeric(1))))
    x<-reference[rep(1,100),,drop=FALSE]; x[[v]]<-seq(min(z$background[[v]]),max(z$background[[v]]),length.out=100)
    response[[length(response)+1]]<-data.frame(model=type,variable=v,value=x[[v]],score=predict_model(fit,x))
  }
}
write_output(p,step,"models",list(fits=fits,results=results,settings=d,q=q))
imp<-do.call(rbind,importance); resp<-do.call(rbind,response)
table_out(p,step,"validation",do.call(rbind,metrics)); table_out(p,step,"permutation_importance",imp); table_out(p,step,"response_curves",resp)
plot_out(p,step,"variable_contributions",ggplot(imp,aes(variable,auc_drop,fill=model))+geom_boxplot(outlier.size=.8)+geom_hline(yintercept=0,linetype=2)+labs(x=NULL,y="Held-out AUC decrease after shuffling",title="Predictive contribution, not causal importance")+theme(axis.text.x=element_text(angle=25,hjust=1)))
plot_out(p,step,"response_curves",ggplot(resp,aes(value,score,colour=model))+geom_line()+facet_wrap(~variable,scales="free_x")+labs(x="Predictor (see variable dictionary for units)",y="Model-specific suitability score",title="Other predictors held at fossil medians; combinations may be unrealistic"))
summary<-do.call(rbind,lapply(names(results),function(type)cbind(model=type,area_summary(grid,results[[type]]$score,results[[type]]$threshold))))
table_out(p,step,"suitable_area",summary)
plot_out(p,step,"suitability_through_time",ggplot(summary,aes(age_ka,suitable_pct,colour=model))+geom_line()+geom_point()+scale_x_reverse()+labs(x="Age (ka BP)",y="Suitable % of land (including ice-covered land)",title="Mean-age-climate baseline; model-specific thresholds"))
# Flag transfer outside the univariate training ranges; this is not a full MESS test.
novel<-rep(FALSE,nrow(grid)); ok<-grid$state=="land"
for(v in z$vars) {bounds<-range(c(z$presence[[v]],z$background[[v]])); novel[ok]<-novel[ok]|grid[[v]][ok]<bounds[1]|grid[[v]][ok]>bounds[2]}
grid$novel_climate<-novel; table_out(p,step,"novel_climate_cells",grid[c("age_ka","longitude","latitude","state","novel_climate")])
complete_step(p,step,c(prev,decision_file(d)),d,c("Both baseline models use one mean climate vector per fossil.","MaxEnt cloglog and Gaussian relative density have different score scales; neither is a calibrated probability of survival.","Thresholds use a lower quantile of site-averaged training presence scores. Ice is always unsuitable.","Feature importance is conditional on the predictors and background, not evidence that a variable caused extinction.","MaxEnt clamps predictors outside training ranges; Gaussian extrapolates. Inspect novel_climate_cells.csv."))
