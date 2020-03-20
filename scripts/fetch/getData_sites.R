# Part 1 of 2020 update (L.Platt)
# Edited version of `getData_siteRecords.R`

# This only goes out to figure out what sites to download data for
# Takes only a few min

# PULLING ACTUAL DATA WAS TAKING FOREVER (>1.5 hrs for just one chunk)
# Therefore, temporarily focused on pulling just 2016 to 2019 and then merging.
startDate <- "2016-01-01"
endDate <- "2019-12-31"

library(dplyr)
library(stringr)
library(data.table)
library(dataRetrieval)
library(lubridate)
library(parallel)

source('scripts/fetch/helperFunctions.R')

#loop over HUC regions
hucs <- str_pad(1:21, width = 2, pad = "0")
setAccess("internal")
allDF <- data.frame()
for(h in hucs) {
  #dataRet call
  hucDF <- select(readNWISdata(huc = h, hasDataTypeCd = "dv", service = "site",
                        seriesCatalogOutput = TRUE, parameterCd = "00060",
                        startDate = startDate, endDate = endDate),
                  agency_cd, site_no, site_tp_cd, station_nm, dec_lat_va, dec_long_va,
                  huc_cd, data_type_cd, parm_cd, begin_date, end_date, count_nu) 
                  
  hucDF <- filter(hucDF, data_type_cd == "dv", parm_cd == "00060")
  
  hucDF <- mutate(hucDF, begin_date = as.character(begin_date), 
                  end_date=as.character(end_date))
  #filter & append
  allDF <- bind_rows(allDF, hucDF)
}

#convert to dates
allDF <- mutate(allDF, begin_date = as.Date(begin_date), 
                end_date = as.Date(end_date),
                dayRange = as.numeric(end_date - begin_date),
                intDaysRecord  = count_nu - 2, #assuming record exists on first and last days
                intDaysAll = end_date - begin_date - 1,
                diff = intDaysAll - intDaysRecord)
# x <- allDF[c(duplicated(allDF$site_no),duplicated(allDF$site_no, fromLast = TRUE)),]
#get sites where ratio days/ years is off
saveRDS(allDF, "cache/allDF.rds")

