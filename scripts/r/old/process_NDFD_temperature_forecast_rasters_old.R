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

celsius.to.fahr <- function(temp)
{
  fahr <- (temp * (9/5)) + 32
  fahr
}

print("Initializing...")
today <- format(as.Date(Sys.Date()), "%m-%d-%Y")
yesterday <- format(as.Date(Sys.Date() - 1), "%m-%d-%Y")
covid19.github.zip.url <- "https://github.com/CSSEGISandData/COVID-19/archive/master.zip"
root.dir   <- "\\\\192.168.0.7/datastore3/climate_dashboard"
tmp.dir    <- paste(root.dir, "/data/tmp", sep="") 
input.dir  <- paste(root.dir, "/data/input_files", sep="") 
output.dir <- paste(root.dir, "/data/output_files", sep="") 

covid19.github.zip.local.file <- paste(tmp.dir, "/covid19_daily_report_", today, ".zip", sep="")

#destination files in local directories
conus.forecast.temperature.grid1  <- paste(input.dir, "/NDFD/conus/ds.maxt_001-003.bin", sep="")
conus.forecast.temperature.grid2  <- paste(input.dir, "/NDFD/conus/ds.maxt_004-007.bin", sep="")
conus.max.temp.raster             <- paste(input.dir, "/NDFD/conus/conus_max_forecast_temp.tif", sep="")
conus.extract.raster.filename     <- paste(input.dir, "/NDFD/conus/conus_extract.tif", sep="")
conus_counties_over90F   <- "conus_counties_over90F"
conus_counties_over100F  <- "conus_counties_over100F"
conus_counties_over105F  <- "conus_counties_over105F"

#output files in local directories
conus.forecast.temperature.stack      <- paste(output.dir, "/conus_stack_forecast_temperatures.tif",sep="")
conus.max.forecast.temperature.raster <- paste(output.dir, "/conus_max_forecast_temperatures.tif",sep="")
counties_covid19_and_temperature      <- "counties_covid19_and_temperature"
conus.forecast.first.day.filename  <- paste(output.dir, "/conus_max_temp_forecast_first_day.tif",sep="")
conus.forecast.second.day.filename <- paste(output.dir, "/conus_max_temp_forecast_second_day.tif",sep="")
conus.forecast.third.day.filename  <- paste(output.dir, "/conus_max_temp_forecast_third_day.tif",sep="")

#the filename of the most current (i.e., named with today's date) covid19 cases csv file
covid19.cases.filename <- paste(tmp.dir, "/COVID-19-master/csse_covid_19_data/csse_covid_19_daily_reports/", yesterday, ".csv", sep="")

#local vars
temperature.threshold.90F  <- 32.2222 
temperature.threshold.100F <- 37.7778 
temperature.threshold.105F <- 40.5556 

#ancillary files
#county file gdb
print("Opening counties shapefile...")
conus.counties.sp    <- readOGR(dsn=input.dir, layer="conus_counties_simplified")
print("Done.")
#URLs for most current NDFD files
conus.forecast.temperature.url1 <- "https://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.conus/VP.001-003/ds.maxt.bin"
conus.forecast.temperature.url2 <- "https://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.conus/VP.004-007/ds.maxt.bin"

#1.covid19 files
#Download most recent covid19 cases files from GitHub repo
print("Processing covid19 cases file...")
print("Downloading most recent covid19 cases files from GitHub repo...")
download.file(url = covid19.github.zip.url,destfile = covid19.github.zip.local.file,mode="wb")
print("Done.")

#unzip it
print("Unzipping...")
unzip(covid19.github.zip.local.file, exdir = tmp.dir, overwrite = T)
print("Done.")

print("reading covid19 cases file...")
covid19.df <- read.csv(covid19.cases.filename)
#subset US cases
print("subsetting US cases...")
conus.covid19.df <- covid19.df[covid19.df$Country_Region=="US",]
#pad FIPS with zero if needed
conus.covid19.df$FIPS <- str_pad(string = conus.covid19.df$FIPS, width=5, side="left", pad = "0")

#join covid19 cases by county
print("joining covid19 cases to counties...")
conus.covid19.df <- conus.covid19.df[!conus.covid19.df$Admin2=="Doña Ana",]
conus.counties.sp <- merge(conus.counties.sp, conus.covid19.df, by.x = "GEOID", by.y = "FIPS")
#dir <- paste(covid.output.dir, "\\", "CONUS", sep="")
#writeOGR(obj=conus.covid19.cases.in.counties.join,dsn=dir,layer="conus_covid19_cases_counties", driver ="ESRI Shapefile",overwrite_layer = T )
print("Done.")
print("Finished processing covid19 cases files.")

