# Combine the old allSitesYears file from JRead's zip folder with the
# one built using only 2016 to 2019

# Create new updated data by running `getData_sites.R` and then `getData_records.R`

data_old <- readr::read_csv("cache/allSitesYears_old.csv") %>% select(-nDays) %>% unique()
data_new <- readr::read_csv("cache/allSitesYears_updated.csv") %>% unique()

# Including "begin_date" as one of the identifiers since there seem to be 
#   unique streams of data with different begin dates
data_old_identifiers <- select(data_old, site_no, year, data_type_cd, parm_cd, begin_date)

# The data below are data that DO NOT appear in the new data, so we should keep them
data_old_identifiers_keep <- anti_join(data_old_identifiers, data_new)
data_old_keep <- left_join(data_old_identifiers_keep, data_old)
data_combined <- bind_rows(data_old_keep, data_new)
summary(data_combined)

write.csv(data_combined, file = "cache/allSitesYears.csv", row.names = FALSE)

# Then run these fxns:
# JRead instructions here: https://github.com/USGS-VIZLAB/gages-through-ages/issues/108
source("scripts/process/disch_sites.R")
process.disch_sites() # creates "cache/disch-sites.rds"

source("scripts/process/process_map.R")
process.site_map() # creates "cache/site-map.rds"
sm <- readRDS("cache/site-map.rds")

source("scripts/process/process_year-json.R")
process.year_json() # creates "cache/year-data.json"
# file.copy(from = "cache/year-data.json", "target/data/year-data.json")

source("scripts/process/process_bar_chart.R")
process.bar_chart() # creates "cache/bar-data.xml"

# This visualize step needs the cache/ directory to have static
# the static files cache/state-map.rds & cache/watermark.rds, and
# rebuilt files cache/site-map.rds & cache/bar-data.xml
# On 3/20/2020, Lindsay sent Marty cache/site-map.rds & cache/bar-data.xml & cache/year-data.json
source("scripts/visualize/visualize-map.R")
visualize.states_svg()
