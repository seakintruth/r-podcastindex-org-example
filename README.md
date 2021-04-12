# r-podcastindex-org-example
R language example of how to engage with the https://podcastindex.org/ APIs 

# How to use:

1. Install R (from https://cran.r-project.org/)

1. Install dependencies 
  1. For Linux your distro's equivilent of (ubuntu 20.04 example)
  ```R
  sudo apt install libssl-dev openssl curl libcurl4-openssl-dev
  ```

1. Script prompts you for the `api_key` and `api_secret` with your api and key values provided by https://api.podcastindex.org.  This script stores your keys in user environment variables for convinience, do change to a file method for a production [shiny app.](https://shiny.rstudio.com/gallery/)

1. Execute in command line:
    ```bash
    $ R podcasting-index.R "adam curry"
    ```
