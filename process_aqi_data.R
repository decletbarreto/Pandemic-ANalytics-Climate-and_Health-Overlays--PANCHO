#process Air Quality Index daily data file
rm(list=ls())
library("rgeos")
library(sf)
library(logging)
library(foreign)
library(raster) 
library(dplyr)

#run config file
source("D:/UCS_projects/climate_shop/SuperPANCHO/bin/run_config.R")

ptm <- proc.time()
today <- format(as.Date(Sys.Date()), "%m-%d-%Y")

#logger config
log.filename <- paste(log.dir, "/process_aqi_file_", today,".log", sep="")
logReset()
basicConfig(level='FINEST')
addHandler(writeToFile, file=log.filename, level='DEBUG')
log.msg <- "\n\n----------Process Starting: Process AirNow Reporting Area Information File"
loginfo('%s', log.msg)

counties.sf <- st_read(dsn = counties.gdb, layer = counties.layer)

#download AQI forecast tomorrow in GRIB format
log.msg <- "Downloading AirNow AQI forecast for tomorrow in GRIB format..."
loginfo('%s', log.msg)
tryCatch(
  expr=
    {
      download.file(url = aqi.tomorrow.forecast.grib.file, destfile = aqi.local.file)
      print("Done.")
    },
  error= function(e)
  {
    log.msg <- paste("Download of ",aqi.tomorrow.forecast.grib.file, " failed. Exiting",sep="" )
    logerror('%s', log.msg)
    stop()
  }
)

#open file
log.msg <- "Opening AirNow AQI forecast for tomorrow raster..."
loginfo('%s', log.msg)
tryCatch(
  expr=
    {
      aqi.raster <- brick(aqi.tomorrow.forecast.grib.file)
      log.msg <- "Done."
      loginfo('%s', log.msg)
    },
  error= function(e)
  {
    log.msg <- paste("Opening ",aqi.tomorrow.forecast.grib.file, " failed. Exiting",sep="" )
    logerror('%s', log.msg)
    stop()
  }
)
#plot(aqi.raster)

#calculate AQI forecast zonal stats in counties
tryCatch(
  expr=
    {
      #first clip raster to counties sf
      #subset counties to conus
      log.msg <- paste("Cropping ",aqi.tomorrow.forecast.grib.file, " to CONUS perimeter...", sep="") 
      loginfo('%s', log.msg)
      aqi.raster.crop      <- crop(aqi.raster, conus.perimeter.sf)
      
      log.msg <- paste("Calculating mean AQI value in counties...", sep="") 
      loginfo('%s', log.msg)
      aqi.raster.crop.mean <- raster::extract(aqi.raster.crop, counties.sf, fun=mean, na.rm=TRUE, df=TRUE)
      log.msg <- "Done."
      loginfo('%s', log.msg)
      
      #attach mean AQI to counties sf
      counties.sf[,mean.aqi.colname] <- round(aqi.raster.crop.mean[,2],aqi.rounding.factor)
      
    },
  error= function(e)
  {
    log.msg <- paste("Zonal statistics for ",aqi.tomorrow.forecast.grib.file, " failed. Exiting",sep="" )
    logerror('%s', log.msg)
    stop()
  }
)

#recode mean AQI into categories
#https://www.airnow.gov/aqi/aqi-basics/
counties.sf[,mean.aqi.category.colname] <- NA

counties.df <- st_drop_geometry(counties.sf[,mean.aqi.colname])
counties.sf[,mean.aqi.category.colname] <- cut(x = counties.df[,mean.aqi.colname],
                                               breaks = c(-Inf, 50, 100, 150, 200, 300, Inf),
                                               labels=c("Good","Moderate","Unhealthy for Sensitive Groups","Unhealthy","Very Unhealthy", "Hazardous"))              


log.msg <- paste("Writing shapefile to ",  aqi.tmp.dir, "/", aqi.tomorrow.forecast.shapefile,".shp", sep="") 
loginfo('%s', log.msg)
st_write(counties.sf[,aqi.cols],dsn=output.dir, layer=aqi.tomorrow.forecast.shapefile, driver="ESRI Shapefile", delete_layer=T)

log.msg <- paste("Writing AQI forecast raster to ",  aqi.tmp.dir, "/", aqi.tomorrow.forecast.shapefile,".shp", sep="") 
loginfo('%s', log.msg)
writeRaster(x = aqi.raster.crop, filename = paste(aqi.tmp.dir, aqi.tomorrow.forecast.grib.raster,sep="/"), 
            format="GTiff", overwrite=TRUE)

#write to Dropbox
st_write(counties.sf[,aqi.cols],dsn=paste(SuperPANCHO.Dropbox.dir, "/AQI", sep=""), layer=aqi.tomorrow.forecast.shapefile, driver="ESRI Shapefile", delete_layer=T)
writeRaster(x = aqi.raster.crop, filename = paste(SuperPANCHO.Dropbox.dir, "AQI", aqi.tomorrow.forecast.grib.raster,sep="/"), 
            format="GTiff", overwrite=TRUE)

log.msg <- "\n\n----------Process Ending: Process AirNow Reporting Area Information File"
loginfo('%s', log.msg)
print(proc.time() - ptm)

