rm(list=ls())
library("rgdal")
library(logging)
library("ggplot2")
library(viridis)
library(dplyr)
library(plotly)
library(viridis)
library(hrbrthemes)

#assemble all SuperPANCHO shapefiles into one shapefile

ptm <- proc.time()
today <- format(as.Date(Sys.Date()), "%m-%d-%Y")

root.dir   <- "D:/Users/climate_dashboard/Documents/SuperPANCHO"
output.dir <- paste(root.dir, "/data/output", sep="") 
counties.nws.filename <- paste(output.dir,"counties_nws.shp",sep="/")
hi.forecast.filename  <- paste(root.dir,"data/tmp/HI_forecast/maxhi_counties_join_final.shp",sep="/")
counties.filename     <- paste(root.dir,"data/input_files/conus_counties_simplified.shp",sep="/")
aqi.filename          <- paste(root.dir,"data/output/AQI_counties.shp", sep="/")
dropbox.dir           <- "D:/Users/climate_dashboard/Dropbox/SuperPANCHO"
counties.climate.injustice.filename <-  "counties_climate_injustice_indicators"
counties.climate.injustice.points.filename <-  "counties_climate_injustice_indicators_points"
shp.extensions = c("dbf", "prj", "sbn", "sbx", "shp", "shx")

counties.climate.injustice.points.zip.filename <- paste(output.dir, "counties_climate_injustice_indicators_points.zip", sep="/")
counties.climate.injustice.zip.filename        <- paste(output.dir, "counties_climate_injustice_indicators.zip", sep="/")

cdc.vax.filename      <- paste(root.dir, "data/output/counties_vax_rates.shp", sep="/")

cdc.pvi.filename      <- paste(root.dir, "data/output/county_pvi.shp", sep="/")

cejst.filename        <-"D:/Users/climate_dashboard/Documents/climate_dashboard/data/input_files/CEJST/ct2018_cejst"

pvi.column.names <- c("ToxPiScore","HclustGrp","KMeansGrp","Name", "Source", "IR_TrCases", "IR_DsSpred", 
                  "PC_PopMobi","PC_ResDens", "IV_SocDist", "IV_Testing", "HE_PopDemo", "HE_AirPltn",
                  "HE_AgeDist", "HE_CoMorb", "HE_HlthDis", "HE_HospBed","ToxPi_r")
#logger config
log.filename <- paste(root.dir, "/log/process_all_shapefiles_", today,".log", sep="")
logReset()
basicConfig(level='FINEST')
addHandler(writeToFile, file=log.filename, level='DEBUG')
log.msg <- "\n\n----------Process Starting: Process All Shapefiles"
loginfo('%s', log.msg)

#checking that shapefiles exist
all.shapefiles <- c(counties.nws.filename,hi.forecast.filename,counties.filename,aqi.filename)
exist <- unlist(lapply(all.shapefiles,file.exists))
log.msg <- paste(all.shapefiles, exist,sep=":")
loginfo('%s', log.msg)

#open shapefiles
#NWS alerts in counties
log.msg <-"Opening shapefiles..."
loginfo('%s', log.msg)
counties.nws.sp <- readOGR(dsn=dirname(counties.nws.filename), layer=basename(tools::file_path_sans_ext(counties.nws.filename)))
#Heat Index forecast
hi.forecast.sp <- readOGR(dsn=dirname(hi.forecast.filename), layer=basename(tools::file_path_sans_ext(hi.forecast.filename)))
#AQI forecast
aqi.sp <- readOGR(dsn=dirname(aqi.filename), layer=basename(tools::file_path_sans_ext(aqi.filename)))
#counties
counties.sp <- readOGR(dsn=dirname(counties.filename), layer=basename(tools::file_path_sans_ext(counties.filename)))
#CDC COVID-19 vaccination rates
vax.sp <- readOGR(dsn=dirname(cdc.vax.filename), layer=basename(tools::file_path_sans_ext(cdc.vax.filename)))
#CDC PVI data
pvi.sp <- readOGR(dsn=dirname(cdc.pvi.filename), layer=basename(tools::file_path_sans_ext(cdc.pvi.filename)))
pvi.sp <- pvi.sp[,c("GEOID", pvi.column.names)]
#CEJST first version data
#cejst.sp <- readOGR(dsn=dirname(cejst.filename), layer=basename(tools::file_path_sans_ext(cejst.filename)))

