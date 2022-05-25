#Danger Season 2022
rm(list=ls())
library(logging)
library(rgdal)
library(sfheaders)
library(config)
library(sf)

ptm <- proc.time()
today <- format(as.Date(Sys.Date()), "%m-%d-%Y")

#run config file
source("D:/UCS_projects/climate_shop/SuperPANCHO/bin/run_config.R")

#logger config
log.filename <- paste(log.dir, "/assemble_danger_season_2022_shapefile_", today,".log", sep="")
logReset()
basicConfig(level='FINEST')
addHandler(writeToFile, file=log.filename, level='DEBUG')
log.msg <- "\n\n----------Process Starting: Assemble Danger Season 2022 shapefile"
loginfo('%s', log.msg)

######open shapefiles
log.msg <- "opening shapefiles..."
loginfo('%s', log.msg)
ct.sf  <- st_read(dsn=ct.gdb,     layer=ct.layer.name)
ct.df  <- as.data.frame(ct.sf)
aqi.sf <- st_read(dsn=output.dir, layer=aqi.tomorrow.forecast.shapefile)
aqi.df <- as.data.frame(aqi.sf)
nws.sf <- st_read(dsn=output.dir, layer=counties_nws)
nws.df <- as.data.frame(nws.sf)
cejst.sf <- st_read(dsn=output.dir, layer=ct.cejst.nri)
cejst.df <- as.data.frame(cejst.sf)
hi.sf    <- st_read(dsn=output.dir, layer=hi.layer.name)
kh.sf    <- st_read(dsn=kh.dsn, layer=kh.shapefile)
holc.df  <- read.csv(holc.csv)

log.msg <- "Done."
loginfo('%s', log.msg)

log.msg <- "Padding GEOID..."
loginfo('%s', log.msg)
holc.df$GEOID <- stringr::str_pad(holc.df$GEOID, 11,side="left", pad="0")

#join AQI to CT
log.msg <- "Joining AQI to CT..."
loginfo('%s', log.msg)
#ct.sf2 <- sp::merge(ct.sf,aqi.df, by.x = "COUNTY_FIPS",by.y = "GEOID",all.x=T)
ct.df2  <- dplyr::left_join(ct.df,aqi.df, by = c("COUNTY_FIPS" = "GEOID"))
paste("Rows: ", nrow(ct.df2), sep="")

#join NWS to CT
#exclude geometry column from y so merge doesn't freak out
#ct.sf3 <- sp::merge(ct.sf2,nws.df[,c("GEOID", "alert_type")], by.x = "COUNTY_FIPS", by.y = "GEOID", all.x=F )
log.msg <- "Joining NWS to CT..."
loginfo('%s', log.msg)
ct.df3 <- dplyr::left_join(ct.df2, nws.df, by=c("COUNTY_FIPS" = "GEOID"))
paste("Rows: ", nrow(ct.df3), sep="")

#join CEJST/NRI to CT
#exclude geometry column from y so merge doesn't freak out
#ct.sf3 <- sp::merge(ct.sf3,cejst.df[,c("COUNTYFIPS", "CEJST_FLAG", danger.season.scores.rating)], by.x = "COUNTY_FIPS",by.y = "COUNTYFIPS" )
log.msg <- "Joining CEJST/NRI to CT..."
loginfo('%s', log.msg)
ct.df4 <- dplyr::left_join(ct.df3, cejst.df, by=c("GEOID" = "GEOID"))
paste("Rows: ", nrow(ct.df4), sep="")

#join Heat Index to CT
log.msg <- "Joining Heat Index to CT..."
loginfo('%s', log.msg)
ct.df5 <- dplyr::left_join(ct.df4, hi.sf, by=c("COUNTY_FIPS" = "GEOID"))
paste("Rows: ", nrow(ct.df5), sep="")

#join Killer Heat to CT
log.msg <- "Joining Killer Heat to CT..."
loginfo('%s', log.msg)
ct.df6 <- dplyr::left_join(ct.df5, kh.sf, by=c("COUNTY_FIPS" = "GEOID10"))
paste("Rows: ", nrow(ct.df6), sep="")

#join HOLC  data CT
log.msg <- "Joining HOLC to CT..."
loginfo('%s', log.msg)
ct.df7 <- dplyr::left_join(ct.df6, holc.df, by=c("GEOID" = "GEOID"))
paste("Rows: ", nrow(ct.df7), sep="")

#SIIMULATE HEAT
#ct.df7$MAX_gridco <- ct.df7$MAX_gridco + 15

#unprecedented HI forecast indicators
#add columns to df, init to 0
log.msg <- "Calculating unprecedented HI forecast indicators..."
loginfo('%s', log.msg)
ct.df7[,unprecedented.heat.columns[1]]  <- 0
ct.df7[,unprecedented.heat.columns[2]]  <- 0
ct.df7[,unprecedented.heat.columns[3]]  <- 0
ct.df7[,unprecedented.heat.columns[1]][ct.df7$MAX_gridco >= 90  & ct.df7$hist_90  < target.exceedance.frequency] <- 1
ct.df7[,unprecedented.heat.columns[2]][ct.df7$MAX_gridco >= 100 & ct.df7$hist_100 < target.exceedance.frequency] <- 1
ct.df7[,unprecedented.heat.columns[3]][ct.df7$MAX_gridco >= 105 & ct.df7$hist_105 < target.exceedance.frequency] <- 1

#recode NA in NWS alerts to zero
log.msg <- "Recode NA in NWS alerts to zero..."
loginfo('%s', log.msg)
for(col in phenom.export.columns)
{
  ct.df7[[col]][is.na(ct.df7[[col]])] <- 0
}

ct.df.final <- ct.df7[,ct.danger.season.cols]
colnames(ct.df.final)
#class(ct.df.final[,col])
#rename HI column for shapefile export
#doing this here b/c HI processing is done in python
log.msg <- "Renaming HI column for shapefile export..."
loginfo('%s', log.msg)
colnames(ct.df.final)[which(colnames(ct.df.final)==max.hi.column.from.python)] <- max.hi.column.name

#subset CONUS only
log.msg <- "Subsetting CONUS only..."
loginfo('%s', log.msg)
ct.df.final <- ct.df.final[ct.df.final$STATE %in% CONUS.states,]

#round and convert decimal data types
log.msg <- "Rounding and converting decimal data types..."
loginfo('%s', log.msg)
for (col in c(kh.columns, phenom.export.columns, unprecedented.heat.columns, mean.aqi.colname))
{
  print(col)
  ct.df.final[,col] <- as.integer(round(ct.df.final[,col],0))
}

#join back to ct.sp
log.msg <- "Joining back to CT shapefile..."
loginfo('%s', log.msg)
ct.sf.final <- sp::merge(ct.sf[,"GEOID"], ct.df.final, by.x = "GEOID", by.y = "GEOID")
nrow(ct.sf.final)
st_write(obj=ct.sf.final, dsn=output.dir, layer=ct.danger.season.shapefile, driver="ESRI Shapefile", delete_layer = T)

#range(ct.df.final[,col])
#r <- as.integer(round(ct.df.final[,col],0)) 

#NWS and HI stats
#s1.df <- doBy::summary_by(phenom.export.columns[1], data=ct.sf.final, FUN=mean, na.rm=T)

log.msg <- "\n\n----------Process Ending: Assemble CT Danger Season Shapefile"
loginfo('%s', log.msg)
#print(proc.time() - ptm)

