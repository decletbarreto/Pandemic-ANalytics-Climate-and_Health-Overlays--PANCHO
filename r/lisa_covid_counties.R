rm(list=ls())

library(elsa)
library(rgdal)
library(spdep)
library(stringr)
library(ggplot2)
library(maps)
library(xtable)

#Bivariate Moran's I
moran_I <- function(x, y = NULL, W){
  if(is.null(y)) y = x
  
  xp <- (x - mean(x, na.rm=T))/sd(x, na.rm=T)
  yp <- (y - mean(y, na.rm=T))/sd(y, na.rm=T)
  W[which(is.na(W))] <- 0
  n <- nrow(W)
  
  global <- (xp%*%W%*%yp)/(n - 1)
  local  <- (xp*W%*%yp)
  
  list(global = global, local  = as.numeric(local))
}

# Permutations for the Bivariate Moran's I
simula_moran <- function(x, y = NULL, W, nsims = 1000){
  
  if(is.null(y)) y = x
  
  n   = nrow(W)
  IDs = 1:n
  
  xp <- (x - mean(x, na.rm=T))/sd(x, na.rm=T)
  W[which(is.na(W))] <- 0
  
  global_sims = NULL
  local_sims  = matrix(NA, nrow = n, ncol=nsims)
  
  ID_sample = sample(IDs, size = n*nsims, replace = T)
  
  y_s = y[ID_sample]
  y_s = matrix(y_s, nrow = n, ncol = nsims)
  y_s <- (y_s - apply(y_s, 1, mean))/apply(y_s, 1, sd)
  
  global_sims  <- as.numeric( (xp%*%W%*%y_s)/(n - 1) )
  local_sims  <- (xp*W%*%y_s)
  
  list(global_sims = global_sims,
       local_sims  = local_sims)
}

base.dir <- "D:\\Users\\climate_dashboard\\Documents\\coronavirus_response\\geostatistical_analysis"
counties.Q1.swm.filename<- paste(base.dir, "\\conus_covid19_cases_counties_Q1.gal", sep="")
covid.df <- readOGR(dsn=paste(base.dir, "\\data", sep=""), layer = "conus_covid19_cases_counties")
states.df <- st_as_sf(readOGR(dsn="\\\\192.168.0.7\\datastore4\\Census\\tlgdb_2015_a_us_nationgeo.gdb", layer="State"))
#counties.Q1.swm <- read.gal(counties.Q1.swm.filename, region.id = covid.df$GEOID)
conus.states <- as.character(unique(covid.df$State))
states.df <- states.df[states.df$STUSPS %in% conus.states,]

#spatial weights matrix object
nb <- poly2nb(covid.df)
lw <- nb2listw(nb, style = "B", zero.policy = T)
W  <- as(lw, "symmetricMatrix")
W  <- as.matrix(W/rowSums(W))
W[which(is.na(W))] <- 0

create.lisa.map <- function(df, x.name, y.name, W, title="title")
{
  counties.borders <- map_data("county")
  
  df <- as.data.frame(df)
  x <- df[,x.name]
  y <- df[,y.name]
  
  m   <- moran_I(x, y, W)
  #m[[1]] # global value
  
  m_i <- m[[2]]  # local values
  
  local_sims <- simula_moran(x, y, W)$local_sims
  
  # Identifying the significant values 
  alpha <- .05  # for a 95% confidence interval
  probs <- c(alpha/2, 1-alpha/2)
  intervals <- t( apply(local_sims, 1, function(x) quantile(x, probs=probs)))
  sig        <- ( m_i < intervals[,1] )  | ( m_i > intervals[,2] )
  
  #======================================================
  # Preparing for plotting
  
  conus.counties     <- st_as_sf(covid.df)
  conus.counties$sig <- sig
  
  # Identifying the LISA patterns
  xp <- (x-mean(x))/sd(x)
  yp <- (y-mean(y))/sd(y)
  
  patterns <- as.character( interaction(xp > 0, W%*%yp > 0) ) 
  patterns <- patterns %>% 
    str_replace_all("TRUE","High") %>% 
    str_replace_all("FALSE","Low")
  patterns[conus.counties$sig==0] <- "Not significant"
  conus.counties$patterns <- patterns
  conus.counties.borders <- conus.counties[conus.counties$patterns != "Not significant",]
  
  
  lisa.maps.dir <- paste(base.dir, "\\lisa_maps", sep="")
  title.formatted <- str_replace_all(title, " ", "_")
  #title.formatted <- str_replace_all(title, "-", "_")
  
  #pdf.filename <- paste(lisa.maps.dir, "\\", title.formatted, ".pdf", sep="")
  jpeg.filename <- paste(lisa.maps.dir, "\\", title.formatted, ".jpg", sep="")
  
  if(file.exists(jpeg.filename))
  {
    file.remove(jpeg.filename)
  }
  
  #pdf(pdf.filename, width=8.5, height=11, paper="USr")
  jpeg(filename = jpeg.filename,height = 8.5, width=11, units="in", res=300)
  # Plotting
  plot1 <- ggplot() + geom_sf(data=conus.counties, aes(fill=patterns), color="NA") +
    scale_fill_manual(values = c("red", "pink", "#9696FF", "#0000FF", "grey95")) + 
    theme_minimal() +
    geom_sf(data = conus.counties.borders,fill = NA, colour = "black", size=0.3) + 
    geom_sf(data = states.df, aes(fill = NA), colour = "black", size = 0.5) + ggtitle(title)
  print(plot1)
  #ggsave(jpeg.filename, width = 8.5, height=11, units="in", scale=1.5)
  dev.off()
}

