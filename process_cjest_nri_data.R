#Process CEJST and NRI data
rm(list=ls())
library(stringr)
library(sp)
library("sf")
library(sfheaders)
library(logging)

#run config file
source("D:/UCS_projects/climate_shop/SuperPANCHO/bin/run_config.R")

ptm <- proc.time()
today <- format(as.Date(Sys.Date()), "%m-%d-%Y")

#logger config
log.filename <- paste(log.dir, "/process_cjest_nri_data_", today,".log", sep="")
logReset()
basicConfig(level='FINEST')
addHandler(writeToFile, file=log.filename, level='DEBUG')
log.msg <- "\n\n----------Process Starting: Process CEJST and NRI data"
loginfo('%s', log.msg)

#0. Open files
#CEJST flat file
cejst.df <- read.csv(paste(input.dir, cejst.filename, sep="/"))
#strip extra characters in GEOID_TRACT field
cejst.df$GEOID10_TRACT <- unlist((str_extract_all(cejst.df$GEOID10_TRACT, '[0-9a-zA-Z ]+')))
#keep only needed columns
cejst.df <- cejst.df[,cejst.cols]
#head(cejst.df)

#ACS Census Tract GDB
ct.sf             <- sf::st_read(dsn = ct.gdb, layer = ct.layer.name)
#keep only needed columns
ct.sf <- ct.sf[,!(names(ct.sf) %in% ct.cols.to.drop)]
head(ct.sf)

#ethnicity
#ct.race.ethnicity <- sf::st_read(dsn = ct.gdb, layer = "X03_HISPANIC_OR_LATINO_ORIGIN")
#poverty
#ct.poverty        <- sf::st_read(dsn = ct.gdb, layer = "X17_POVERTY")
#states lookup table
#states.lookup.table.filename <- paste(input.dir, "state_fips_lookup_table.dbf",sep="/")
#states.lookup.table <- foreign::read.dbf(states.lookup.table.filename)
#states
#states.sf <- st_read(dsn = "D:/Users/climate_dashboard/Documents/climate_dashboard/data/tlgdb_2015_a_us_nationgeo.gdb", layer = "State_right_shapes")

#FEMA NRI
nri.sf  <- sf::st_read(dsn = nri.gdb, layer = NRI.layer)
#select only necessary columns
nri.sf  <- nri.sf[,nri.cols]
#colnames(nri.sf)
nri.df  <- as.data.frame(nri.sf)

#counties
counties.sf <- st_read(dsn = counties.gdb, layer = counties.layer)
#counties.sf <- merge(counties.sf, states.lookup.table, by.x="state",by.y = "State" )

#1. join CJEST flat file to CT shapefile
ct.sf2 <- sp::merge(ct.sf,  cejst.df  , by.x="GEOID", by.y="GEOID10_TRACT", all.x=T)
nrow(ct.sf2)
head(ct.sf2)

#2. join FEMA NRI file to CT shapefile
ct.sf2 <- sp::merge(ct.sf2,  nri.df , by.x="GEOID", by.y="TRACTFIPS", all.x=T)
#View(colnames(ct.sp2@data))
nrow(ct.sf2)
head(ct.sf2)

#3. join states lookup table to CT shapefile
#ct.sf3 <- sp::merge(ct.sf2,  states.lookup.table , by.x="STATEFP", by.y="FIPS", all.x=T)
#nrow(ct.sf2)

#keep only CONUS geographies - DEPRECATED
#ct.sf2 <- ct.sf2[ct.sf2$NCA4_regio %in% NCA4.CONUS.regions,]
#View(colnames(ct.sf5))

#ct.extract.df <- sf_to_df(ct.sf2,fill=T)
#drop geometry columns from sf_to_df 
#ct.extract.sf <- ct.sf2[,!(names(ct.sf2) %in% sf.cols.to.drop)]

colnames(ct.sf2)[which(colnames(ct.sf2)=="County.Name")]                        <- "COUNTY"
colnames(ct.sf2)[which(colnames(ct.sf2)=="Identified.as.disadvantaged..v0.1.")] <- "CEJST_FLAG"
colnames(ct.sf2)[which(colnames(ct.sf2)=="State.Territory")]                    <- "STATE"
colnames(ct.sf2)[which(colnames(ct.sf2)=="COUNTY_FIPS")]                        <- "COUNTYFIPS"

st_write(obj=ct.sf2, dsn=output.dir, layer=ct.cejst.nri, driver="ESRI Shapefile", delete_layer = T)
#csv.output <- paste(output.dir, "ct_cejst_nri.csv", sep="/")
#drop.cols <- c("sfg_id", "multipolygon_id", "polygon_id","linestring_id","x","y")
#ct.extract.df <-ct.extract.df[,!(names(ct.extract.df) %in% drop.cols)]
#write.csv(ct.extract.df, csv.output, row.names = F)

log.msg <- "\n\n----------Process Ending: Process CEJST and NRI data"
loginfo('%s', log.msg)
print(proc.time() - ptm)


