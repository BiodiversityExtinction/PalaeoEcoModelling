script_file <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[[1]]))
source(file.path(dirname(script_file), "..", "R", "bootstrap.R"))
source(file.path(getOption("palaeo.repo_root"),"R","common.R")); p <- load_project(); prev <- require_step(p,"01_fossils")
d <- decision(p,"02_calibration"); step <- "02_calibration"
stopifnot(d$curve=="intcal20",d$age_points>=2,d$age_points==as.integer(d$age_points),d$boundary_policy %in% c("exclude","keep_flagged"))
x <- read_output(p,"01_fossils","fossils"); x$boundary_flag <- FALSE; x$median_bp <- NA_real_
grids <- list()
for (i in seq_len(nrow(x))) {
  if (x$date_type[i]=="radiocarbon") {
    cal <- rcarbon::calibrate(x$age_14c_bp[i],errors=x$error_14c_bp[i],calCurves=d$curve,timeRange=c(55000,0),normalised=TRUE,verbose=FALSE)
    g <- cal$grids[[1]]; g <- g[order(g$calBP),]; prob <- g$PrDens/sum(g$PrDens)
    if (any(!is.finite(prob))) stop("Calibration failed: ",x$record_id[i])
    cdf <- cumsum(prob); quant <- function(q) g$calBP[which(cdf>=q)[1]]
    x$cal_young_bp[i] <- quant(.023); x$cal_old_bp[i] <- quant(.977); x$median_bp[i] <- quant(.5)
    x$boundary_flag[i] <- sum(prob[g$calBP>=54900])>=.005
    g$record_id <- x$record_id[i]; grids[[length(grids)+1L]] <- g
  } else x$median_bp[i] <- (x$cal_young_bp[i]+x$cal_old_bp[i])/2
}
table_out(p,step,"calibration_audit",x)
if(length(grids)) {
  gs <- do.call(rbind,grids); write_output(p,step,"calibration_densities",gs)
  # Display six densities; the full distribution of every date remains in RDS.
  gs <- gs[gs$record_id %in% unique(gs$record_id)[seq_len(min(6,length(unique(gs$record_id))))],]
  plot_out(p,step,"example_densities",ggplot(gs,aes(calBP,PrDens))+geom_line()+facet_wrap(~record_id,scales="free")+labs(x="cal BP",y="Calibrated density"))
}
if(d$boundary_policy=="exclude") x <- x[!x$boundary_flag,]
if(!nrow(x)) stop("No dates retained after calibration.")
ages <- do.call(rbind,lapply(seq_len(nrow(x)),function(i) {
  z<-x[rep(i,d$age_points),]; z$age_index<-seq_len(d$age_points); z$age_bp<-seq(x$cal_young_bp[i],x$cal_old_bp[i],length.out=d$age_points); z
}))
write_output(p,step,"ages",ages); table_out(p,step,"ages",ages)
plot_out(p,step,"age_intervals",ggplot(x,aes(median_bp,reorder(record_id,median_bp)))+geom_segment(aes(x=cal_young_bp,xend=cal_old_bp,yend=record_id))+geom_point()+labs(x="Calendar years BP",y="Fossil"),h=max(5,nrow(x)/6))
complete_step(p,step,c(prev,decision_file(d)),d,c(paste(nrow(x),"retained fossils."),"Equally spaced ages approximate interval support, not the calibrated probability density; gaps between modes are included."))
