rm(list=ls())

today <- format(as.Date(Sys.Date()), "%m-%d-%Y")
today.excel.file.formatted <- format(as.Date(Sys.Date()), "%m_%d_%Y")

SuperPANCHO.root <- "D:/UCS_projects/climate_shop/SuperPANCHO"
input.dir        <- paste(SuperPANCHO.root, "data","input",  sep="/")
output.dir       <- paste(SuperPANCHO.root, "data","output", sep="/")
tmp.dir          <- paste(SuperPANCHO.root, "data","tmp", sep="/")
nws.tmp.dir      <- paste(SuperPANCHO.root, "data", "tmp", "NWS",sep="/")
aqi.tmp.dir      <- paste(SuperPANCHO.root, "data", "tmp", "AQI",sep="/")
log.dir          <- paste(SuperPANCHO.root, "log" , sep="/")
latex.dir        <- paste(SuperPANCHO.root, "latex", sep="/")
state.latex.dir  <- paste(latex.dir, "states", sep="/")
SuperPANCHO.Dropbox.dir <- "F:/Dropbox/SuperPANCHO"

NCA4.CONUS.regions <- c("Southeast","Southwest","Northwest","Northeast","Southeast","Midwest","Northern Great Plains","Southern Great Plains","Northern Great Plains")
CONUS.states       <- state.name[!state.name %in% c("Alaska", "Hawaii")]

# danger season events
#CFLD_AFREQ coastal flooding
#DRGT_AFREQ drought
#HWAV_AFREQ heat wave
#HRCN_AFREQ hurricane
#RFLD_AFREQ riverine flooding
#WFIR_AFREQ wildfire
danger.season.events        <- c("CFLD_AFREQ","DRGT_AFREQ","HWAV_AFREQ","HRCN_AFREQ","RFLD_AFREQ","WFIR_AFREQ")
danger.season.scores        <- c("CFLD_EALS" ,"DRGT_EALS" ,"HWAV_EALS" ,"HRCN_EALS" ,"RFLD_EALS" ,"WFIR_EALS")
danger.season.scores.rating <- c("CFLD_EALR" ,"DRGT_EALR" ,"HWAV_EALR" ,"HRCN_EALR" ,"RFLD_EALR" ,"WFIR_EALR")

cejst.cols         <- c("GEOID10_TRACT", "County.Name","State.Territory","Identified.as.disadvantaged..v0.1.")
nri.cols           <- c("TRACTFIPS",danger.season.scores.rating)
danger.season.cols <- c("GEOID","COUNTYFP","TRACTCE","NAMELSAD", "STATEABBRV","STATEFIPS",danger.season.scores.rating)
#sf.cols.to.drop  <- c("sfg_id","multipolygon_id","polygon_id","linestring_id","x","y")
ct.cols.to.drop   <- c("COUNTYFP","NAME","MTFCC","FUNCSTAT","ALAND","AWATER","INTPTLAT","INTPTLON", "GEOID_Data","Shape_Length","Shape_Area")
mean.aqi.colname  <- "mean_aqi"
mean.aqi.category.colname <- "aqi_cat"
aqi.cols          <- c("GEOID", mean.aqi.colname, mean.aqi.category.colname)
cejst.filename    <- "CEJST/communities-2022-02-18-1217.csv"

#Census Tract GDB
ct.gdb <- paste(input.dir,"Census", "ACS_2019_5YR_TRACT.gdb", sep="/")

#Census Tract layer
#D:\UCS_projects\climate_shop\SuperPANCHO\maps\danger_season.gdb\ACS_2019_5YR_TRACT_simplified_GCS
ct.layer.name <- "ACS_2019_5YR_TRACT_simplified_GCS"

#Other Census GDBs
tlgdb_2015_a_us_nationgeo.gdb <- paste(input.dir,"/Census/tlgdb_2015_a_us_nationgeo.gdb",sep="")
conus.perimeter.sf <- sf::st_read(dsn=tlgdb_2015_a_us_nationgeo.gdb, layer="State_right_shapes_perimeter")

#NRI GDB
nri.gdb   <- paste(input.dir,"NRI","NRI_GDB_CensusTracts.gdb", sep="/")
NRI.layer <- "NRI_CensusTracts"