#2. NDFD raster files
#download NDFD files in binary mode
print("Processing NDFD temperature forecast files...")
print("Downloading latest forecast rasters...")
download.file(conus.forecast.temperature.url1,conus.forecast.temperature.grid1,mode="wb")
download.file(conus.forecast.temperature.url2,conus.forecast.temperature.grid2,mode="wb")
print("Done.")

#open NDFD files
print("Opening NDFD rasters...")
conus.forecast.temperature.grid1.brick <- brick(conus.forecast.temperature.grid1)
conus.forecast.temperature.grid2.brick <- brick(conus.forecast.temperature.grid2)
#create a raster stack from the input raster files
print("Stacking NFDF rasters...")
conus.forecast.temperatures.stack<- raster::stack(c(conus.forecast.temperature.grid1.brick,conus.forecast.temperature.grid2.brick))
print("Writing raster stack to file...")
writeRaster(x=conus.forecast.temperatures.stack,filename=conus.forecast.temperature.stack,format="GTiff",overwrite=T)
print("Done.")

#create empty raster with dimensions of CONUS' NDFD file
conus.raster <- raster(ncol=2145, nrow=1377)
#calculate the max temp for each pixel in the raster stack, i.e., max daily forecast temp over 7-day period
print("Calculating max forecast temperature in pixels in stack...")
conus.forecast.temperatures.max <- max(conus.forecast.temperatures.stack)
#writeRaster(x=conus.max.forecast.temperature.raster,filename=conus.max.raster,format="GTiff",overwrite=T)
#this is basically the zonal stats tool from ArcGIS but in two steps
#first extract raster values in polygons
print("Extracting forecast temperature values in counties...")
conus.extract.values.in.counties <- extract(x=conus.forecast.temperatures.max,y=conus.counties.sp, df=F)
print("Calculating max forecast temperature in counties...")
#now calculate the max for each polygon
conus.max.values.in.counties <- unlist(lapply(conus.extract.values.in.counties, function(x) if (!is.null(x)) max(x, na.rm=TRUE) else NA ))
#put them in a dataframe and also the GEOIDs...
conus.max.values.in.counties.df <- data.frame(max.temp =conus.max.values.in.counties, geoid=conus.counties.sp$GEOID )
#...to join them back to the counties feature class
conus.max.values.in.counties.join <- merge(conus.counties.sp, conus.max.values.in.counties.df, by.x = "GEOID", by.y = "geoid")
#write final temp shapefile
print("Writing shapefile to disk...")
writeOGR(obj=conus.max.values.in.counties.join,dsn=output.dir,layer="counties_covid19_and_temperature", driver ="ESRI Shapefile",overwrite_layer = T )
#zip it
zipfile <- paste(output.dir, "/", counties_covid19_and_temperature, ".zip", sep="")
#delete zip archive if exists
if(file.exists(zipfile))
{
  print("Zip archive exists; deleting.")
  unlink(zipfile)
}

files.to.zip <- list.files(path=output.dir, pattern=paste(counties_covid19_and_temperature, "*",sep=""), full.names = T)
print("Zipping shapefile...")
zip::zipr(zipfile = zipfile, files=files.to.zip)
print("Done.")

#Create rasters of first, second, and third day forecasts
#project to EPSG:3857 -- WGS84 Web Mercator (Auxiliary Sphere)
#needs this projection for AGOL mapping
crs.3857 <- CRS("+init=epsg:3857")

conus.forecast.temperatures.stack2 <- projectRaster(from=conus.forecast.temperatures.stack, crs=crs.3857)
conus.forecast.first.day  <- subset(x = conus.forecast.temperatures.stack2, 1, drop=TRUE)
conus.forecast.first.day  <- raster::calc(conus.forecast.first.day,celsius.to.fahr)
#conus.forecast.first.day  <- projectRaster(from=conus.forecast.first.day, crs=crs.3857)

conus.forecast.second.day <- subset(x = conus.forecast.temperatures.stack2, 2, drop=TRUE)
conus.forecast.second.day <- raster::calc(conus.forecast.second.day,celsius.to.fahr)
#conus.forecast.second.day <- projectRaster(from=conus.forecast.second.day, crs=crs.3857)

