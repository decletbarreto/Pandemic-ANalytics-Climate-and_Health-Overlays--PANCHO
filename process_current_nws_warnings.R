rm(list=ls())
#process Current NWS warnings shapefile
library("rgeos")
library(sf)
library(reshape2)
library(logging)
library(tidyr)

#run config file
source("D:/UCS_projects/climate_shop/SuperPANCHO/bin/run_config.R")

ptm <- proc.time()
today <- format(as.Date(Sys.Date()), "%m-%d-%Y")

#logger config
log.filename <- paste(log.dir, "/process_nws_alerts_", today,".log", sep="")
logReset()
basicConfig(level='FINEST')
addHandler(writeToFile, file=log.filename, level='DEBUG')
log.msg <- "\n\n----------Process Starting: Process Current NWS data"
loginfo('%s', log.msg)

counties.sf <- st_read(dsn = counties.gdb, layer = counties.layer)

#download current NWS warnings
log.msg <- "Downloading current NWS warnings shapefile..."
loginfo('%s', log.msg)
tryCatch(
  expr=
    {
      if (file.exists(nws.current.zip.local.file)) {
        log.msg <- paste("Deleting old shapefile: ", nws.current.zip.local.file, sep="")
        loginfo('%s', log.msg)
        file.remove(nws.current.zip.local.file)
      }
      
      download.file(url = nws.current.url, destfile = nws.current.zip.local.file)
      print("Done.")
    },
  error= function(e)
  {
    log.msg <- paste("Download of ",nws.current.url, " failed. Exiting",sep="" )
    logerror('%s', log.msg)
    stop()
  }
)

#unzip current NWS warnings
log.msg <- paste("Unzipping ", nws.current.zip.local.file, sep="")
loginfo('%s', log.msg)
#extract file
utils::untar(nws.current.zip.local.file, exdir = nws.tmp.dir)
#list the files in the archive
current.nws.filename <- utils::untar(nws.current.zip.local.file, exdir = nws.tmp.dir, list=T)

#rebuild filename with extension in case the first element in the list if not the shp file.
current.nws.filename <- paste(nws.tmp.dir, "/", tools::file_path_sans_ext(current.nws.filename[1]), ".shp", sep="")

#read current NWS warnings as sf
log.msg <- paste("Reading ", current.nws.filename, sep="")
loginfo('%s', log.msg)
current.nws.sf <- st_read(dsn=current.nws.filename)
#colnames(current.nws.sp)

#project to county CRS
current.nws.sf <- st_transform(x=current.nws.sf, crs=st_crs(counties.sf))
#plot(current.nws.sp[,c("PHENOM","geometry")] )
#getting county centroids
counties.centroids.sf     <- st_centroid(counties.sf)

#project NWS warnings to counties CRS
#current.nws.sp <- st_transform(current.nws.sp, crs=counties.sf@proj4string)
current.nws.sf <- st_make_valid(current.nws.sf)

#now extract desired weather alert types (PHENOM) 
log.msg <- "Extracting weather alerts..."
loginfo('%s', log.msg)
phenom.types.sf <- current.nws.sf[current.nws.sf$PHENOM %in% phenom.types ,]
log.msg <- "Done."
loginfo('%s', log.msg)

log.msg <- "joining alert labels."
loginfo('%s', log.msg)
phenom.types.sf <- sp::merge(phenom.types.sf, phenom.df, by.x = "PHENOM", by.y = "types")
log.msg <- "Done."
loginfo('%s', log.msg)

log.msg <- "spatial join of alerts to counties"
loginfo('%s', log.msg)
counties.centroid.join.sf <- st_join(counties.centroids.sf, phenom.types.sf, join=st_within, left=F)

#cast alerts to capture all alerts in county
#cast GEOID and alert_type, drop geom field
counties.centroid.join.df<- st_drop_geometry(counties.centroid.join.sf[,c("GEOID",alert.type.column, alert.url.column)])

#function to recode alerts to 0 or 1
fn <- function(x)
{
  if (is.na(x)) {
    return(0)
  }
  return(1)
 
}
alerts.df <-dcast(counties.centroid.join.df, formula = GEOID ~ alert_type, fun.aggregate = fn, fill=0)

#rename columns for shapefile export
colnames(alerts.df)[which(colnames(alerts.df)==phenom.labels[1])]  <- phenom.export.columns[1]
colnames(alerts.df)[which(colnames(alerts.df)==phenom.labels[2])]  <- phenom.export.columns[2]
colnames(alerts.df)[which(colnames(alerts.df)==phenom.labels[3])]  <- phenom.export.columns[3]
colnames(alerts.df)[which(colnames(alerts.df)==phenom.labels[4])]  <- phenom.export.columns[4]
colnames(alerts.df)[which(colnames(alerts.df)==phenom.labels[5])]  <- phenom.export.columns[5]
colnames(alerts.df)[which(colnames(alerts.df)==phenom.labels[6])]  <- phenom.export.columns[6]
colnames(alerts.df)[which(colnames(alerts.df)==phenom.labels[7])]  <- phenom.export.columns[7]
colnames(alerts.df)[which(colnames(alerts.df)==phenom.labels[8])]  <- phenom.export.columns[8]
colnames(alerts.df)[which(colnames(alerts.df)==phenom.labels[9])]  <- phenom.export.columns[9]
colnames(alerts.df)[which(colnames(alerts.df)==phenom.labels[10])] <- phenom.export.columns[10]
colnames(alerts.df)[which(colnames(alerts.df)==phenom.labels[11])] <- phenom.export.columns[11]


#add NWS alert columns that don't exist, i.e. for alerts not declared. 
#this is needed for schema completeness in ArcGIS Online final shapefile
alerts.df[phenom.export.columns[!(phenom.export.columns %in% colnames(alerts.df))]] = 0

log.msg <- "Done."
loginfo('%s', log.msg)

#join alert_type field data
alerts.df2 <- dplyr::left_join(alerts.df, counties.centroid.join.df, by = "GEOID") 

log.msg <- "Merging alerts with counties..."
loginfo('%s', log.msg)
#counties.centroid.join.df<- st_set_geometry(counties.centroid.join.sf, NULL)
counties.sf2 <- sp::merge(counties.sf,alerts.df2[,],by="GEOID",all.x=F)
#remove duplicated GEOIDs i.e., counties with multiple alerts
counties.sf3 <- counties.sf2[!duplicated(counties.sf2$GEOID),]
log.msg <- "Done."
loginfo('%s', log.msg)

log.msg <- paste("Writing to ", output.dir, "/", counties_nws, sep="")
loginfo('%s', log.msg)
st_write(counties.sf3[,-which(names(counties.sf3) %in% nws.drop.cols)],dsn=output.dir,layer=counties_nws, driver="ESRI Shapefile", delete_layer = T, quiet=F)
log.msg <- "Done."
loginfo('%s', log.msg)
log.msg <- "\n\n----------Process Ending: Process Current NWS data"
loginfo('%s', log.msg)
print(proc.time() - ptm)
