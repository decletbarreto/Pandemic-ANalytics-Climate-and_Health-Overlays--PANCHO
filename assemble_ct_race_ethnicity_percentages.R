#assemble race/ethnicity percentages
#ACS 2018

rm(list=ls())
library(rgdal)
#library(ggplot2)
library(reshape)
library(doBy)
library(plyr)
library(dplyr)
#library(sm)
library(data.table)
library(Hmisc)

#setwd("C:/Users/rama/OneDrive - Union of Concerned Scientists/EJ paper/R")
#source("function_definitions.R", local=TRUE)
output.dir <- "D:/Users/climate_dashboard/Documents/SuperPANCHO/data/output_dir"
input_fc  <- 'D:/Users/climate_dashboard/Documents/SuperPANCHO/data/input_files/Census/ACS_2018_5YR_TRACT.gdb'
ct.race.ethnicity.output.layer <- "ct_race_ethnicity"

ct.sp             <- rgdal::readOGR(dsn=input_fc,   layer = "ACS_2018_5YR_TRACT")
ct.race.ethnicity <- sf::st_read(   dsn = input_fc, layer = "X03_HISPANIC_OR_LATINO_ORIGIN")
ct.poverty        <- sf::st_read(   dsn = input_fc, layer = "X17_POVERTY")

ct.sp            <- sp::merge(ct.sp,  ct.race.ethnicity  , by.x="GEOID_Data", by.y="GEOID")
ct.sp            <- sp::merge(ct.sp, ct.poverty          , by.x="GEOID_Data", by.y="GEOID")
ct.sp            <- sp::merge(ct.sp, states.lookup.table , by.x="STATEFP"   , by.y="fips_text")
#ct.sp             <- ct.sp4

#Rename population columns
#colnames(df)[17] <- "TOTAL_POPULATION"
colnames(ct.sp@data)[which(colnames(ct.sp@data)=="B03002e1")]  <- "TOTPOP"
#colnames(df)[18] <- "HISPANIC_TOTAL_POP"
colnames(ct.sp@data)[which(colnames(ct.sp@data)=="B03002e12")] <- "HISP_POP"
#colnames(df)[19] <- "WHITE_NH_TOTAL_POP"
colnames(ct.sp@data)[which(colnames(ct.sp@data)=="B03002e3")]  <- "WHITE_POP"
#colnames(df)[20] <- "BLACK_NH_TOTAL_POP"
colnames(ct.sp@data)[which(colnames(ct.sp@data)=="B03002e4")]  <- "BLACK_POP"
#colnames(df)[21] <- "NATIVE_NH_TOTAL_POP"
colnames(ct.sp@data)[which(colnames(ct.sp@data)=="B03002e5")]  <- "NATIVE_POP"
#colnames(df)[22] <- "ASIAN_NH_TOTAL_POP"
colnames(ct.sp@data)[which(colnames(ct.sp@data)=="B03002e6")]  <- "ASIAN_POP"
#colnames(df)[23] <- "HIPI_NH_TOTAL_POP"
colnames(ct.sp@data)[which(colnames(ct.sp@data)=="B03002e7")]  <- "HIPI_POP"
#colnames(df)[24] <- "OTHER_NH_TOTAL_POP"
colnames(ct.sp@data)[which(colnames(ct.sp@data)=="B03002e8")]  <- "OTHER_POP"
#colnames(df)[25] <- "TWO_OR_MORE_NH_TOTAL_POP"
colnames(ct.sp@data)[which(colnames(ct.sp@data)=="B03002e9")]  <- "TWOPL_POP"

#generate variables
ct.sp$POP_IN_POVERTY     <- ct.sp$C17002e2 + ct.sp$C17002e3
ct.sp$POP_NOT_IN_POVERTY <- ct.sp$C17002e1 -ct.sp$POP_IN_POVERTY     
ct.sp$PER_POV        <- round(ct.sp$POP_IN_POVERTY / (ct.sp$POP_IN_POVERTY + ct.sp$POP_NOT_IN_POVERTY) * 100,2)

#generate WHITE and NOT_WHITE population variables
ct.sp$NW_POP <-   
  ct.sp@data$HISP_POP   + 
  ct.sp@data$BLACK_POP  + 
  ct.sp@data$NATIVE_POP + 
  ct.sp@data$ASIAN_POP  +
  ct.sp@data$HIPI_POP   + 
  ct.sp@data$OTHER_POP  +
  ct.sp@data$TWOPL_POP

ct.sp$PER_WH         <- round(ct.sp$WHITE_POP  / ct.sp$TOTPOP * 100,2)
ct.sp$PER_NW         <- round(ct.sp$NW_POP     / ct.sp$TOTPOP * 100,2)
ct.sp$PER_HISP       <- round(ct.sp$HISP_POP   / ct.sp$TOTPOP * 100,2)
ct.sp$PER_BLACK      <- round(ct.sp$BLACK_POP  / ct.sp$TOTPOP * 100,2)
ct.sp$PER_NATIVE     <- round(ct.sp$NATIVE_POP / ct.sp$TOTPOP * 100,2)
ct.sp$PER_ASIAN      <- round(ct.sp$ASIAN_POP  / ct.sp$TOTPOP * 100,2)
ct.sp$PER_HIPI       <- round(ct.sp$HIPI_POP   / ct.sp$TOTPOP * 100,2)
ct.sp$PER_OTHER      <- round(ct.sp$OTHER_POP  / ct.sp$TOTPOP * 100,2)
ct.sp$PER_TWOPL      <- round(ct.sp$TWOPL_POP  / ct.sp$TOTPOP * 100,2)

vars <- c("STATEFP","GEOID_Data","COUNTYFP","TRACTCE","GEOID", "NAME","NAMELSAD","TOTPOP", "HISP_POP", "WHITE_POP",
          "BLACK_POP", "NATIVE_POP", "ASIAN_POP","HIPI_POP","OTHER_POP", "TWOPL_POP","PER_NW","PER_HISP","PER_WH",
          "PER_BLACK", "PER_NATIVE", "PER_ASIAN", "PER_HIPI", "PER_OTHER","PER_TWOPL","PER_POV")
writeOGR(obj=ct.sp[,vars], dsn=output.dir, layer=ct.race.ethnicity.output.layer, driver= "ESRI Shapefile", overwrite_layer = T)



