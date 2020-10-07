setwd("/home/joemarlo/Dropbox/Data/Projects/hate-speech")
source('Plots/ggplot_settings.R')

# read in the data
tweets_json <- jsonlite::fromJSON(txt = "Tweets/Data/tweet_20201006_1700.json")

# convert from nested json to flat df
tweets <- map_dfc(names(tweets_json), function(col){
  unlist(tweets_json[[col]])
}) %>% 
  setNames(names(tweets_json))

# tweets per user
tweets %>% 
  group_by(handle) %>% 
  tally() %>% 
  ggplot(aes(x = n)) +
  geom_histogram(color = 'white', bins = 15) +
  scale_x_continuous(labels = scales::comma_format()) +
  labs(title = 'Tweets captured per user',
       subtitle = paste0('n tweets = ', scales::comma_format()(nrow(tweets))),
       x = "Tweets per user",
       y = 'Count of users')
ggsave("Plots/tweets_by_user.png",
       width = 8,
       height = 5)

# tweets over time
tweets %>% 
  mutate(
    Date = as.Date(Date),
    Period = as.Date(paste0(lubridate::year(Date), "-", 
                            lubridate::month(Date), "-01"))) %>% 
  group_by(Period) %>% 
  tally() %>% 
  ggplot(aes(x = Period, y = n, color = n)) +
  geom_line() +
  geom_point() +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = 'Tweets captured per month',
       subtitle = paste0('n tweets = ', scales::comma_format()(nrow(tweets))),
       x = NULL,
       y = 'Count of tweets per month') +
  theme(legend.position = 'none')
ggsave("Plots/tweets_over_time.png",
       width = 8,
       height = 5)
