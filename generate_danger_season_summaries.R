#Danger Season 2022 summaries

#run config file
source("D:/UCS_projects/climate_shop/SuperPANCHO/bin/run_config.R")

library(logging)
library(rgdal)
library(sfheaders)
library(config)
library(sf)
library(doBy)
library(xlsx)

ptm <- proc.time()
today <- format(as.Date(Sys.Date()), "%m-%d-%Y")

#logger config
log.filename <- paste(log.dir, "/process_aqi_file_", today,".log", sep="")
logReset()
basicConfig(level='FINEST')
addHandler(writeToFile, file=log.filename, level='DEBUG')
log.msg <- "\n\n----------Process Starting: Generate County-level Danger Season summary"
loginfo('%s', log.msg)


#communities with unprecedented heat
#HI_90plus.df <- ct.danger.season.sf[ct.danger.season.sf$HI_90plus=="yes",]
#summary1.df  <- with(HI_90plus.df, table(STATE, HI_100plus))

counties.nws.sf <- st_read(dsn=output.dir, layer=counties_nws)
#keep all NWS alert columns
counties.nws.df <- st_drop_geometry(counties.nws.sf[,c("GEOID", phenom.export.columns, alert.type.column, alert.url.column)])
counties.sf     <- st_read(dsn=counties.gdb, layer=counties.layer)
counties.sf     <- sp::merge(counties.sf, counties.nws.df, by="GEOID", all.x = TRUE)
cejst.sf        <- st_read(dsn=output.dir, layer=ct.cejst.nri)
cejst.df        <- st_drop_geometry(cejst.sf)
kh.sf           <- st_read(dsn=kh.dsn, layer=kh.shapefile)
kh.df           <- st_drop_geometry(kh.sf)
hi.sf           <- st_read(dsn=output.dir, layer=hi.layer.name)
hi.df           <- st_drop_geometry(hi.sf)
aqi.sf          <- st_read(dsn=output.dir, layer=aqi.tomorrow.forecast.shapefile)
aqi.df          <- st_drop_geometry(aqi.sf)

#calculate county FIPS
ct.danger.season.sf  <- st_read(dsn=output.dir,     layer=ct.danger.season.shapefile)
ct.danger.season.sf$COUNTYFIPS <- substr(ct.danger.season.sf$GEOID, 1, 5)

#summarize CEJST at county level
cejst.county.summary <- (table(ct.danger.season.sf$COUNTYFIPS, ct.danger.season.sf$CEJST_FLAG))
cejst.county.summary.df <- data.frame(GEOID = row.names(cejst.county.summary), 
                                      False = cejst.county.summary[,1],
                                      True  = cejst.county.summary[,2])

cejst.county.summary.df$per.disadvantaged <- round((cejst.county.summary.df$True / (cejst.county.summary.df$True + cejst.county.summary.df$False)) * 100,0)

#join CEJST to counties.sf
counties.sf <- sp::merge(counties.sf, cejst.county.summary.df, by="GEOID")

#join HI forecast to counties.sf
counties.sf <- sp::merge(counties.sf,hi.df[c("GEOID",max.hi.column.from.python)], by="GEOID")
colnames(counties.sf)[which(colnames(counties.sf)==max.hi.column.from.python)] <- max.hi.column.name

#join KH to counties
counties.sf <- sp::merge(counties.sf,kh.df[c("GEOID10", historical.kh.columns, future.kh.columns)], by.x="GEOID", by.y = "GEOID10")

#join AQI to counties
counties.sf <- sp::merge(counties.sf,aqi.df, by.x="GEOID", by.y = "GEOID")

#select counties with HI forecast >=90
#counties.sf <- counties.sf[counties.sf$HI_tmrw>=90,]

#Create unprecented heat indicators
counties.sf$unpre_90   <- "common"
counties.sf$unpre_100  <- "common"
counties.sf$unpre_105  <- "common"
# counties.sf$unpre_90[counties.sf$HI_tmrw  >= 90  & counties.sf$hist_90  < 5] <- "rare"
# counties.sf$unpre_100[counties.sf$HI_tmrw >= 100 & counties.sf$hist_100 < 5] <- "rare"
# counties.sf$unpre_105[counties.sf$HI_tmrw >= 105 & counties.sf$hist_100 < 5] <- "rare"

