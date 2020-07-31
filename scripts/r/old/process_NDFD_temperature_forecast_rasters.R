rm(list=ls())
# Start the clock!
ptm <- proc.time()
library(raster)
library(utils)
library(rgdal)
library(maptools)
library(rgeos)
library(tools)
library(stringr)
library(utils)
library(zip)
library(logging)

source("D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\scripts\\r\\funcdefs.R")
root.dir   <- "D:/Users/climate_dashboard/Documents/climate_dashboard"
tmp.dir    <- paste(root.dir, "/data/tmp", sep="") 
input.dir  <- paste(root.dir, "/data/input_files", sep="") 
output.dir <- paste(root.dir, "/data/output_files", sep="") 
today <- Sys.Date()
today <- format(today, format="%m-%d-%Y")

#logger config
log.filename <- paste(root.dir, "/log/process_NDFD_temperature_forecast_rasters_", today,".log", sep="")

logReset()
basicConfig(level='FINEST')
addHandler(writeToFile, file=log.filename, level='DEBUG')

log.msg <- "\n\n----------Process Starting: Process NDFD Temperature Forecast Rasters"
loginfo('%s', log.msg)


tryCatch(
  expr=
    {
      log.msg <- "trying to kill ArcGISPro"
      loginfo('%s', log.msg)
      system("taskkill /F /IM ArcGISPro.exe")
    },
  error= function(e)
  {
    log.msg <- "couldn't kill ArcGISPro"
    loginfo('%s', log.msg)
  }
)

#URLs for most current NDFD files
conus.forecast.temperature.url1 <- "https://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.conus/VP.001-003/ds.maxt.bin"
conus.forecast.temperature.url2 <- "https://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.conus/VP.004-007/ds.maxt.bin"

#destination files in local directories
conus.forecast.temperature.grid1   <- paste(input.dir, "/NDFD/conus/ds.maxt_001-003.bin", sep="")
conus.forecast.temperature.grid2   <- paste(input.dir, "/NDFD/conus/ds.maxt_004-007.bin", sep="")
conus.forecast.first.day.filename  <- paste(output.dir, "/conus_max_temp_forecast_first_day.tif",sep="")
conus.forecast.second.day.filename <- paste(output.dir, "/conus_max_temp_forecast_second_day.tif",sep="")
conus.forecast.third.day.filename  <- paste(output.dir, "/conus_max_temp_forecast_third_day.tif",sep="")

#2. NDFD raster files
#download NDFD files in binary mode
#print("Processing NDFD temperature forecast files...")
loginfo('%s',  "Downloading latest forecast rasters...")
download.file(conus.forecast.temperature.url1,conus.forecast.temperature.grid1,mode="wb")
download.file(conus.forecast.temperature.url2,conus.forecast.temperature.grid2,mode="wb")
loginfo('%s', "Download complete.")

#open NDFD files
loginfo('%s',  "Opening NDFD rasters...")
conus.forecast.temperature.grid1.brick <- stack(conus.forecast.temperature.grid1)
conus.forecast.first.day  <- raster::raster(conus.forecast.temperature.grid1,layer=1)
conus.forecast.second.day <- raster::raster(conus.forecast.temperature.grid1,layer=2)
conus.forecast.third.day  <- raster::raster(conus.forecast.temperature.grid1,layer=3)
conus.forecast.temperature.all.grids <- stack(conus.forecast.temperature.grid1,conus.forecast.temperature.grid1)

log.msg <- paste("Writing ", conus.forecast.first.day.filename, sep="")
loginfo('%s',  log.msg)
writeRaster(x=conus.forecast.first.day,  filename = conus.forecast.first.day.filename,  format="GTiff",overwrite=T)

log.msg <- paste("Writing ", conus.forecast.second.day.filename, sep="")
loginfo('%s',  log.msg)
writeRaster(x=conus.forecast.second.day, filename = conus.forecast.second.day.filename, format="GTiff",overwrite=T)

log.msg <- paste("Writing ", conus.forecast.third.day.filename, sep="")
loginfo('%s',  log.msg)
writeRaster(x=conus.forecast.third.day,  filename = conus.forecast.third.day.filename,  format="GTiff",overwrite=T)

log.msg <- "\n----------Process Ending"
loginfo('%s', log.msg)