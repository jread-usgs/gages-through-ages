#' Get discharge sites for NWIS
#'
#'@param viz the vizlab object 
process.disch_sites <- function(...){
  library(dplyr)
  sites <- readr::read_csv("cache/allSitesYears.csv") %>% group_by(site_no) %>% 
    # 3/19/2020 - discovered that some sites have more than one HUC code, not sure how that
    # is possible, but filtering to the last one (most recent) for now
    #   E.g. site number `11434500` had huc_cd=="18020129" for year == 2014 and then 
    #     huc_cd `16050101` for year == 2016
    summarize(huc = stringr::str_sub(tail(unique(huc_cd),1), 1L, 2L), 
      # huc = paste(stringr::str_sub(unique(huc_cd)[[1]], 1L, 2L), collapse = "|"),
      dec_lat_va = mean(dec_lat_va), dec_long_va = mean(dec_long_va)) %>% 
    filter(dec_long_va < -65.4) # remove US virgin Islands and other things we won't plot
  
  saveRDS(sites, "cache/disch-sites.rds")
  
}
