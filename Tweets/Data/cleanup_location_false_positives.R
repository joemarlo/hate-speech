setwd("/home/joemarlo/Dropbox/Data/Projects/hate-speech")
source('Plots/ggplot_settings.R')
library(RSQLite)

# connect to sqlite database containing the tweets
conn <- dbConnect(RSQLite::SQLite(), "tweets.db")

# pull all unique locations
tweet_locations <- tbl(conn, "Tweets") %>% 
  select(location) %>% 
  distinct() %>% 
  collect()

# read in US locations
locations <- read_csv("Tweets/Functions/cleaned_locations.csv") %>% 
  select(-X1) %>% 
  mutate(Case_insensitive = tolower(Case_insensitive))

# many of the false positives are all caps that match to US states
#   so we can remove many of them by filtering for all caps that are 4 or 
#   more characters and whose lowercase version does not match a US city or state
location_matches <- tweet_locations %>%
  filter(str_count(location, "[A-Z]{4}") > 0) %>%
  rowwise() %>%
  mutate(is_US = any(
    str_detect(
      string = tolower(location),
      pattern = locations$Case_insensitive
    )
  )) %>%
  ungroup()

# make a table of the false positives
location_matches %>% 
  filter(!is_US) %>% 
  select(location) %>% 
  dbWriteTable(
    conn = conn,
    name = 'false_positives',
    value = .
  )

# create blank table to save the results into
dbCreateTable(
  conn = conn,
  name = "Tweets_cleaned",
  fields = c(
    id = "text",
    created_at = "int",
    text = "text",
    location = "text",
    handle = 'text',
    user_id = 'int',
    source_file = "text",
    Date = "int"
  )
)

# make sure the new tables exist
dbListTables(conn)

# anti join the tweets table with the false positives and save to a
#   a new table
dbSendQuery(
  conn = conn,
  statement = 
    '
    INSERT INTO Tweets_cleaned
    SELECT A.*
    FROM Tweets A
    LEFT JOIN false_positives B
    ON A.location = B.location
    WHERE B.location IS NULL
  '
)

# see how the tables compare
tbl(conn, "Tweets")
tbl(conn, "Tweets_cleaned")
tbl(conn, "Tweets_cleaned") %>% tally()

# remove old table
# dbRemoveTable(conn, "Tweets")
# dbRemoveTable(conn, "false_positives")

# rename new table back to 'Tweets'
dbSendQuery(
  conn = conn,
  statement =  "ALTER TABLE Tweets_cleaned RENAME TO Tweets"
)

# rebuild the database file so the old data is removed
dbSendQuery(
  conn = conn,
  statement =  "VACUUM"
)

dbListTables(conn)

