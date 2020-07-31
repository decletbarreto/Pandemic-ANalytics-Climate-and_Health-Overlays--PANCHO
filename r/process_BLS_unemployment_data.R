
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
library(reshape)


root.dir <- "D:/Users/climate_dashboard/Documents/climate_dashboard"
today    <- format(as.Date(Sys.Date()), "%m-%d-%Y")
col.names <- c("LAUS_area_code", "state_fips", "county_fips", "area_title", "period", "civilian_labor_force", "employed", "unemployed_level","unemployed_rate")

#logger config
log.filename <- paste(root.dir, "\\log\\process_bls_unemployment_data_", today,".log", sep="")
logReset()
basicConfig(level='FINEST')
addHandler(writeToFile, file=log.filename, level='DEBUG')
log.msg <- "\n\n----------Process Starting: Process BLS Local Area Unemployment data"
loginfo('%s', log.msg)

bls.url <- "https://www.bls.gov/web/metro/laucntycur14.txt"
tmp.dir    <- paste(root.dir, "/data/tmp", sep="") 
output.dir <- paste(root.dir, "/data/output_files/BLS_unemployment", sep="") 
bls.local.file <- paste(tmp.dir, "/BLS_unemployment/laucntycur14.txt", sep="")

#Download most recent BLS LAU data file
log.msg <- "Downloading most recent BLS Local Area Unemployment data file..."
loginfo('%s', log.msg)
tryCatch(
  expr=
    {
      download.file(url = bls.url,destfile = bls.local.file,mode="wb")
      print("Done.")
    },
  error= function(e)
  {
    log.msg <- paste("Download of ",bls.url, " failed. Exiting",sep="" )
    logerror('%s', log.msg)
    stop()
  }
)

log.msg <- paste("Reading ", bls.local.file, sep="")
loginfo('%s', log.msg)
bls.df <- read.csv(bls.local.file, skip = 6, col.names = col.names, sep="|")

#drop the last 5 rows since those are comments, not data
bls.df <- head(bls.df,-5)

#recode as numeric, dropping the comma 1000s separator
bls.df$civilian_labor_force <- as.numeric(gsub(",", "", bls.df$civilian_labor_force))
bls.df$employed             <- as.numeric(gsub(",", "", bls.df$employed))
bls.df$unemployed_level     <- as.numeric(gsub(",", "", bls.df$unemployed_level))

#cast factor as numeric
bls.df$unemployed_rate <- as.numeric(as.character(bls.df$unemployed_rate))

#build five-digit county FIPS
state.fips.padded  <- str_pad(bls.df$state_fips, 2, side="left", pad ="0")
county.fips.padded <- str_pad(bls.df$county_fips,3, side="left", pad ="0")
bls.df$GEOID       <- paste(state.fips.padded, county.fips.padded, sep="")

#format period as date
#first convert to char from factor
bls.df$period     <- as.character(bls.df$period)
#trim whitespace
bls.df$period     <- str_trim(bls.df$period, side="both")
#now format as date
bls.df$date <- zoo::as.yearmon(bls.df$period, "%b-%y")

unemployed_rate.monthly <- cast(bls.df, formula = GEOID ~ date, value="unemployed_rate")

#TODO export to csv