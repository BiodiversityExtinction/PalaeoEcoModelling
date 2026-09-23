assign_regions <- function(grid,d) {
  if(d$mode=="whole")return(rep("Whole study area",nrow(grid)))
  if(d$mode %in% c("longitude_bands","latitude_bands")) {
    if(length(d$region_names)!=length(d$breaks)-1 || any(diff(d$breaks)<=0) || anyDuplicated(d$region_names))stop("Check region_names and increasing breaks.")
    coordinate<-grid[[if(d$mode=="longitude_bands")"longitude" else "latitude"]]
    result<-as.character(cut(coordinate,d$breaks,labels=d$region_names,right=FALSE,include.lowest=TRUE))
  } else if(d$mode=="polygons") {
    if(!requireNamespace("sf",quietly=TRUE))stop("Install sf to use polygons; broad bands need no sf.")
    polygons<-sf::st_read(d$polygon_file,quiet=TRUE)
    if(is.na(sf::st_crs(polygons)))stop("Polygon file needs a declared CRS.")
    if(!d$name_column %in% names(polygons))stop("Missing polygon region name column.")
    polygons<-sf::st_transform(sf::st_make_valid(polygons),4326)
    points<-sf::st_as_sf(grid,coords=c("longitude","latitude"),crs=4326)
    matches<-sf::st_intersects(points,polygons)
    if(any(lengths(matches)>1))stop("Some cell centres belong to multiple polygons, including shared boundaries; adjust boundaries or use bands.")
    result<-vapply(matches,function(i)if(length(i))as.character(polygons[[d$name_column]][i]) else NA_character_,character(1))
  } else stop("Unknown region mode.")
  result[is.na(result)]<-"Unassigned"; result
}
region_summaries <- function(grid,score,threshold,regions) {
  whole<-area_summary(grid,score,threshold)
  if(all(regions=="Whole study area"))return(whole)
  rbind(whole,area_summary(grid,score,threshold,regions))
}
