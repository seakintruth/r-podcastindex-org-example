#!/usr/bin/env Rscript
# This script was developed on ubunto and depends on having previously installed these packages: 
# sudo apt install libssl-dev openssl curl libcurl4-openssl-dev 
# [Todo] add check for pacman install, if missing then install it install.packages("pacman")
pacman::p_load(
	httr,
	jsonlite,
        digest,
	askpass
)

# Intial working R Example (a single function as a begining for a package)
# this R script was crafted after the python example see:
# https://github.com/tbowers/python-podcastindex-org-example/blob/master/podcasting-index.py
# and guidance from this vignette
# https://cran.r-project.org/web/packages/httr/vignettes/api-packages.html
# setup some basic vars for the search api. 
# for more information, see https://api.podcastindex.org/developer_docs
podcast_index_api_search_byterm <- function(...){
   search_terms <- list(...)
   if(length(search_terms)>0){
	# is the key set to environment variable?
	if ("" == Sys.getenv("podcast.index.api.key")){ 
		Sys.setenv(
			podcast.index.api.key = askpass::askpass(
				prompt = 'ENTER YOUR PODCAST INDEX API KEY HERE: '
			)
		)
	}
	api_key <- Sys.getenv("podcast.index.api.key")

	# is the key secret set to environment variable?
	if ("" == Sys.getenv("podcast.index.api.secret")){ 
		Sys.setenv(
			podcast.index.api.secret = askpass::askpass(
				prompt = 'ENTER YOUR PODCAST API SECRET HERE: '
			)
		)
	}
	api_secret <- Sys.getenv("podcast.index.api.secret")

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
		),
		"; script; podcasting-index-r-cli)"
	)	
	# For fun: Sets User-Agent to something like (that date is the R version date):
	# R version 4.0.5 (2021-03-31) (x86_64 Linux 5.8.0-48-generic; script; podcasting-index-r-cli)

	   
       # we'll need the unix time, for a linux system just using: 
	epoch_time <- as.numeric(as.POSIXlt(Sys.time(), "GMT"))
	#NOT --> as.integer(Sys.time())

	# our hash here is the api key + secret + time 
	data_to_hash <- paste0(
		api_key, api_secret, as.character(epoch_time)
	)
	# which is then sha-1'd
	sha_1 <- digest::sha1(data_to_hash)

# try this??? 	sha_1 <- sha1_hash("",paste0(api_key,api_secret, as.character(epoch_time)))
	response <- GET(
		url = "https://api.podcastindex.org/api/1.0/search/byterm?q=no+agenda+33",
		config = add_headers(
			`User-Agent` = user_agent,
	                `X-Auth-Date` = epoch_time,
			`X-Auth-Key` = api_key,
			`Authorization` = sha_1
		),
		 encode = "json"
	)

#Accept = "application/json"
#	response_BROKE <- GET(
#		url = "https://api.podcastindex.org", 
#		path = "/api/1.0/search/byterm",
#		query = search_queries,
#		add_headers(
#			`User-Agent` = user_agent,
#	                `X-Auth-Date` = epoch_time,
#			`X-Auth-Key` = api_key,
#			Authorization = sha_1,
#			Accept = "application/json"
#		)
#	)

# NOT RUN:  
#	if (http_error(response)) {
#		stop(
#		      sprintf(
#		        "GitHub API request failed [%s]\n%s\n<%s>", 
#		        status_code(response),
#		        parsed$message,
#		        parsed$documentation_url
#		      ),
#		      call. = FALSE
#		)
#		return(NULL)
#	}

	parsed <- jsonlite::fromJSON(content(response, "text"), simplifyVector = FALSE)
	return(parsed)
   }else{
	return(NULL)
   }
}

check <-podcast_index_api_search_byterm("no","agenda",33) 

message(check)