#counties GDB
counties.gdb <- paste(input.dir, "Census", "tlgdb_2015_a_us_nationgeo.gdb", sep="/")
counties.layer <- "County_clean"

#NWS
nws.current.url <- "https://tgftp.nws.noaa.gov/SL.us008001/DF.sha/DC.cap/DS.WWA/current_all.tar.gz" 
nws.current.zip.local.file <- paste(input.dir,"NWS","current_all_tar.gz", sep="/")
#coastal flood, extreme heat, flood, flash flood, flood, heat, storm, storm surge, inland tropical storm, red flag(fire weather hazard)
flood.phenom.types  <- c("CF","FA","FF","FL")
storm.phenom.types  <- c("HU","SR","SS","TI")
heat.phenom.types   <- c("EH","HT")
fire.phenom.types   <- c("FW")
flood.phenom.labels         <- c("Coastal Flood", "Flood",     "Flash Flood", "Flood")
flood.phenom.export.columns <- c("NWS_CFLOOD",    "NWS_FLOOD", "NWS_FFLOOD",  "NWS_FLOOD")
storm.phenom.labels         <- c("Hurricane","Storm",     "Storm Surge", "Inland Tropical Storm")
storm.phenom.export.columns <- c("NWS_HRCN", "NWS_STORM", "NWS_SSURGE",  "NWS_TSTORM")
heat.phenom.labels          <- c("Excessive Heat", "Heat")
heat.phenom.export.columns  <- c("NWS_EHEAT",      "NWS_HEAT")
fire.phenom.labels          <- c("Red Flag")
fire.phenom.export.columns  <- c("NWS_REDFLG")
phenom.types        <- c(flood.phenom.types, storm.phenom.types,heat.phenom.types,fire.phenom.types)
phenom.labels       <- c(flood.phenom.labels, storm.phenom.labels,heat.phenom.labels,fire.phenom.labels)
phenom.export.columns <-  c(flood.phenom.export.columns, storm.phenom.export.columns,heat.phenom.export.columns,fire.phenom.export.columns)
phenom.df           <- data.frame(types = phenom.types, alert_type = phenom.labels)
nws.extract.cols    <- c("GEOID", "alert_type")  # columns for final NWS alerts shapefile
alert.type.column   <- "alert_type"
nws.drop.cols <- c("state_and_county_fips_code","COUNTYNS","SHAPE_Length", "SHAPE_Area","state_fips","county_state_key","GEOD_lng", "county_area")
alert.url.column <- "URL"

#states lookup table
states.df <- foreign::read.dbf(paste(input.dir, "states_lookup_table.dbf", sep="/"))
states.territories.list <- states.df$abb

#AQI
grib.formatted.date  <- format(as.Date(Sys.Date()), "%y%m%d") #format date for GRIB file naming convention
grib.formatted.date2 <- format(as.Date(Sys.Date()), "%Y%m%d") #format date for GRIB folder naming convention
grib.formatted.year  <- format(as.Date(Sys.Date()), "%Y")     #format date for GRIB file naming convention
url.prefix <- "https://s3-us-west-1.amazonaws.com//files.airnowtech.org/airnow"
aqi.tomorrow.forecast.grib.file  <- paste(url.prefix, "/today", "/US-", grib.formatted.date, "-ForecastTomorrow.grib2", sep="")
#aqi.tomorrow.forecast.grib.file <- paste(url.prefix, "/", grib.formatted.year,"/",grib.formatted.date2, "/US-", grib.formatted.date, "-ForecastTomorrow.grib2", sep="")
aqi.local.file                   <- paste(aqi.tmp.dir,"forecast_tomorrow.grib2",sep="/")
aqi.rounding.factor <- 1

#CEJST
cejst.nri.shapefile <- "ct_cejst_nri" 

#HeatIndex Forecast
hi.layer.name <- paste("maxhi_counties_join_final" )
max.hi.column.name <- "HI_tmrw"
max.hi.column.from.python <- "MAX_gridco"

