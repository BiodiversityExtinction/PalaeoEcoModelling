source("R/common.R"); p<-load_project(); prev<-require_step(p,"03_climate"); step<-"04_variables"
x<-read_output(p,"03_climate","means")
correlation<-cor(x[predictor_names],method="spearman")
tab<-as.data.frame(as.table(correlation)); names(tab)<-c("variable_1","variable_2","rho")
table_out(p,step,"correlations",tab)
plot_out(p,step,"correlations",ggplot(tab,aes(variable_1,variable_2,fill=rho))+geom_tile()+scale_fill_gradient2(low="#b65b32",high="#196573",limits=c(-1,1))+theme(axis.text.x=element_text(angle=45,hjust=1))+labs(title="Redundant fossil climate summaries",x=NULL,y=NULL))
long<-do.call(rbind,lapply(predictor_names,function(v) data.frame(record_id=x$record_id,age_ka=x$median_bp/1000,variable=unname(predictor_labels[v]),value=x[[v]])))
plot_out(p,step,"fossil_climate_through_time",ggplot(long,aes(age_ka,value))+geom_point(colour="#196573")+facet_wrap(~variable,scales="free_y",ncol=2)+scale_x_reverse()+labs(x="Fossil age (cal ka BP)",y=NULL,title="Climates at sampled fossil sites"),h=10)
complete_step(p,step,prev,list(),c("Choose a small biologically relevant set; |rho| > 0.7 flags possible redundancy.","These are sampled occurrence climates; changes can reflect collecting geography.","No model has yet been fitted; permutation importance is generated in step 07."))
