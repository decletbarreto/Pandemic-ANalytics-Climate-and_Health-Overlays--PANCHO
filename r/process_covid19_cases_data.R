#PROCESS CONUS COVID CASES

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

root.dir   <- "D:/Users/climate_dashboard/Documents/climate_dashboard"
today <- format(as.Date(Sys.Date()), "%m-%d-%Y")
maxhi.dir <- "D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\tmp\\HI_forecast" 

#source("D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\scripts\\r\\course.R")
#logger config
log.filename <- paste(root.dir, "\\log\\process_covid19_cases_data_", today,".log", sep="")
logReset()
basicConfig(level='FINEST')
addHandler(writeToFile, file=log.filename, level='DEBUG')
log.msg <- "\n\n----------Process Starting: Process CONUS COVID-19 cases data"
loginfo('%s', log.msg)

yesterday <- format(as.Date(Sys.Date() - 1), "%m-%d-%Y")
covid19.github.zip.url <- "https://github.com/CSSEGISandData/COVID-19/archive/master.zip"
tmp.dir    <- paste(root.dir, "\\data\\tmp", sep="") 
input.dir  <- paste(root.dir, "\\data\\input_files", sep="") 
output.dir <- paste(root.dir, "/data/output_files/covid_and_temperature", sep="") 
covid19.github.zip.local.file <- paste(tmp.dir, "\\covid19_daily_report_", today, ".zip", sep="")
#the filename of the most current (i.e., named with today's date) covid19 cases csv file
#covid19.cases.filename <- paste(tmp.dir, "\\covid19_daily_report_", today, ".zip", "\\csse_covid_19_data\\csse_covid_19_daily_reports\\", yesterday, ".csv", sep="")
covid19.cases.filename <- paste("COVID-19-master/csse_covid_19_data/csse_covid_19_daily_reports/", yesterday, ".csv", sep="")
shp.extensions = c("dbf", "prj", "sbn", "sbx", "shp", "shx")
states.fips.loookup.df <- read.dbf(paste(input.dir,"/state_fips_lookup_table.dbf",sep=""))
colnames(states.fips.loookup.df)[3] <- "STATE_FIPS"
medicaid.expansion.df <- read.dbf(paste(input.dir,"/medicaid_expansion.dbf",sep=""))
maxhi.current.sp <- foreign::read.dbf(paste(maxhi.dir, "/maxhi_counties_summary.dbf", sep=""))
covid_and_mobility_trends <- foreign::read.dbf("D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\county_level_risk\\county_covid_and_mobility_trends_poly.dbf")

cdc.svi        <- readOGR(dsn=paste(input.dir, "/SVI", sep=""), layer="SVI2016_US_COUNTY")
cdc.svi.fields <- c("FIPS", "EP_POV", "EP_AGE65", "EP_DISABL", "EP_MINRTY", "EP_LIMENG", "RPL_THEME1", "RPL_THEME2", "RPL_THEME3", "RPL_THEME4", "RPL_THEMES")
cdc.svi2       <- cdc.svi[,cdc.svi.fields]



#destination files in local directories

#output files in local directories

#local vars
conus_covid19_cases_counties <- "conus_covid19_cases_counties"
#ancillary files
#county file gdb
log.msg <- "Opening counties shapefile..."
loginfo('%s', log.msg)
conus.counties.sp    <- readOGR(dsn=input.dir, layer="conus_counties_simplified")
conus.counties.sp$STATE_FIPS <- substr(conus.counties.sp$GEOID,1,2)
conus.counties.sp <- merge(conus.counties.sp, states.fips.loookup.df, by.x="STATE_FIPS", by.y = "STATE_FIPS")
conus.counties.sp <- merge(conus.counties.sp, medicaid.expansion.df, by.x="name", by.y = "Location")
conus.counties.sp <- merge(conus.counties.sp, cdc.svi2@data, by.x="GEOID", by.y = "FIPS")

#1.covid19 files
#Download most recent covid19 cases files from GitHub repo
log.msg <- "Downloading most recent covid19 cases files from GitHub repo..."
loginfo('%s', log.msg)
tryCatch(
  expr=
    {
      download.file(url = covid19.github.zip.url,destfile = covid19.github.zip.local.file,mode="wb")
      print("Done.")
    },
  error= function(e)
    {
      log.msg <- paste("Download of ",covid19.github.zip.url, " failed. Exiting",sep="" )
      logerror('%s', log.msg)
      stop()
    }
)

#unzip it
#replace with unzipped csv
covid19.cases.filename <- utils::unzip(covid19.github.zip.local.file, files = covid19.cases.filename, exdir = tmp.dir, overwrite = T)
if(length(covid19.cases.filename)==0)
{
  log.msg <-paste("Updated file for ", today, " not in archive; skipping rest of COVID-19 cases update.",sep="")
  loginfo('%s', log.msg)
  log.msg <- "\n\n----------Process Ending: Process COVID-19 cases data"
  loginfo('%s', log.msg)
  stop()
 
}
log.msg <- paste("Unzipping ", covid19.github.zip.local.file, sep="")
loginfo('%s', log.msg)

#unzip(covid19.github.zip.local.file, files = covid19.cases.filename, exdir = tmp.dir, overwrite = T)
#covid19.cases.filename <- paste("COVID-19-master/csse_covid_19_data/csse_covid_19_daily_reports/", yesterday, ".csv", sep="")

log.msg <- paste("Reading ", covid19.cases.filename, sep="")
loginfo('%s', log.msg)
covid19.df <- read.csv(covid19.cases.filename)

