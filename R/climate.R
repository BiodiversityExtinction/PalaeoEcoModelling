# Reader for Armstrong version 2 monthly files, 0.5-degree grid, January first.
catalogue <- function(p) {
  prefixes <- c(tas="bias_regrid_tas_",pr="bias_regrid_pr_",sftlf="regrid_landmask_",sftgif="regrid_icefrac_")
  rows <- lapply(names(prefixes),function(v) {
    files <- list.files(p$climate_dirs[[v]],pattern="\\.nc$",full.names=TRUE)
    pattern <- paste0("^",prefixes[v],"([0-9.]+)_([0-9.]+)kyr\\.nc$")
    files <- files[grepl(pattern,basename(files))]
    if(!length(files)) stop("No Armstrong files for ",v," at ",p$climate_dirs[[v]])
    parts <- regmatches(basename(files),regexec(pattern,basename(files)))
    data.frame(variable=v,path=files,young=as.numeric(vapply(parts,`[`,"",2)),old=as.numeric(vapply(parts,`[`,"",3)))
  }); do.call(rbind,rows)
}
open_slice <- function(cat,v,age) {
  choices <- cat[cat$variable==v & cat$young<=age & cat$old>=age,]
  if(!nrow(choices)) stop("No ",v," file covers ",age," ka")
  choices <- choices[order(choices$young),]; nc <- ncdf4::nc_open(choices$path[1])
  list(nc=nc,old=choices$old[1],young=choices$young[1],path=choices$path[1])
}
read_cube <- function(s,v,xi,yi,start_t,n_t) {
  dims <- vapply(s$nc$var[[v]]$dim,`[[`,"","name")
  if (!setequal(dims,c("lon","lat","time"))) stop("Unexpected dimensions in ",s$path)
  start <- c(lon=min(xi),lat=min(yi),time=start_t)[dims]
  count <- c(lon=length(xi),lat=length(yi),time=n_t)[dims]
  a <- ncdf4::ncvar_get(s$nc,v,start=start,count=count,collapse_degen=FALSE)
  aperm(a,match(c("lon","lat","time"),dims))
}
read_climate <- function(p,cat,age,d,location=NULL) {
  slices <- list(); on.exit(for(s in slices) ncdf4::nc_close(s$nc))
  for(v in c("tas","pr","sftlf","sftgif")) slices[[v]] <- open_slice(cat,v,age)
  lon <- ncdf4::ncvar_get(slices$tas$nc,"lon"); lat <- ncdf4::ncvar_get(slices$tas$nc,"lat")
  if(any(diff(lon)<=0)||any(diff(lat)<=0)) stop("This reader requires increasing Armstrong longitude/latitude coordinates.")
  for(v in names(slices)) {
    s <- slices[[v]]
    if(!isTRUE(all.equal(ncdf4::ncvar_get(s$nc,"lon"),lon))||!isTRUE(all.equal(ncdf4::ncvar_get(s$nc,"lat"),lat))) stop("Climate grids do not align: ",v)
    expected <- (s$old-s$young)*1000*if(v %in% c("tas","pr")) 12 else 1
    if(s$nc$dim$time$len!=expected) stop("Unexpected temporal resolution: ",s$path,". Use full monthly/annual files, not decadal starter data.")
    units <- ncdf4::ncatt_get(s$nc,v,"units")$value
    if(v=="tas" && !units %in% c("DegC","degC","degrees_Celsius")) stop("Expected Celsius temperature units.")
    if(v=="pr" && !units %in% c("mm day-1","mm/day")) stop("Expected mm/day precipitation units.")
  }
  radius <- if(d$extraction=="mean_3x3") 1L else 0L
  if(is.null(location)) {
    xi <- which(lon>=d$extent["xmin"] & lon<=d$extent["xmax"])
    yi <- which(lat>=d$extent["ymin"] & lat<=d$extent["ymax"])
    if(!length(xi)||!length(yi)) stop("Study extent does not intersect grid.")
    tx<-xi; ty<-yi
  } else {
    tx<-which.min(abs(lon-location[1])); ty<-which.min(abs(lat-location[2]))
    xi<-tx; yi<-ty
  }
  xi<-seq(max(1,min(xi)-radius),min(length(lon),max(xi)+radius))
  yi<-seq(max(1,min(yi)-radius),min(length(lat),max(yi)+radius))
  s<-slices$tas; years<-as.integer((s$old-s$young)*1000)
  target<-max(0,min(years-1,floor((s$old-age)*1000)))
  nyr<-min(d$average_years,years); first<-max(0,min(years-nyr,target-floor((nyr-1)/2)))
  t<-read_cube(s,"tas",xi,yi,first*12+1,nyr*12)
  sp<-slices$pr
  if(sp$old!=s$old||sp$young!=s$young) stop("Temperature and precipitation slices differ.")
  pr<-read_cube(sp,"pr",xi,yi,first*12+1,nyr*12)
  mask <- lapply(c("sftlf","sftgif"),function(v) {
    a<-slices[[v]]; idx<-max(1,min(a$nc$dim$time$len,round((a$old-age)*1000)+1))
    read_cube(a,v,xi,yi,idx,1)[,,1,drop=FALSE]/p$fraction_divisor
  })
  land<-matrix(mask[[1]],length(xi)); ice<-matrix(mask[[2]],length(xi))
  if(any(c(land,ice)<0|c(land,ice)>1,na.rm=TRUE)) stop("Fractions outside 0-1; check fraction_divisor.")
  available<-is.finite(land)&land>=d$land_threshold&is.finite(ice)&ice<d$ice_threshold
  # Average January across years, then February, etc., before spatial averaging.
  monthly<-function(a) {
    ans<-array(NA_real_,c(length(xi),length(yi),12))
    for(m in 1:12) ans[,,m]<-apply(a[,,seq(m,nyr*12,12),drop=FALSE],c(1,2),mean)
    ans
  }
  t<-monthly(t); pr<-monthly(pr)
  cells<-expand.grid(ix=match(tx,xi),iy=match(ty,yi)); rows<-vector("list",nrow(cells))
  for(j in seq_len(nrow(cells))) {
    a<-cells$ix[j]; b<-cells$iy[j]
    state<-if(!is.finite(land[a,b])||land[a,b]<d$land_threshold) "ocean" else if(!is.finite(ice[a,b])) "missing" else if(ice[a,b]>=d$ice_threshold) "ice" else "land"
    values<-setNames(rep(NA_real_,length(predictor_names)),predictor_names)
    if(state=="land") {
      xx<-seq(max(1,a-radius),min(length(xi),a+radius)); yy<-seq(max(1,b-radius),min(length(yi),b+radius))
      ok<-available[xx,yy,drop=FALSE]
      tm<-vapply(1:12,function(m) mean(t[xx,yy,m,drop=FALSE][ok],na.rm=TRUE),numeric(1))
      pm<-vapply(1:12,function(m) mean(pr[xx,yy,m,drop=FALSE][ok],na.rm=TRUE),numeric(1))
      if(all(is.finite(c(tm,pm)))) values<-climate_metrics(tm,pm) else state<-"missing"
    }
    rows[[j]]<-data.frame(age_ka=age,longitude=lon[xi[a]],latitude=lat[yi[b]],state=state,area_weight=cos(lat[yi[b]]*pi/180),t(values),check.names=FALSE)
  }; do.call(rbind,rows)
}
