
setwd("example")
rmarkdown::render("COVID_US.Rmd", 
                  output_file = "New England Report.html", 
                  params = list(states = c("Connecticut", "Massachusetts", 
                                           "Rhode Island", "Maine", 
                                           "New Hampshire", "Vermont")))