#rename Heat Index forecast (MAX_gridco) column
colnames(hi.forecast.sp@data)[which(colnames(hi.forecast.sp@data)=="MAX_gridco")]         <- "MaxHI_tmrw"
colnames(hi.forecast.sp@data)

log.msg <-"Joining shapefiles..."
loginfo('%s', log.msg)

SuperPANCHO.sp <- sp::merge(counties.sp,
                            counties.nws.sp@data[,c("GEOID","alert_type")],
                            by="GEOID",
                            all.x=T,
                            duplicateGeoms=T)
#colnames(counties.nws.sp@data)
nrow(SuperPANCHO.sp@data)
nrow(counties.nws.sp@data)
#View(table(counties.sp$GEOID))
#View(table(counties.nws.sp$GEOID))
colnames(SuperPANCHO.sp@data)

#merge with NWS alerts data
SuperPANCHO.sp <- sp::merge(SuperPANCHO.sp, hi.forecast.sp,  by="GEOID")
colnames(SuperPANCHO.sp@data)
nrow(SuperPANCHO.sp@data)

#merge with AQI data
SuperPANCHO.sp <- sp::merge(SuperPANCHO.sp, aqi.sp,          by="GEOID")
colnames(SuperPANCHO.sp@data)
nrow(SuperPANCHO.sp@data)

#merge with vaccination rates data
SuperPANCHO.sp <- sp::merge(SuperPANCHO.sp, vax.sp,          by.x="GEOID", by.y="FIPS")
colnames(SuperPANCHO.sp@data)
nrow(SuperPANCHO.sp@data)

#merge with CDC PVI data
SuperPANCHO.sp <- sp::merge(SuperPANCHO.sp, pvi.sp@data,          by.x="GEOID", by.y="GEOID", all.x=T, duplicateGeoms=T)
colnames(SuperPANCHO.sp@data)
nrow(SuperPANCHO.sp@data)

#merge with CEJST data
#SuperPANCHO.sp <- sp::merge(SuperPANCHO.sp, pvi.sp@data,          by.x="GEOID", by.y="GEOID", all.x=T, duplicateGeoms=T)
#colnames(SuperPANCHO.sp@data)
#nrow(SuperPANCHO.sp@data)

#remove extra columns that came in from aqi.sp
SuperPANCHO.sp@data <- SuperPANCHO.sp@data[,!names(SuperPANCHO.sp@data) %in% c("coords.x1", "coords.x2")]
colnames(SuperPANCHO.sp@data)
#aqi.counties.sj.droppped <- aqi.counties.sj[,!names(aqi.counties.sj) %in% reporting.area.colnames[c(1,2,3,4,5,6,7,10,11,12,13,14,15,16,17)]]

SuperPANCHO.non.duplicated.sp <- SuperPANCHO.sp[!duplicated(SuperPANCHO.sp$GEOID),]

rgdal::writeOGR(SuperPANCHO.non.duplicated.sp, dsn=output.dir,  layer=counties.climate.injustice.filename, driver = "ESRI Shapefile",overwrite_layer=T)
#copy to Dropbox folder for Mango to monitor
rgdal::writeOGR(SuperPANCHO.non.duplicated.sp, dsn=dropbox.dir, layer=counties.climate.injustice.filename, driver = "ESRI Shapefile",overwrite_layer=T)

