rm(list=ls())
#redlining classification of  census tracts
#requires: holc and cjest intersect shapefile
library(logging)
library(rgdal)
library(sf)
library(doBy)

ptm <- proc.time()
today <- format(as.Date(Sys.Date()), "%m-%d-%Y")

#run config file
source("D:/UCS_projects/climate_shop/SuperPANCHO/bin/run_config.R")

#logger config
log.filename <- paste(log.dir, "/process_redlining_data", today,".log", sep="")
logReset()
basicConfig(level='FINEST')
addHandler(writeToFile, file=log.filename, level='DEBUG')
log.msg <- "\n\n----------Process Starting: Process redlining data"
loginfo('%s', log.msg)

#ACS Census Tract GDB
ct.sf             <- sf::st_read(dsn = ct.gdb, layer = ct.layer.name)
#keep only needed columns
ct.sf <- ct.sf[,!(names(ct.sf) %in% ct.cols.to.drop)]

#open HOLC shapefile
holc.sf <- st_read(dsn=holc.dsn, layer= "holc_ad_data_NAD83")
holc.sf <- st_read(dsn=holc.dsn, layer= "holc_ad_data_NAD83")

#project to ct's CRS
holc.sf <- st_transform(x=holc.sf, crs=st_crs(ct.sf))

#intersect census tracts and HOLC polygons
ct.holc.intersect.sf <- st_intersection(ct.sf, holc.sf)

#create area fields for slivers
ct.holc.intersect.sf$sliver.area <- st_area(ct.holc.intersect.sf)
#extract the sliver with the largest area, by census tract GEOID
#first add up the areas of all slivers in the same census tract by HOLC grade
#convert sf to df for summaryBy b/c it doesn't like an sf
ct.holc.intersect.df = as.data.frame(ct.holc.intersect.sf)
summary1.df <- doBy::summaryBy(sliver.area ~ GEOID + holc_grade, data = ct.holc.intersect.df, FUN = sum, na.rm=T)

#then get the HOLC grade with the largest area
#sort by GEOID and area in descending order so max sliver area by GEOID is first
summary1.sorted.df <- summary1.df[order(summary1.df$GEOID, -summary1.df$sliver.area),c("GEOID","holc_grade","sliver.area.sum")]
#now summarize by max sliver area and grab HOLC grade of max area
summary2.df <- doBy::summaryBy(sliver.area.sum ~ GEOID, data = summary1.sorted.df, FUN = max, na.rm=T, id="holc_grade")

write.csv(summary2.df,ct.holc.csv,row.names = F )

#st_write(ct.holc.intersect.sf, dsn=tmp.dir, layer="test", driver = "ESRI Shapefile")