# x is a matrix containing the data
# method : correlation method. "pearson"" or "spearman"" is supported
# removeTriangle : remove upper or lower triangle
# results :  if "html" or "latex"
# the results will be displayed in html or latex format
corstars <-function(x, method=c("pearson", "spearman"), removeTriangle=c("upper", "lower"),
                    result=c("none", "html", "latex")){
  #Compute correlation matrix
  require(Hmisc)
  x <- as.matrix(x)
  correlation_matrix<-rcorr(x, type=method[1])
  R <- correlation_matrix$r # Matrix of correlation coeficients
  p <- correlation_matrix$P # Matrix of p-value 
  
  ## Define notions for significance levels; spacing is important.
  mystars <- ifelse(p < .0001, "****", ifelse(p < .001, "*** ", ifelse(p < .01, "**  ", ifelse(p < .05, "*   ", "    "))))
  
  ## trunctuate the correlation matrix to two decimal
  R <- format(round(cbind(rep(-1.11, ncol(x)), R), 2))[,-1]
  
  ## build a new matrix that includes the correlations with their apropriate stars
  Rnew <- matrix(paste(R, mystars, sep=""), ncol=ncol(x))
  diag(Rnew) <- paste(diag(R), " ", sep="")
  rownames(Rnew) <- colnames(x)
  colnames(Rnew) <- paste(colnames(x), "", sep="")
  
  ## remove upper triangle of correlation matrix
  if(removeTriangle[1]=="upper"){
    Rnew <- as.matrix(Rnew)
    Rnew[upper.tri(Rnew, diag = TRUE)] <- ""
    Rnew <- as.data.frame(Rnew)
  }
  
  ## remove lower triangle of correlation matrix
  else if(removeTriangle[1]=="lower"){
    Rnew <- as.matrix(Rnew)
    Rnew[lower.tri(Rnew, diag = TRUE)] <- ""
    Rnew <- as.data.frame(Rnew)
  }
  
  ## remove last column and return the correlation matrix
  Rnew <- cbind(Rnew[1:length(Rnew)-1])
  if (result[1]=="none") return(Rnew)
  else{
    if(result[1]=="html") print(xtable(Rnew), type="html")
    else print(xtable(Rnew), type="latex") 
  }
} 


title <- "Percent COVID19 cases vs Percent Not White"
create.lisa.map(df = covid.df, x.name = "per_confir", y="EP_MINRTY", W=W, title=title)

title <- "Percent COVID19 cases vs Percent Uninsured"
create.lisa.map(df = covid.df, x.name = "per_confir", y="EP_UNINSUR", W=W, title=title)

title <- "Percent COVID19 cases vs Percent in Poverty"
create.lisa.map(df = covid.df, x.name = "per_confir", y="EP_POV", W=W, title=title)

title <- "Percent COVID19 cases vs Percent 65 Years or Older"
create.lisa.map(df = covid.df, x.name = "per_confir", y="EP_AGE65", W=W, title=title)

title <- "Percent COVID19 cases vs Per Capita Income"
create.lisa.map(df = covid.df, x.name = "per_confir", y="E_PCI", W=W, title=title)


#CDc SVI
#
#Socioeconomic - RPL_THEME1
#Household Composition & Disability - RPL_THEME2
#Minority Status & Language - RPL_THEME3
#Housing & Transportation - RPL_THEME4

title <- "Percent COVID19 cases vs Socio-economic Vulnerability"
create.lisa.map(df = covid.df, x.name = "per_confir", y="SPL_THEME1", W=W, title=title)

title <- "Percent COVID19 cases vs Household Composition & Disability Vulnerability"
create.lisa.map(df = covid.df, x.name = "per_confir", y="SPL_THEME2", W=W, title=title)

title <- "Percent COVID19 cases vs Minority Status & Language Vulnerability "
create.lisa.map(df = covid.df, x.name = "per_confir", y="SPL_THEME3", W=W, title=title)

title <- "Percent COVID19 cases vs Housing & Transportation Vulnerability"
create.lisa.map(df = covid.df, x.name = "per_confir", y="SPL_THEME4", W=W, title=title)

title <- "Percent COVID19 cases vs Overall Vulnerability"
create.lisa.map(df = covid.df, x.name = "per_confir", y="SPL_THEMES", W=W, title=title)

# df =covid.df
# x.name = "per_confir"
# y.name="EP_MINRTY"
# W=W

# covid.ses.df <- covid.df@data[,c("per_confir","EP_MINRTY","EP_UNINSUR","EP_POV", "E_PCI","MedcdXp", "name" )]
# #corstars(covid.ses.df, "spearman",removeTriangle = "upper")
# 
# ggplot(covid.ses.df, aes(x=per_confir, y=EP_MINRTY)) +
#   geom_point(size=2, shape=23) + 
#   facet_wrap( ~ name)
# 
# ggplot(covid.ses.df, aes(x=per_confir, y=E_PCI)) +
#   geom_point(size=2, shape=23) + 
#   facet_wrap( ~ name)