counties.sf$unpre_90[counties.sf$hist_90   < 5] <- "rare"
counties.sf$unpre_100[counties.sf$hist_100 < 5] <- "rare"
counties.sf$unpre_105[counties.sf$hist_100 < 5] <- "rare"

counties.df          <- st_drop_geometry(counties.sf)

# format for shapefile output ----------------------------------------------------------------------
counties.shp.sf <- counties.sf[,c("GEOID", 
                                    "NAMELSAD", 
                                    "state",
                                    "alert_type",
                                    "URL",
                                    "per.disadvantaged",
                                    mean.aqi.colname,
                                    mean.aqi.category.colname,
                                    max.hi.column.name,
                                    historical.kh.columns,
                                    future.kh.columns,
                                    unprecedented.heat.columns)]

colnames(counties.shp.sf)[which(colnames(counties.shp.sf)=="NAMELSAD")]                  <- "name"
colnames(counties.shp.sf)[which(colnames(counties.shp.sf)=="per.disadvantaged")]         <- "per_dis"
colnames(counties.shp.sf)[which(colnames(counties.shp.sf)=="mean.aqi.colname")]          <- "aqi_val"
colnames(counties.shp.sf)[which(colnames(counties.shp.sf)=="mean.aqi.category.colname")] <- "aqi_desc"
colnames(counties.shp.sf)[which(colnames(counties.shp.sf)=="url")]                       <- "alert_url"

st_write(obj = counties.shp.sf, dsn = output.dir, layer = county.danger.season.shapefile, driver="ESRI Shapefile", delete_layer = T)

# format for spreadsheet output ----------------------------------------------------------------------


counties.excel.df <- counties.df[,c("GEOID", 
                                    "NAMELSAD", 
                                    "state",
                                    "alert_type",
                                    "URL",
                                    "per.disadvantaged",
                                    mean.aqi.colname,
                                    mean.aqi.category.colname,
                                    max.hi.column.name,
                                    historical.kh.columns,
                                    future.kh.columns,
                                    unprecedented.heat.columns)]

#format column names
colnames(counties.excel.df) <- c("County FIPS",
                                 "Name",
                                 "State",
                                 "NWS Alert",
                                 "NWS Alert URL",
                                 "Per. of communities with disadvantaged status",
                                 "Mean AQI (value)",
                                 "Mean AQI (description)",
                                 "Max HI forecast (F)",
                                 "KH hist_90",
                                 "KH hist_100",
                                 "KH hist_105",
                                 future.kh.columns,
                                 unprecedented.heat.columns)


write.xlsx(counties.excel.df, counties.danger.season.excel.filename, 
           sheetName = "county data", 
           col.names = TRUE,
           row.names = TRUE, 
           append = FALSE)

#replicate to Dropbox
write.xlsx(counties.excel.df, counties.danger.season.excel.filename2, 
           sheetName = "county data", 
           col.names = TRUE,
           row.names = TRUE, 
           append = FALSE)



# table(counties.sf$unpre_90)
# table(counties.sf$unpre_100)
# table(counties.sf$unpre_105)
#generate multiple NWS alerts scenario
#sample.state <- "TX"
# sample.state.df <- counties.sf[counties.sf$state==sample.state,]
# t1 = sample(1 : length(unique(phenom.labels)), size = 1, replace = T)
# simulated.alerts <- replicate(n = nrow(sample.state.df)/3 , expr = sample(c(phenom.labels, NA), size= 1) )
# counties.sf$alert_type[counties.sf$state == sample.state] <- simulated.alerts

# #render Rmarkdown report
# render_report = function(.state, .counties.sf) {
#   rmarkdown::render(
#     danger.season.rmd.filename, params = list(
#       .state = .state,
#       .counties.sf = .counties.sf
#     ),
#     output_file = paste0(state.latex.dir, "/", .state, "_report",sep="") #render guesses format from extension. FIX: PDF rendering pandoc error 4.
#   )
# }
# render_report(.state= "CO", .counties.sf=counties.sf)  
# 
# states.list <- c("UT", "CO", "NM", "TX")
# for (state in states.list)
# {
#   render_report(.state=state, .counties.sf=counties.sf)  
# }

