

# Run this script to download the John Hopkins COVID-19 dataset -----------
# Source: COVID-19 Data Repository by the Center for Systems Science and 
    # Engineering (CSSE) at Johns Hopkins University
# https://github.com/CSSEGISandData/COVID-19
# See the github page for a full list of sources

require(glue)
require(purrr)

ghpath <- "https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series"

fns <- glue::glue("time_series_covid19_{x}.csv",
                  x = c("confirmed_US",
                        "deaths_US"))

urls <- glue::glue("{ghpath}/{fns}")

purrr::walk2(urls, fns, download.file)



# Run this code to cleanup the raw data -----------------------------------

require(readr)
require(dplyr)
require(tidyr)
require(lubridate)

col.info <- cols(
    .default = col_double(),
    UID = col_character(),
    iso2 = col_factor(),
    iso3 = col_factor(),
    iso3 = col_factor(),
    FIPS = col_integer(),
    Admin2 = col_character(),
    Province_State = col_character(),
    Country_Region = col_factor(),
    Combined_Key = col_character()
)

cases <- read_csv("time_series_covid19_confirmed_US.csv", col_types = col.info)
deaths <- read_csv("time_series_covid19_deaths_US.csv", col_types = col.info)

# function to tidy-up the raw covid data
piv <- function(x, lbl) {
    x %>% 
        # filtering on 50 states only
        filter(Province_State %in% state.name) %>% 
        # drop columns not needed
        # Country_Region always = US
        # iso2, iso3, and code3 all contain the same info
        # note iso3 = "US" denotes the states + DC. other values for 
        # American Samoa (AS), Guam (GU), Northern Mariana Islands (MP), 
        # Puerto Rico (PR), and The Virgin Islands (VI)
        # UID is a concatenation of code3 and FIPS
        select(-Country_Region, -iso2, -iso3, -code3, -UID) %>% 
        # pivot the dataset. all columns with a "/" (i.e. dates) will be 
        # moved to a new cal_date column. all values moved to a label column
        pivot_longer(contains("/"), names_to = "cal_date", values_to = lbl) %>% 
        # convert dates into a proper format with mdy(month/day/year) function
        mutate(cal_date = mdy(cal_date))
}

cases <- piv(cases, "tot_cases")
deaths <- piv(deaths, "tot_deaths")

# combine tidy data into one table
dat <- left_join(cases, deaths) %>% 
    group_by(Combined_Key) %>% 
    rename(State = Province_State,
           County = Admin2,
           Lon = Long_) %>%     
    mutate(cases = tot_cases - lag(tot_cases, default = 0),
           deaths = tot_deaths - lag(tot_deaths, default = 0)) %>% 
    ungroup()

# save results to an RDS file
saveRDS(dat, "covid19-us.rds")