#export a CSV version of the sp file with unique GEOIDs
#for counties with multiple alerts, this will get only the first one on the sp object
#non.numeric.columns <- colnames(SuperPANCHO.sp@data)[!(unlist(lapply(X=SuperPANCHO.sp@data, FUN=class))=="numeric")]
#SuperPANCHO.df <- doBy::summaryBy(. ~ GEOID, data=SuperPANCHO.sp@data,FUN=first, keep.names = T, id=non.numeric.columns)
#colnames(SuperPANCHO.df)
#SuperPANCHO.df2 <- dplyr::left_join(SuperPANCHO.df,SuperPANCHO.sp@data)
#write.csv(SuperPANCHO.df,paste(output.dir,"/",counties.climate.injustice.filename,".csv",sep="")  ,row.names = F)
#write.csv(SuperPANCHO.df, paste(dropbox.dir,"/",counties.climate.injustice.filename,".csv",sep=""),row.names = F)
#head(SuperPANCHO.df)
#nrow(SuperPANCHO.df)
#nrow(SuperPANCHO.sp)

#export as points with only the ToxPiScore data column
SuperPANCHO.centroids.sp <- coordinates(SuperPANCHO.sp)
SuperPANCHO.centroids.sp <- SpatialPointsDataFrame(coords=SuperPANCHO.centroids.sp, 
                                                   data=SuperPANCHO.sp@data,
                                                   proj4string=SuperPANCHO.sp@proj4string)
SuperPANCHO.centroids.sp2 <- SuperPANCHO.centroids.sp[!is.na(SuperPANCHO.centroids.sp$alert_type),c("ToxPiScore","ToxPi_r")]
#SuperPANCHO.centroids.sp3 <- SuperPANCHO.centroids.sp2[SuperPANCHO.centroids.sp2$MaxHI_tmrw>0,c("ToxPiScore")]
rgdal::writeOGR(SuperPANCHO.centroids.sp2, dsn=output.dir,  layer=counties.climate.injustice.points.filename, driver = "ESRI Shapefile",overwrite_layer=T)
#copy to Dropbox folder for Mango to monitor
rgdal::writeOGR(SuperPANCHO.centroids.sp2, dsn=dropbox.dir, layer=counties.climate.injustice.points.filename, driver = "ESRI Shapefile",overwrite_layer=T)
#plot(SuperPANCHO.centroids.sp2)
#colnames(SuperPANCHO.non.duplicated.sp@data)

#zip up for AGOL
#polygons
files <- paste(counties.climate.injustice.filename, shp.extensions, sep=".")
files <- paste(output.dir,"/", files, sep="")
zip.shapefile.result<- utils::zip(zipfile = counties.climate.injustice.zip.filename, files=files, flags= "-j")

#points
files <- paste(counties.climate.injustice.points.filename, shp.extensions, sep=".")
files <- paste(output.dir,"/", files, sep="")
zip.shapefile.result<- utils::zip(zipfile = counties.climate.injustice.points.zip.filename, files=files, flags= "-j")

