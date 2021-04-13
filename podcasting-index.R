#!/usr/bin/env Rscript
# Example command line call from the terminal
# --------------------------------------------
# $ ./podcasting-index.R 'no agenda' ./key.R

# Dependancies:
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
	httr,
	jsonlite,
        digest,
	askpass,
	argparse
)

# Set key and secret
if(interactive()) { 
	api_key <- askpass::askpass(
		prompt = 'ENTER YOUR PODCAST INDEX API KEY HERE: '
	)
	api_secret <- askpass::askpass(
		prompt = 'ENTER YOUR PODCAST API SECRET HERE: '
	)
	search_terms <- readline(prompt="Enter search terms:\n")
} else {
	# Handle cli Arguments if they exist
	args <- commandArgs(trailingOnly=TRUE)
	search_terms <- args[1]
	KeySecretFilePath <- args[2]
	if(file.exists(KeySecretFilePath)){
		source(KeySecretFilePath)
	} else {
		message("Usage: \n ./podcasting-index.r 'search terms' /path/to/secret/key.r ")
	}
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
	message(jsonlite::prettify(content(response, "text",indent=4)))
	parsed <- jsonlite::fromJSON(content(response, "text"), simplifyVector = FALSE)
	return(parsed)
   }else{
	return(NULL)
   }
}


# Call the search function
search_results <- podcast_index_api_search_byterm(
	search_terms,
	api_key=api_key,
	api_secret=api_secret
)
# now use the values stored in (search_results) 

