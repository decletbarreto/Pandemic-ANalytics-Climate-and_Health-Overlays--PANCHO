rm(list=ls())
#process Current NWS warnings shapefile
library(sf)
library(logging)
library(arcpullr)

#run config file
source("D:/UCS_projects/climate_shop/SuperPANCHO/bin/run_config.R")

ptm <- proc.time()
today <- format(as.Date(Sys.Date()), "%m-%d-%Y")

#logger config
log.filename <- paste(log.dir, "/process_wildfires_data", today,".log", sep="")
logReset()
basicConfig(level='FINEST')
addHandler(writeToFile, file=log.filename, level='DEBUG')
log.msg <- "\n\n----------Process Starting: Process Wildfires data"
loginfo('%s', log.msg)

counties.sf <- st_read(dsn = counties.gdb, layer = counties.layer)

#download wildfires warnings
log.msg <- "Downloading current NWS warnings shapefile..."
loginfo('%s', log.msg)
#https://ucsusa.maps.arcgis.com/home/item.html?id=d957997ccee7408287a963600a77f61f#overview
url <-"https://services9.arcgis.com/RHVPKKiFTONKtxq3/ArcGIS/rest/services/USA_Wildfires_v1/FeatureServer/1"
wildfires.rest.sf  <- get_spatial_layer(url)

#project to county CRS
wildfires.rest.sf <- st_transform(x=wildfires.rest.sf, crs=st_crs(counties.sf))

#spatial join of wildfires to counties
#turn off the s2 processing; in your script; in theory the behaviour should revert to the one before release 1.0
sf::sf_use_s2(FALSE) 
counties.wildfires.sj <- st_join(counties.sf, wildfires.rest.sf)

write_sf(counties.wildfires.sj, dsn=tmp.dir, layer="counties_wildfire_sj", driver="ESRI Shapefile", delete_layer = T)



write_sf(wildfires.rest.sf, dsn=tmp.dir, layer=wildfires.shapefile, driver="ESRI Shapefile")
