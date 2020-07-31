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
library(tidyverse)
library(DescTools)
library(data.table)

#source("D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\scripts\\r\\course.R")
state.fips.lookup.table <- foreign::read.dbf("D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\input_files\\state_fips_lookup_table.dbf")
print("Initializing...")
today <- format(as.Date(Sys.Date()), "%m-%d-%Y")
yesterday <- format(as.Date(Sys.Date() - 1), "%m-%d-%Y")
covid19.github.zip.url <- "https://github.com/CSSEGISandData/COVID-19/archive/master.zip"
root.dir   <- "D:/Users/climate_dashboard/Documents/climate_dashboard"
tmp.dir    <- paste(root.dir, "\\data\\tmp", sep="") 
input.dir  <- paste(root.dir, "\\data\\input_files", sep="") 

conus.counties.sp    <- readOGR(dsn=input.dir, layer="conus_counties_simplified")
conus.counties.sp$STATE_FIPS <- substr(conus.counties.sp$GEOID,1,2)

df <- read.csv("D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\tmp\\COVID-19-master\\csse_covid_19_data\\csse_covid_19_time_series\\time_series_covid19_confirmed_US.csv")
df$FIPS2 <- str_pad(df$FIPS,width = 5,side="left", pad="0")

df2 <- melt(id.vars ="FIPS2" , data= df, measure.vars = c(12:80))
colnames(df2) <- c("FIPS", "date", "confirmed")
df2$date <- as.character(df2$date)
#View(df2)

x.pos <- StrPos(df2[,2],pattern = "X", pos=1 )
df2$date2 <- substr(x=df2[,2], start=x.pos + 1, str_length(df2[,2]))
df2$date2 <- str_replace_all(df2$date2, pattern = "\\.", "-")
df2$date3 <- as.Date(df2$date2, tryFormats ="%m-%d-%Y")
head(df2)

df2$state.fips <- substr(df$FIPS2,1,2)
head(df2)
summary <- doBy::summaryBy(confirmed ~ state.fips + date2, data = df2, FUN=sum)
colnames(summary)[1] <- "FIPS"
summary2 <- dplyr::left_join(summary, state.fips.lookup.table, by="FIPS")

#sp <- ggplot(summary2, aes(x=date2, y=confirmed.sum)) + geom_point(shape=1) + facet_wrap(~NCA4_regio)

dir <- "D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\covid19_time_series"
date.seq <- unique(df2$date3)

for(date in date.seq)
{
  conus.counties.sp <- merge(conus.counties.sp, states.fips.loookup.df, by.x="STATE_FIPS", by.y = "STATE_FIPS")
  
}


