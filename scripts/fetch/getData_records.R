# Part 2 of 2020 update (L.Platt)
# Edited version of `getData_siteRecords.R`

# PULLING ACTUAL DATA WAS TAKING FOREVER (>1.5 hrs for just one chunk)
# Therefore, temporarily focused on pulling just 2016 to 2019 and then merging.
startDate <- "2016-01-01"
endDate <- "2019-12-31"

#get # years of record for every site
library(dplyr)
library(stringr)
library(data.table)
library(dataRetrieval)
library(lubridate)
library(parallel)

source('scripts/fetch/helperFunctions.R')

dir.create('chunks',showWarnings = FALSE)

allDF <- readRDS("cache/allDF.rds")

completeSiteDF <- filter(allDF, 
                         diff <= 10,
                         count_nu > 355) #can't have less than 355 days in any non-start/end year
incompleteSiteDF <- filter(allDF, diff > 10)
incompleteSiteDF <- filter(incompleteSiteDF, count_nu >= 355)


#want long df with row for each site/year
#For complete sites, check if start and end years should be counted
longOK <- checkCompleteYears(completeSiteDF)
longOK <- longOK[!duplicated(longOK),]
# fwrite(longOK, file = 'sitesYearsComplete_latLon_355_NEW.csv')

# #need to deal with multiple lines for some sites in allDF
allDF_oneLineSite <- allDF[!duplicated(allDF$site_no),]
longOK_join <- left_join(longOK, allDF_oneLineSite, by = "site_no")

#get data for incomplete sites
#check what sites I already downloaded - save 6000 some sites
dlSites <- checkDownloadedSites('old_chunks')
toDownloadDF <- filter(incompleteSiteDF, !site_no %in% dlSites)
#don't repeat - there are sites with multiple measurement points
toDownloadSites <- unique(toDownloadDF$site_no)

#chunk by 200 sites
reqBks <- seq(1,length(toDownloadSites),by=200)
message(paste("Total sites to download:", length(toDownloadSites)))
for(i in reqBks) { # Takes ~2 hours
  sites <- na.omit(toDownloadSites[i:(i+199)])
  
  fp <- file.path('chunks', paste0('newChunk', i))
  if(file.exists(fp)) {
    print(sprintf("File exists; skipping %s to %s", i, i+199))
  } else {
    print(paste('Starting', i))
    
    all_sites <- tryCatch({
      currentSitesDF <- readNWISdv(siteNumber = sites, parameterCd = "00060",
                                   startDate = startDate, endDate = endDate)
      fwrite(currentSitesDF, file = fp)
    },
    error=function(cond) {
      message("***************Errored on",i,"***********\n")
      return(all_sites)
    })
    print(paste("Finished sites", i, "through", i+199))
  }
  
}

files <- list.files(c('chunks','old_chunks'), full.names = TRUE)
completeFromIncomplete <- data.frame()
for(i in files){
  complete <- yearsFunc(i)
  completeFromIncomplete <- bind_rows(completeFromIncomplete, complete)
}

cl <- makeCluster(4)
allIncompleteYears <- clusterApply(cl, fun = yearsFunc, x = files)
stopCluster(cl)

#reassemble to DF, write
allIncompleteDF <- do.call("bind_rows", allIncompleteYears)
incomplete_lat_lon <- left_join(allIncompleteDF, allDF_oneLineSite, by = "site_no")

fwrite(incomplete_lat_lon, file = "cache/incomplete_lat_lon.csv")
allSites_355 <- bind_rows(longOK_join, incomplete_lat_lon)
fwrite(allSites_355, file = "cache/allSitesYears_updated.csv", quote = TRUE)