conus.forecast.third.day  <- subset(x = conus.forecast.temperatures.stack2, 3, drop=TRUE)
conus.forecast.third.day  <- raster::calc(conus.forecast.third.day,celsius.to.fahr)
#conus.forecast.third.day  <- projectRaster(from=conus.forecast.third.day, crs=crs.3857)

writeRaster(x=conus.forecast.first.day,  filename = conus.forecast.first.day.filename,  format="GTiff",overwrite=T)
writeRaster(x=conus.forecast.second.day, filename = conus.forecast.second.day.filename, format="GTiff",overwrite=T)
writeRaster(x=conus.forecast.third.day,  filename = conus.forecast.third.day.filename,  format="GTiff",overwrite=T)

cellStats(conus.forecast.first.day, stat='mean',  na.rm=TRUE, asSample=TRUE)
cellStats(conus.forecast.second.day, stat='mean', na.rm=TRUE, asSample=TRUE)
cellStats(conus.forecast.third.day, stat='mean',  na.rm=TRUE, asSample=TRUE)

cellStats(conus.forecast.first.day, stat='range',  na.rm=TRUE, asSample=TRUE)
cellStats(conus.forecast.second.day, stat='range', na.rm=TRUE, asSample=TRUE)
cellStats(conus.forecast.third.day, stat='range',  na.rm=TRUE, asSample=TRUE)

# 
# 
#create a shapefile with the outline of counties with 90F max forecast temp
conus.over90F <- conus.max.values.in.counties.join[conus.max.values.in.counties.join$max.temp>=temperature.threshold.90F,]
if(!length(conus.over90F) == 0)
{
  print("Creating shapefile with outline of counties with 90F max forecast temp...")
  conus.over90F.dissolve <- gUnaryUnion(conus.over90F)
  conus.over90F.dissolve <- as(conus.over90F.dissolve,"SpatialPolygonsDataFrame")
  writeOGR(obj=conus.over90F.dissolve,dsn=output.dir,layer=conus_counties_over90F, driver ="ESRI Shapefile",overwrite_layer = T )

  #zip it
  zipfile <- paste(output.dir, "/", conus_counties_over90F, ".zip", sep="")
  #delete zip archive if exists
  if(file.exists(zipfile))
  {
    print("Zip archive exists; deleting.")
    unlink(zipfile)
  }
  files.to.zip <- list.files(path=output.dir, pattern=paste(conus_counties_over90F, "*",sep=""), full.names = T)
  if(!length(files.to.zip)==0)
  {
    print("Zipping shapefile...")
    zip::zipr(zipfile = zipfile, files=files.to.zip)
  }
  else
  {
    print("No 90F exceedances found.")
  }
    print("Done.")
}

#create a shapefile with the outline of counties with 100F max forecast temp
conus.over100F <- conus.max.values.in.counties.join[conus.max.values.in.counties.join$max.temp>=temperature.threshold.100F,]
if(!length(conus.over100F) == 0)
{
  conus.over100F.dissolve <- gUnaryUnion(conus.over100F)
  conus.over100F.dissolve <- as(conus.over100F.dissolve,"SpatialPolygonsDataFrame")
  writeOGR(obj=over100F.dissolve,dsn=output.dir,layer=conus_counties_over100F, driver ="ESRI Shapefile",overwrite_layer = T )

  #zip it
  zipfile <- paste(output.dir, "/", conus_counties_over100F, ".zip", sep="")
  #delete zip archive if exists
  if(file.exists(zipfile))
  {
    print("Zip archive exists; deleting.")
    unlink(zipfile)
  }
  files.to.zip <- list.files(path=output.dir, pattern=paste(conus_counties_over100F, "*",sep=""), full.names = T)
  print("Zipping shapefile...")
  zip::zipr(zipfile = zipfile, files=files.to.zip)
  print("Done.")
}

#create a shapefile with the outline of counties with 105F max forecast temp
conus.over105F <- conus.max.values.in.counties.join[conus.max.values.in.counties.join$max.temp>=temperature.threshold.105F,]
if(!length(conus.over105F) == 0)
{
  conus.over105F.dissolve <- gUnaryUnion(conus.over105F)
  conus.over105F.dissolve <- as(conus.over105F.dissolve,"SpatialPolygonsDataFrame")
  writeOGR(obj=over105F.dissolve,dsn=output.dir,layer=conus_counties_over105F, driver ="ESRI Shapefile",overwrite_layer = T )
}


# Stop the clock
print(proc.time() - ptm)


