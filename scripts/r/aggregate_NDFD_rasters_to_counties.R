rm(list=ls())
# Start the clock!
ptm <- proc.time()
library(raster)
library(utils)
#library(rgdal)
library(maptools)
library(rgeos)
library(rgdal)
library(tools)
library(stringr)
library(utils)
library(zip)
library(logging)
library(dplyr)
library(doBy)
library(R.utils)
library(foreign)
#source("D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\scripts\\r\\course.R")

print("Initializing...")
today <- format(as.Date(Sys.Date()), "%m-%d-%Y")
yesterday <- format(as.Date(Sys.Date() - 1), "%m-%d-%Y")
root.dir   <- "D:/Users/climate_dashboard/Documents/climate_dashboard"
tmp.dir    <- paste(root.dir, "\\data\\tmp", sep="") 
input.dir  <- paste(root.dir, "\\data\\input_files", sep="") 
output.dir <- paste(root.dir, "/data/output_files", sep="") 
seven.day.forecast.max <- paste(output.dir, "/conus_max_temp_forecast_seven_day.tif",sep="")
conus.forecast.temperature.grid1   <- paste(input.dir, "/NDFD/conus/ds.maxt_001-003.bin", sep="")
conus.forecast.temperature.grid2   <- paste(input.dir, "/NDFD/conus/ds.maxt_004-007.bin", sep="")

#logger config
log.filename <- paste(root.dir, "/log/aggregate_NDFD_rasters_to_counties_", today,".log", sep="")

logReset()
basicConfig(level='FINEST')
addHandler(writeToFile, file=log.filename, level='DEBUG')

log.msg <- paste("Stacking grids.",sep="")
loginfo('%s',  log.msg)
conus.forecast.temperature.all.grids <- stack(conus.forecast.temperature.grid1,conus.forecast.temperature.grid2)

log.msg <- paste("Calculating grid max",sep="")
loginfo('%s',  log.msg)
conus.forecast.temperatures.max      <- max(conus.forecast.temperature.all.grids)

log.msg <- paste("Writing ", seven.day.forecast.max, sep="")
loginfo('%s',  log.msg)
writeRaster(x=conus.forecast.temperatures.max,  filename = seven.day.forecast.max,  format="GTiff",overwrite=T)
