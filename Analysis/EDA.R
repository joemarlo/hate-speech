setwd("/home/joemarlo/Dropbox/Data/Projects/hate-speech")
source('Plots/ggplot_settings.R')

# read in and combine the data into one flat dataframe
# tweets_old <- jsonlite::fromJSON("Tweets/Data/v2/US_tweets_one_one.json")
tweets <- map_dfr(list.files("Tweets/Data/v2/raw_jsons_US_tweets_one_two", pattern = ".json"),
    function(file){
      
      # read in the data
      tweets_json <- jsonlite::fromJSON(txt = paste0("Tweets/Data/", file))
      
      # convert from nested json to flat df
      tweets <- map_dfc(names(tweets_json), function(col){
        unlist(tweets_json[[col]])
      }) %>% 
        setNames(names(tweets_json)) %>% 
        mutate(source_file = file)
      
      return(tweets)
    }) %>% 
  # created_at field is milliseconds since 1970
  mutate(Date = as.Date(lubridate::as_datetime(created_at/1000)))

# combine dataframes
# tweets <- bind_rows(tweets_old, tweets_new)

# remove duplicates
tweets <- distinct(tweets, id, created_at, text, location, 
                   handle, user_id, Date, .keep_all = TRUE)

# write out latest json combination to one json
# jsonlite::write_json(jsonlite::toJSON(tweets), path = "Tweets/Data/v2/US_tweets_one_one.json")

# tweets per user
tweets %>% 
  group_by(handle) %>% 
  tally() %>% 
  ggplot(aes(x = n)) +
  geom_histogram(color = 'white', bins = 15) +
  scale_x_continuous(labels = scales::comma_format()) +
  labs(title = 'Tweets collected per user',
       subtitle = paste0('n tweets = ', scales::comma_format()(nrow(tweets)), "\n",
                         'n users = ', scales::comma_format()(n_distinct(tweets$handle))),
       caption = paste0("As of ", Sys.Date()),
       x = "Tweets per user",
       y = 'Count of users')
ggsave("Plots/tweets_by_user.png",
       width = 8,
       height = 5)

# tweets over time
tweet_tally <- tweets %>% 
  mutate(Period = as.Date(paste0(lubridate::year(Date), "-", 
                                 lubridate::month(Date), "-01"))) %>% 
  group_by(Period) %>% 
  tally()
tweet_tally %>% 
  ggplot(aes(x = Period, y = n)) +
  geom_rect(xmin = as.Date("2016-07-01"), xmax = as.Date("2017-12-01"),
            ymin = 0.9  * tweet_tally %>% filter(Period %in% seq(as.Date("2016-07-01"), as.Date("2017-12-01"), by = 'month')) %>% pull(n) %>% min(),
            ymax = 1.1 * tweet_tally %>% filter(Period %in% seq(as.Date("2016-07-01"), as.Date("2017-12-01"), by = 'month')) %>% pull(n) %>% max(), 
            alpha = 0.3, fill = 'gray90', size = 0) +
  annotate(geom = 'text', 
           x = as.Date("2016-07-01"),
           y = 1.3 * tweet_tally %>% filter(Period %in% seq(as.Date("2016-07-01"), as.Date("2017-12-01"), by = 'month')) %>% pull(n) %>% max(),
           label = "Observation\nperiod",
           family = 'Helvetica', hjust = 0, size = 3, color = 'grey30', fontface = "bold"
           ) +
  geom_line(color = 'grey30') +
  geom_point(color = 'grey30') +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = 'Tweets collected by tweet date',
       subtitle = paste0('n tweets = ', scales::comma_format()(nrow(tweets)), "\n",
                         'n users = ', scales::comma_format()(n_distinct(tweets$handle))),
       caption = paste0("As of ", Sys.Date()),
       x = NULL,
       y = 'Count of tweets per month') +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 40, hjust = 1))
ggsave("Plots/tweets_over_time.png",
       width = 8,
       height = 5)
rm(tweet_tally)

# distinct users by tweet date
tweets %>% 
  mutate(Period = as.Date(paste0(lubridate::year(Date), "-",
                                 lubridate::month(Date), "-01"))) %>%
  group_by(Period) %>%
  summarize(n_users = n_distinct(handle),
            .groups = 'drop') %>% 
  ggplot(aes(x = Period, y = n_users)) +
  geom_line(color = 'grey30') +
  geom_point(color = 'grey30') +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = 'Distinct users collected by tweet date',
       subtitle = paste0('n tweets = ', scales::comma_format()(nrow(tweets)), "\n",
                         'n users = ', scales::comma_format()(n_distinct(tweets$handle))),
       caption = paste0("As of ", Sys.Date()),
       x = NULL,
       y = 'Count of users per month') +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 40, hjust = 1))
ggsave("Plots/users_over_time.png",
       width = 8,
       height = 5)

# users by oldest tweet
tweets %>% 
  mutate(Period = as.Date(paste0(lubridate::year(Date), "-",
                                 ceiling(lubridate::month(Date) / 6) * 6, "-01"))) %>%
  group_by(handle) %>% 
  filter(Period == min(Period)) %>%
  group_by(Period) %>% 
  tally() %>% 
  ggplot(aes(x = Period, y = n)) +
  geom_col() +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = 'Users by first tweet date',
       subtitle = paste0('n tweets = ', scales::comma_format()(nrow(tweets)), "\n",
                         'n users = ', scales::comma_format()(n_distinct(tweets$handle))),
       caption = paste0("As of ", Sys.Date()),
       x = NULL,
       y = 'Count of users') +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 40, hjust = 1))
ggsave("Plots/users_by_first_tweet.png",
       width = 8,
       height = 5)



# IDs <- map_dfr(list.files('Tweets/Functions/IDs', pattern = "*.csv")[-201], function(file){
#   read_csv(paste0("Tweets/Functions/IDs/", file))
# }) %>% dplyr::select(-X1)
# 
# n_distinct(IDs)

# there are a number of false positives that I think are captured because they
#   match uppercase state names. Filtering include locations with 3 or more consecutive
#   uppercase letters and then converting to lowercase and then running is_US()
#   should remove many of these false positives
# IDs %>% filter(str_count(location, "[A-Z]{4}") > 0) %>% View

#write_csv(IDs, "Tweets/IDs/US_IDs_one.csv")