#Killer Heat
kh.dsn       <- paste(input.dir, "KillerHeat", sep="/")
kh.shapefile <- "county_heat"
kh.columns <- c("hist_90","hist_100","hist_105", "hist_OTC", "mid45_90", "mid45_100", "mid45_105",
                "mid45_OTC", "mid85_90", "mid85_100", "mid85_105", "mid85_OTC", "late45_90","late45_100",
                "late45_105", "late45_OTC", "late85_90","late85_100", "late85_105", "late85_OTC","paris_90",
                "paris_100", "paris_105",  "paris_OTC")
unprecedented.heat.columns <- c("unpre_90","unpre_100", "unpre_105" )
historical.kh.columns <- c("hist_90","hist_100","hist_105")
future.kh.columns     <- c("mid45_90","mid45_100", "mid45_105","mid85_90","mid85_100", "mid85_105" )

target.exceedance.frequency <- 5

#HOLC
holc.csv <- paste(output.dir, "ct_holc.csv", sep="/")


ct.danger.season.cols <- c("GEOID", mean.aqi.colname, mean.aqi.category.colname, unique(phenom.export.columns), "NAMELSAD",    
  "COUNTY", "STATE", "CEJST_FLAG", "CFLD_EALR", "DRGT_EALR", "HWAV_EALR", "HRCN_EALR", "RFLD_EALR",
  "WFIR_EALR", "MAX_gridco", "holc_grade", kh.columns, unprecedented.heat.columns)

#doc - https://docs.airnowapi.org/docs/ReportingAreaInformationFactSheet.pdf
#aqi.reporting.data.url <- "https://s3-us-west-1.amazonaws.com//files.airnowtech.org/airnow/today/reportingarea.dat"
#https://files.airnowtech.org/?prefix=airnow/2022/20220428/
#issue date|valid date|valid time|time zone|record sequence|data type|primary|reporting area|state
#code|latitude|longitude|pollutant|AQI value|AQI category|action day|discussion|forecast source
# reporting.area.colnames <- c("issue_date","valid_date","valid_time","time_zone","record_sequence","data_type","primary","reporting_area",
#                              "state_code","latitude","longitude","pollutant","AQI_value","AQI_category","action_day","discussion","forecast_source")
# #pollutant codes
# ozone.code <- "OZONE"
# pm10.code  <- "PM10"
# pm25.code  <- "PM2.5"
# #alert shapefiles 
# aqi.counties.today.o3.shp   <- "AQI_O3_counties"
# aqi.counties.today.pm10.shp <- "AQI_PM10_counties"
# aqi.counties.today.pm25.shp <- "AQI_PM25_counties"
# aqi.counties.shp            <- "AQI_counties"
# aqi.points.shp              <- "AQI_points"
# aqi.extract.cols            <- c("GEOID", "AQIO3","AQIPM10","AQIPM25")
# aqi.local.file              <- paste(aqi.tmp.dir,"reportingarea.dat",sep="/")


#wildfires
wildfires.rest.url <-"https://services9.arcgis.com/RHVPKKiFTONKtxq3/ArcGIS/rest/services/USA_Wildfires_v1/FeatureServer/1"
wildfires.shapefile <- "wildfires"

#outputs
ct.cejst.nri <- "ct_cejst_nri" #output layer name
counties_nws <- "counties_nws"  #final output shapefile name
county.cji   <- "counties_climate_injustice_indicators" #output layer name
aqi.tomorrow.forecast.shapefile   <- "county_aqi_forecast_tomorrow"
aqi.tomorrow.forecast.grib.raster <- "aqi_forecast_tomorrow"
ct.danger.season.shapefile        <- "ct_danger_season"
county.danger.season.shapefile    <- "county_danger_season"

counties.danger.season.excel.filename <- paste(output.dir, "/county_danger_season/county_danger_season_", today.excel.file.formatted, ".xlsx", sep="")
counties.danger.season.excel.filename2 <- paste(SuperPANCHO.Dropbox.dir, "/county_danger_season/county_danger_season_", today.excel.file.formatted, ".xlsx", sep="")

#latex, knitr
danger.season.rmd.filename <- paste(latex.dir, "danger_season.Rmd", sep="/")

