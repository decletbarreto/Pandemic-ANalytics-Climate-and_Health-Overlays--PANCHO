rm(list=ls())
library(rgdal)

ptm <- proc.time()
today <- format(as.Date(Sys.Date()), "%m-%d-%Y")

#run config file
source("D:/UCS_projects/climate_shop/SuperPANCHO/bin/run_config.R")

natl.grids <- readRDS(file = paste(input.dir, "/wildfires/national_grid.RDS", sep=""))
smoke.df   <- readRDS(file = paste(input.dir, "/wildfires/results_all.RDS", sep=""))

#year is a factor with year levels
years.range <- as.numeric(levels(smoke.df$year))

smoke.split.df        <- split(smoke.df, smoke.df$year)
prediction.columns    <- c("preds", "preds0")
smoke.columns.yearly  <- unlist(lapply("smoke", sep="_",FUN = paste, collapse=" ", ...=years.range))
smoke.columns.yearly  <- strsplit(smoke.columns.yearly, split = " ")[[1]]

#preds.columns.yearly2 <- stringr::str_split(preds.columns.yearly, " ") 


  
#all.df <- data.frame()
curr.df <- smoke.split.df[[1]]
all.df <- data.frame(id = curr.df[,"id"])
i <- 1
for (i in 1:length(smoke.split.df))
{
    curr.df <- smoke.split.df[[i]]
    curr.df <- curr.df[,c("id", "smoke")]
    colnames(curr.df)[2] <- smoke.columns.yearly[i]
    all.df <- dplyr::left_join(all.df, curr.df, by="id")
    i <- i + 1
}
#head(all.df)

#merge smoke data with grids
natl.grids2 <- sp::merge(natl.grids, all.df, by="id")

#write grids to shapefile
colnames(natl.grids2@data)[7] <- "physio_sec"
colnames(natl.grids2@data)[8] <- "physio_reg"
writeOGR(natl.grids2, dsn= tmp.dir, layer="county_wildfire_smoke", driver="ESRI Shapefile", overwrite_layer = T)