#############################
#create plots
# flood.phenom.types <- c("CF","FA","FF","FL")
# storm.phenom.types <- c("HU","SR","SS","TI")
# heat.phenom.types  <- c("EH","HT")
# fire.phenom.types  <- c("FW")
# 
# flood.phenom.labels <- c("Coastal Flood","Flood","Flash Flood","Flood")
# storm.phenom.labels <- c("Hurricane","Storm","Storm Surge","Inland Tropical Storm")
# heat.phenom.labels  <- c("Excessive Heat", "Heat")
# fire.phenom.labels  <- c("Red Flag")
# 
# flood.phenom.colors <- c("#00ff00","#00ff00", "#00ff00", "#00ff00")
# storm.phenom.colors <- c("black","black","black","black")
# heat.phenom.colors  <- c("#ff7f50","#ff7f50")
# fire.phenom.colors  <- c("#ff1296")
# 
# phenom.types  <- c(flood.phenom.types, storm.phenom.types,heat.phenom.types,fire.phenom.types)
# phenom.labels <- c(flood.phenom.labels, storm.phenom.labels,heat.phenom.labels,fire.phenom.labels)
# phenom.colors <- c(flood.phenom.colors, storm.phenom.colors,heat.phenom.colors,fire.phenom.colors)
# phenom.df     <- data.frame(types = phenom.types, alert_type = phenom.labels, phenom.colors2 = phenom.colors)
# colors2 <- c("#00ff00","#ff7f50", "#00ff00","#ff7f50","#ff1296")
# 
# 
# phenom.colors.sorted <- phenom.colors[order(phenom.labels)]
# phenom.labels[order(phenom.labels)]
# SuperPANCHO.plots.sp <- sp::merge(SuperPANCHO.sp@data,phenom.df, by.x="alert_type", by.y="alert_type")
# 
# data <- SuperPANCHO.plots.sp[SuperPANCHO.plots.sp$MaxHI_tmrw>0 &
#                             !is.na(SuperPANCHO.plots.sp$alert_type),]
# 
# #add all alert types as levels to alert_type
# levels(data$alert_type) <- c(levels(data$alert_type), as.character(phenom.df$alert_type))
# 
# # # Interactive version
# bubble.size.factor <- 2
# bubble.size.breaks <- c(1,2,3)  * bubble.size.factor
# p <- data %>%
#   #mutate(gdpPercap=round(gdpPercap,0)) %>%
#   #mutate(pop=round(pop/1000000,2)) %>%
#   #mutate(lifeExp=round(lifeExp,1)) %>%
#   mutate(ToxPiScore=round(ToxPiScore,1)) %>%
#   # Reorder countries to having big bubbles on top
#   arrange(desc(ToxPiScore)) %>%
#   #mutate(Name = factor(Name, Name)) %>%
# 
#   # prepare text for tooltip
#   mutate(text = paste("County: ", Name, "\nNWS alert:",alert_type, "\nPVI: ", ToxPiScore, sep="")) %>%
# 
#   # Classic ggplot
#   ggplot( aes(x=perVax, y=MaxHI_tmrw, size = ToxPiScore, fill = alert_type, text=text)) +
#   geom_point(alpha=0.7) +
#   scale_size(range = range(bubble.size.breaks), breaks=bubble.size.breaks) +
#   #scale_color_viridis(discrete=TRUE, guide=FALSE) +
#   scale_fill_manual(values=phenom.colors.sorted) +
#   theme_ipsum() +
#   theme(legend.position="none")
# 
# # turn ggplot interactive with plotly
# pp <- ggplotly(p, tooltip="text")
# pp
# 
# 
# #####################################
# #recode ToxPiScore
# data.df$ToxPiScore.recode <- NA
# data.df$ToxPiScore.recode <- cut(data.df$ToxPiScore,
#                      breaks=c(-Inf, 0.3, 0.6, Inf),
#                      labels=c(1,2,3))
# data.df$ToxPiScore.recode <- as.numeric(as.character(data.df$ToxPiScore.recode))
# 
# bubble.size.factor <- 2
# bubble.size.breaks <- c(1,2,3)  * bubble.size.factor
# ggplot(data = data.df,
#        aes(x=perVax, y=MaxHI_tmrw, size=ToxPiScore.recode, fill=alert_type)) +
#   geom_point(alpha=0.5, shape=21, fill=data.df$phenom.colors) +
#   xlab("Percent of the total population fulyl vaccinated") +
#   ylab("Maximum Heat Index forecast for tomorrow") +
#   scale_fill_viridis(discrete=TRUE, guide=FALSE, option="A") +
#   theme_ipsum() +
#   theme(legend.position="right")  +
#   scale_size(range = range(bubble.size.breaks), breaks=bubble.size.breaks)
# 
#   #scale_colour_identity("zone", breaks=color.codes, guide="legend")
# 
# 
# #stats by alert types
# # s <- doBy::summaryBy(perVax + MaxHI_tmrw + ToxPiScore + IR_DsSpred + IR_TrCases~ alert_type, data = data.df, FUN = mean)
# # s
