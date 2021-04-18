#!/usr/bin/env Rscript
# Example command line call from the terminal
# --------------------------------------------
# $ ./podcasting-index.R 'no agenda' ./key.R

# Dependencies:
# This script was developed on linux/ubuntu and depends on having previously installed these packages: 
# sudo apt install libssl-dev openssl curl libcurl4-openssl-dev 

# Intial working R Example (a single function as a begining for a package)
# this R script was crafted after the python example see:
# https://github.com/tbowers/python-podcastindex-org-example/blob/master/podcasting-index.py
# and guidance from this vignette
# https://cran.r-project.org/web/packages/httr/vignettes/api-packages.html
# setup some basic vars for the search api. 
# for more information, see https://api.podcastindex.org/developer_docs

# If missing then install pacman
if (!require("pacman")) install.packages("pacman")
# install and load everything else with pacman
pacman::p_load( 
  shiny,
  httr,
  jsonlite,
  digest,
  askpass,
  argparse,
  DT,
  purrr, 
  data.table
)

# Set key and secret
# Handle cli Arguments if they exist
args <- commandArgs(trailingOnly=TRUE)
search_terms <- args[1]
KeySecretFilePath <- args[2]
if(file.exists(KeySecretFilePath)){
  source(KeySecretFilePath)
} else {
  # use the static file path:
  source(
    "~/git/r-podcastindex-org-shiny-app/r-podcastindex-org-shiny-app/podcastindex-key.R"
  )
  message("Usage: \n ./podcasting-index.r 'search terms' /path/to/secret/key.r ")
}

# The search function
podcast_index_api_search_byterm <- function(...,api_key,api_secret){
  search_terms <- list(...)
  if(length(search_terms)>0){
    search_queries <- URLencode(paste0("q=",paste(search_terms,sep="",collapse=" ")))
    #q=[search terms
    urlTarget <- paste0("https://api.podcastindex.org/api/1.0/search/byterm")
    # the api follows the Amazon style authentication
    # see https://docs.aws.amazon.com/AmazonS3/latest/dev/S3_Authentication2.html
    # podcast_index <- handle("https://api.podcastindex.org")
    user_agent <- paste0(
      R.version.string, 
      " shiny-app-",
      packageVersion("shiny"),
      " (",
      paste(
        Sys.info()[c("machine","sysname","release")],
        sep = "",
        collapse = " "
      ),")"
    )	
    # For fun: Sets User-Agent to something like (that date is the R version date):
    # R version 4.0.5 (2021-03-31) (x86_64 Linux 5.8.0-48-generic; script; podcasting-index-r-cli)
    
    # we'll need the unix time, for a linux system just using: 
    epoch_time <- as.numeric(as.POSIXlt(Sys.time(), "GMT"))
    
    # our hash here is the api key + secret + time 
    data_to_hash <- paste0(
      api_key, api_secret, as.character(epoch_time)
    )
    # which then generates the authorization hash via sha-1 (had to set serialize=FALSE, to work)
    sha_1 <- digest(data_to_hash,algo="sha1",serialize=FALSE)
    
    # GET our payload
    response <- GET(
      url = "https://api.podcastindex.org", 
      path = "/api/1.0/search/byterm",
      query = search_queries,
      add_headers(
        `User-Agent` = user_agent,
        `X-Auth-Date` = epoch_time,
        `X-Auth-Key` = api_key,
        Authorization = sha_1,
        Accept = "application/json"
      )
    )
    # Comment this line out for production, displays results
#    json_text_pretty <- jsonlite::prettify(content(response, "text",indent=4)) 
#    message(json_text_pretty)
#    return(json_text_pretty)
    parsed <- jsonlite::fromJSON(content(response, "text"), simplifyVector = FALSE)
    
    return(parsed)
  }else{
    return(NULL)
  }
}

ui <- fluidPage(
    textInput(
      inputId='search_term', 
      label="Search by Term", 
      value = NULL, 
      width = "50%", 
      placeholder = "Enter a search  term"
    ),
    actionButton("action", "Request"),
    textOutput("counter"),
    textOutput("next_fire"),
    DT::dataTableOutput("search_results_out")
)

server <- function(input, output) {
  # This method ensures that users can't poll the api more than one time per second
  # it will take a fairly large user base to exceed the api limits.
  timer <- reactiveVal(Sys.time())
  i_counter <- reactiveVal(0)

  observeEvent(input$action, {
      # poll timer
      while (timer() > Sys.time()) {
          # so we don't burn CPU
          Sys.sleep(0.1)
      }
      # timer satisfied! push out timer 1 second
      timer(Sys.time() + 1)

      # make request
      # Call the search function
      search_results <- podcast_index_api_search_byterm(
        { input$search_term },
        api_key=api_key,
        api_secret=api_secret
      )
      message(search_results$count)
      # now use the values stored in (search_results) 
      search_results_dt <- rbindlist(map(search_results$feeds,as.data.table),fill=TRUE,idcol=TRUE)
      output$search_results_out <- DT::renderDataTable(
        search_results_dt
      )
      i_counter(i_counter() + 1)
  })
  output$next_fire <- renderText(timer())
  output$counter <- renderText(i_counter())
}

shinyApp(ui = ui, server = server)
