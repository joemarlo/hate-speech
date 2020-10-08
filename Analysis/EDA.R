setwd("/home/joemarlo/Dropbox/Data/Projects/hate-speech")
source('Plots/ggplot_settings.R')

# read in and combine the data into one flat dataframe
tweets <- map_dfr(list.files("Tweets/Data", pattern = ".json"),
    function(file){
      
      # read in the data
      tweets_json <- jsonlite::fromJSON(txt = paste0("Tweets/Data/", file))
      
      # convert from nested json to flat df
      tweets <- map_dfc(names(tweets_json), function(col){
        unlist(tweets_json[[col]])
      }) %>% 
        setNames(names(tweets_json))
      
      return(tweets)
    }) %>% 
  # created_at field is milliseconds since 1970
  mutate(Date = as.Date(lubridate::as_datetime(created_at/1000)))
    
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
       x = "Tweets per user",
       y = 'Count of users')
ggsave("Plots/tweets_by_user.png",
       width = 8,
       height = 5)

# tweets over time
tweets %>% 
  mutate(Period = as.Date(paste0(lubridate::year(Date), "-", 
                                 lubridate::month(Date), "-01"))) %>% 
  group_by(Period) %>% 
  tally() %>% 
  ggplot(aes(x = Period, y = n, color = n)) +
  geom_rect(xmin = as.Date("2016-07-01"), xmax = as.Date("2017-12-01"),
            ymin = 0, ymax = 30000, alpha = 0.3, fill = 'grey85', size = 0) +
  geom_line() +
  geom_point() +
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

# distinct users by tweet date
tweets %>% 
  mutate(Period = as.Date(paste0(lubridate::year(Date), "-",
                                 lubridate::month(Date), "-01"))) %>%
  group_by(Period) %>%
  summarize(n_users = n_distinct(handle),
            .groups = 'drop') %>% 
  ggplot(aes(x = Period, y = n_users, color = n_users)) +
  geom_line() +
  geom_point() +
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
                                 lubridate::month(Date), "-01"))) %>%
  group_by(handle) %>% 
  filter(Period == min(Period)) %>%
  group_by(Period) %>% 
  tally() %>% 
  ggplot(aes(x = Period, y = n, color = n)) +
  geom_line() +
  geom_point()
