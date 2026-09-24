script_file <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[[1]]))
source(file.path(dirname(script_file), "..", "R", "bootstrap.R"))
source(file.path(getOption("palaeo.repo_root"),"R","common.R")); source(repo_file("R","models.R")); source(repo_file("R","regions.R"))
p<-load_project(); prev<-require_step(p,"08_uncertainty"); d<-decision(p,"09_regions"); step<-"09_regions"
grid<-read_output(p,"03_climate","grid"); regions<-assign_regions(grid,d)
baseline<-read_output(p,"07_models","models"); ensemble<-read_output(p,"08_uncertainty","ensemble")
baseline_rows<-list(); raw<-list()
for(type in names(baseline$results)) {
  b<-baseline$results[[type]]
  baseline_rows[[type]]<-cbind(model=type,region_summaries(grid,b$score,b$threshold,regions))
  for(r in seq_len(ncol(ensemble$scores[[type]])))raw[[length(raw)+1]]<-cbind(model=type,replicate=r,region_summaries(grid,ensemble$scores[[type]][,r],ensemble$thresholds[r,type],regions))
}
base<-do.call(rbind,baseline_rows); raw<-do.call(rbind,raw)
bands<-do.call(rbind,lapply(split(raw,paste(raw$model,raw$region,raw$age_ka)),function(x)data.frame(model=x$model[1],region=x$region[1],age_ka=x$age_ka[1],median=median(x$suitable_pct),low=quantile(x$suitable_pct,.025),high=quantile(x$suitable_pct,.975))))
table_out(p,step,"regional_baseline",base); table_out(p,step,"regional_intervals",bands)
plot_out(p,step,"regional_suitability",ggplot(bands,aes(age_ka,median,colour=region,fill=region))+geom_ribbon(aes(ymin=low,ymax=high),alpha=.12,colour=NA)+geom_line()+facet_wrap(~model)+scale_x_reverse()+labs(x="Age (ka BP)",y="Suitable % of regional land",title="Solid: age/site ensemble median; ribbons: 95% sensitivity envelope"),12,6)
climate<-list(); region_list<-list("Whole study area"=rep(TRUE,nrow(grid)))
if(!all(regions=="Whole study area")) for(region in unique(regions))region_list[[region]]<-regions==region
for(region in names(region_list))for(age in sort(unique(grid$age_ka))) {
  x<-grid[region_list[[region]] & grid$age_ka==age & grid$state=="land",]
  if(!nrow(x))next
  for(v in predictor_names)climate[[length(climate)+1]]<-data.frame(region=region,age_ka=age,variable=v,mean=weighted.mean(x[[v]],x$area_weight))
}
climate<-do.call(rbind,climate); table_out(p,step,"regional_climate",climate)
plot_out(p,step,"regional_climate",ggplot(climate,aes(age_ka,mean,colour=region))+geom_line()+facet_wrap(~variable,scales="free_y",ncol=2)+scale_x_reverse()+labs(x="Age (ka BP)",y="Area-weighted mean (units in variable dictionary)",title="Climate across ice-free land, not just fossil localities"),12,12)
ice<-unique(base[c("age_ka","region","ice_pct")]); table_out(p,step,"ice_coverage",ice)
plot_out(p,step,"ice_coverage_supplement",ggplot(ice,aes(age_ka,ice_pct,colour=region))+geom_line()+scale_x_reverse()+labs(x="Age (ka BP)",y="Ice-covered % of land",title="Ice fraction >= chosen threshold counts as ice-covered"))
xy<-unique(grid[c("longitude","latitude")]); xy$region<-regions[match(paste(xy$longitude,xy$latitude),paste(grid$longitude,grid$latitude))]
extent<-readRDS(out(p,"03_climate","provenance.rds"))$settings$extent
map_coords<-function()coord_quickmap(xlim=extent[c("xmin","xmax")],ylim=extent[c("ymin","ymax")],expand=FALSE)
fossils<-read_output(p,"03_climate","means")
plot_out(p,step,"region_map",ggplot(xy,aes(longitude,latitude,fill=region))+geom_tile(alpha=.3)+country_lines()+geom_point(data=fossils,aes(longitude,latitude),inherit.aes=FALSE,size=1)+map_coords()+labs(title="Reporting regions; black dots are included fossil localities",fill="Region"))
available<-sort(unique(grid$age_ka)); requested<-data.frame(requested_ka=d$map_ages,used_ka=vapply(d$map_ages,function(x)available[which.min(abs(available-x))],numeric(1)))
table_out(p,step,"map_times",requested)
for(type in names(baseline$results)) {
  g<-grid; g$score<-baseline$results[[type]]$score; g<-g[g$age_ka %in% requested$used_ka,]
  plot_out(p,step,paste0("maps_",tolower(type)),ggplot(g[g$state=="land",],aes(longitude,latitude,fill=score))+geom_tile()+scale_fill_viridis_c(limits=c(0,1),name="Suitability")+
    geom_tile(data=g[g$state=="ice",],aes(longitude,latitude),inherit.aes=FALSE,fill="lightblue")+country_lines()+facet_wrap(~age_ka,ncol=2)+map_coords()+labs(title=paste(type,"baseline; panels in ka BP; blue = ice; white = ocean/missing")),12,9)
}
inputs<-c(prev,decision_file(d),if(d$mode=="polygons")d$polygon_file)
complete_step(p,step,inputs,d,c("Reporting regions do not change the fitted model or its background.","Percent denominator is land including ice at each time: changing coastlines can alter it.","Regional climate means exclude ice-covered cells; changes can reflect both climate and changing ice-free area.","Whole study area is only Eurasia-wide if the chosen domain actually covers Eurasia.","Maps show modern country outlines for orientation, not reconstructed political or coastal boundaries."))