#subset US cases
log.msg <- "Subsetting US cases and padding FIPS column..."
loginfo('%s', log.msg)
conus.covid19.df <- covid19.df[which(covid19.df$Country_Region=="US"),]
#pad FIPS with zero if needed
conus.covid19.df$FIPS <- str_pad(string = conus.covid19.df$FIPS, width=5, side="left", pad = "0")

#join covid19 cases by county
log.msg <- "Joining covid19 cases to counties"
loginfo('%s', log.msg)
conus.covid19.df <- conus.covid19.df[!conus.covid19.df$Admin2=="Doña Ana",]

tryCatch(expr=
           {
             #joining covid19 cases to counties
             confirmed.cases.by.county <- summaryBy(formula = Confirmed ~ FIPS, 
                                                    FUN = c(sum, length),
                                                    data=conus.covid19.df)
             confirmed.deaths.by.county <- summaryBy(formula = Deaths ~ FIPS, 
                                                    FUN = c(sum, length),
                                                    data=conus.covid19.df)
             colnames(confirmed.cases.by.county) <- c("FIPS", "Confirmed", "county.frequency")
             conus.counties.sp <- merge(conus.counties.sp,confirmed.cases.by.county, by.x = "GEOID", by.y = "FIPS")
             
             #join covid and mobility trends data
             rows <- c(4:25)
             conus.counties.sp <- merge(conus.counties.sp,covid_and_mobility_trends[,rows], by.x = "GEOID_dbl", by.y = "GEOID_dbl")
           },
         error= function(e)
         {
           log.msg <- paste("covid cases Join error. Bailing.")
           logerror('%s', log.msg)
           stop()
         }
)

#join max heat index to counties
log.msg <- "Joining daily max and mean heat index forecast to counties"
loginfo('%s', log.msg)
tryCatch(expr=
           {
            #joining daily max heat index to counties
            #first project maxhi to the counties projection
            #maxhi.current.sp.xformed <- spTransform(maxhi.current.sp, CRSobj = crs(conus.counties.sp))
            #intersect maxhi and counties 
            #conus.counties.heat.index.intersect <- raster::intersect(conus.counties.sp,maxhi.current.sp.xformed)
            
            #convert factor to numeric
            #conus.counties.heat.index.intersect@data$MAX_gridcode <- as.numeric(as.character(conus.counties.heat.index.intersect@data$MAX_gridcode)) 
            
            #get maxhi gridcode value by county
            #maxhi.max.by.counties  <- doBy::summaryBy(MAX_gridcode ~ GEOID, data = conus.counties.heat.index.intersect@data, FUN=max, rm.na=T)
            #maxhi.mean.by.counties <- doBy::summaryBy(MAX_gridcode ~ GEOID, data = conus.counties.heat.index.intersect@data, FUN=mean, rm.na=T)
            
            #rename columns to shapefile-friendly names
            #colnames(maxhi.max.by.counties)[2]  <- "maxhi"
            #colnames(maxhi.mean.by.counties)[2] <- "meanhi"
            
            #cast to integer to save space
            #maxhi.max.by.counties$meanhi  <- as.integer(maxhi.max.by.counties$maxhi)
            #maxhi.mean.by.counties$meanhi <- as.integer(maxhi.mean.by.counties$meanhi)
            
            #join back to counties shapefile
            conus.counties.sp <- merge(conus.counties.sp,maxhi.current.sp,  by.x="GEOID_dbl", by.y = "GEOID_dbl") 
            
            #subset counties with
            #HI >=100
            #increasing covid cases trend
            hi.threshold <- 100
            cases.trend <- "increasing"
            conus.counties.sp2 <- conus.counties.sp[conus.counties.sp@data$MAX_gridco >= hi.threshold & conus.counties.sp@data$cases_trnd ==cases.trend, ]
           },
         error= function(e)
         {
           log.msg <- paste("heat index Join error. Bailing.")
           logerror('%s', log.msg)
           stop()
         }
)


tryCatch(expr=
            {
              log.msg <- paste("Writing ",output.dir,"/", conus_covid19_cases_counties, sep="")
              loginfo('%s', log.msg)
              #write final shapefile
              writeOGR(obj=conus.counties.sp,dsn=output.dir,layer=conus_covid19_cases_counties, driver ="ESRI Shapefile",overwrite_layer = T )
              conus_covid19_cases_counties_subset <- "conus_covid19_cases_counties_subset"
              writeOGR(obj=conus.counties.sp2,dsn=output.dir,layer=conus_covid19_cases_counties, driver ="ESRI Shapefile",overwrite_layer = T )
              
              #zip for AGOL update
              conus.covid19.cases.counties.zip.filename <- paste(output.dir,"/", conus_covid19_cases_counties, ".zip",sep="")
              log.msg <- paste("Zipping ",conus.covid19.cases.counties.zip.filename, sep="")
              
              files <- paste(conus_covid19_cases_counties, shp.extensions, sep=".")
              files <- paste(output.dir,"/", files, sep="")
              files
              loginfo('%s', log.msg)
              zip.shapefile.result<- utils::zip(zipfile = conus.covid19.cases.counties.zip.filename, files=files, flags= "-j")
            },
         error = function(e)
         {
           log.msg <- paste("write error. Bailing.")
           logerror('%s', log.msg)
           stop()
         }
)
log.msg <- "\n\n----------Process Ending: Process COVID-19 cases data"
loginfo('%s', log.msg)
#print(proc.time() - ptm)




