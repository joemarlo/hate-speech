setwd("/home/joemarlo/Dropbox/Data/Projects/hate-speech")
source('Plots/ggplot_settings.R')
library(RSQLite)


# connect to database -----------------------------------------------------

# connect to database NYC.db; if it doesn't exist this will
#  create it in the working directory
conn <- dbConnect(RSQLite::SQLite(), "tweets.db")


# read in and combine the data into one flat dataframe
files <- list.files("Tweets/Data/v2/raw_jsons_US_tweets_one_two", pattern = ".json")
tweets <- map_dfr(files, function(file) {
  # read in the data
  tweets_json <- jsonlite::fromJSON(txt = paste0("Tweets/Data/v2/raw_jsons_US_tweets_one_one/", file))
  
  # convert from nested json to flat df
  tweets <- map_dfc(names(tweets_json), function(col) {
      unlist(tweets_json[[col]])
    }) %>%
    setNames(names(tweets_json)) %>%
    mutate(source_file = file)
  
  return(tweets)
}) %>%
  # created_at field is milliseconds since 1970
  mutate(Date = as.Date(lubridate::as_datetime(created_at / 1000)))

# remove duplicates
tweets <- distinct(tweets, id, created_at, text, location, 
                   handle, user_id, Date, .keep_all = TRUE)

# original table
# dbWriteTable(
#   conn = conn,
#   name = "Tweets",
#   value = tweets,
#   overwrite = TRUE
# )

# append the file to the table if the table already exists
dbWriteTable(
  conn = conn,
  name = "Tweets",
  value = tweets,
  append = TRUE
)

# list all the tables available in the database
# dbListTables(conn)

# test a query
# tbl(conn, "tweets") %>%
#   group_by(Source_file) %>%
#   summarize(n.rows = n())
