setwd("/home/joemarlo/Dropbox/Data/Projects/hate-speech")
source('Plots/ggplot_settings.R')
library(RSQLite)

# connect to sqlite database containing the tweets
conn <- dbConnect(RSQLite::SQLite(), "tweets.db")

# read in the flagged tweets
flagged_tweets <- read_csv("Predictions/post_prediction_ID_patch.csv") %>% 
  mutate(id = as.character(id))


# on disk aggregation -----------------------------------------------------

# filter to just include flagged tweets
only_flagged <- flagged_tweets %>%
  filter(probability > 0.4) %>% 
  select(id) %>% 
  mutate(flagged = TRUE)
  
# merge with bigger db and check to see how many flagged tweets there are
tbl(conn, "Tweets") %>% 
  select(id, created_at) %>% 
  left_join(only_flagged, by = 'id', copy = TRUE) %>% 
  summarize(total_flagged = sum(flagged))


# monthly aggregation -----------------------------------------------------

# create df of just the hate speech tweets
flagged_tweets_monthly <- flagged_tweets %>%
  filter(probability > 0.4) %>% 
  mutate(Period = as.Date(paste0(lubridate::year(created_at), "-", 
                                 lubridate::month(created_at), "-01"))) %>% 
  group_by(Period) %>% 
  tally() %>% 
  rename(Flagged = n)

# plot of flagged tweets  
flagged_tweets_monthly %>% 
  ggplot(aes(x = Period, y = Flagged)) +
  geom_line(color = 'grey30') +
  geom_point(color = 'grey30') +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = 'Flagged tweets over time',
       x = NULL,
       y = 'Count per month') +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 40, hjust = 1))

# all tweets over time
tweet_tally_monthly <- tbl(conn, "Tweets") %>% 
  select(Date) %>% 
  collect() %>% 
  mutate(
    Date = as.Date(Date, origin = as.Date("1970-01-01")),
    Period = as.Date(paste0(lubridate::year(Date), "-", 
                            lubridate::month(Date), "-01"))
  ) %>% 
  group_by(Period) %>% 
  tally()

# plot of proportion of flagged tweets overtime
tweet_tally_monthly %>% 
  full_join(flagged_tweets_monthly, by = 'Period') %>%
  mutate(flagged = Flagged / n) %>% 
  na.omit() %>% 
  slice(-1) %>% 
  ggplot(aes(x = Period, y = flagged)) +
  geom_line(color = 'grey30') +
  geom_point(color = 'grey30') +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = 'Proportion of tweets flagged as anti-LGBTQ+',
       subtitle = paste0('Total tweets = ', scales::comma_format()(sum(tweet_tally$n)), "\n",
                         'Flagged tweets = ', scales::comma_format()(sum(flagged_tweets_monthly$Flagged))),
       x = 'Month',
       y = 'Proportional of tweets') +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 40, hjust = 1))
ggsave("Plots/flagged_tweets_by_month.png",
       width = 8,
       height = 5)

# write out proportion
tweet_tally_monthly %>% 
  full_join(flagged_tweets_monthly, by = 'Period') %>%
  mutate(Proportion = Flagged / n) %>% 
  write_csv("Analysis/flagged_rate_monthly.csv")


# weekly aggregation ------------------------------------------------------

# create df of just the hate speech tweets
flagged_tweets_weekly <- flagged_tweets %>%
  filter(probability > 0.4) %>% 
  mutate(week = cut(created_at, "week", start.on.monday = FALSE),
         Period = as.Date(week)) %>% 
  group_by(Period) %>% 
  tally() %>% 
  rename(Flagged = n)

# plot of flagged tweets  
flagged_tweets_weekly %>% 
  ggplot(aes(x = Period, y = Flagged)) +
  geom_line(color = 'grey30') +
  geom_point(color = 'grey30') +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = 'Flagged tweets over time',
       x = NULL,
       y = 'Count per week') +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 40, hjust = 1))


# all tweets over time
tweet_tally_weekly <- tbl(conn, "Tweets") %>% 
  select(Date) %>% 
  collect() %>% 
  mutate(
    Date = as.Date(Date, origin = as.Date("1970-01-01")),
    Period =  as.Date(cut(Date, "week", start.on.monday = FALSE)) 
  ) %>% 
  group_by(Period) %>% 
  tally()

# plot of proportion of flagged tweets overtime
tweet_tally_weekly %>% 
  full_join(flagged_tweets_weekly, by = 'Period') %>%
  mutate(flagged = Flagged / n) %>% 
  na.omit() %>% 
  slice(-1) %>% 
  ggplot(aes(x = Period, y = flagged)) +
  geom_line(color = 'grey30') +
  geom_point(color = 'grey30') +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = 'Proportion of tweets flagged as anti-LGBTQ+',
       subtitle = paste0('Total tweets = ', scales::comma_format()(sum(tweet_tally_weekly$n)), "\n",
                         'Flagged tweets = ', scales::comma_format()(sum(flagged_tweets_weekly$Flagged))),
       x = 'Week',
       y = 'Proportion of tweets') +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 40, hjust = 1))
ggsave("Plots/flagged_tweets_by_week.png",
       width = 8,
       height = 5)

# write out proportion
tweet_tally_weekly %>% 
  full_join(flagged_tweets_weekly, by = 'Period') %>%
  mutate(Proportion = Flagged / n) %>% 
  write_csv("Analysis/flagged_rate_weekly.csv")

# 
tweet_tally_weekly_trimmed <- tweet_tally_weekly %>% 
  full_join(flagged_tweets_weekly, by = 'Period') %>%
  mutate(proportion = Flagged / n) %>% 
  na.omit() %>% 
  slice(-1)

# dates
dates <- tibble(Description = c('U.S. vs Windsor', 'Legalization of same-sex marriage', '2016 election', 'Transgender ban', 'Pulse nightclub shooting', 'Trump inauguration day'),
                Dates = c(as.Date('2013-06-26'), as.Date('2015-05-01'), as.Date('2016-11-06'), as.Date('2017-07-26'), as.Date('2016-06-01'), as.Date('2017-01-20')))
tweet_tally_weekly_trimmed %>% 
  ggplot(aes(x = Period, y = proportion)) +
  geom_line(color = 'grey30') +
  geom_point(color = 'grey30') +
  geom_vline(data = dates, aes(xintercept = Dates),
             linetype = 'dashed') +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = 'Proportion of tweets flagged as anti-LGBTQ+',
       subtitle = paste0('Total tweets = ', scales::comma_format()(sum(tweet_tally_weekly$n)), "\n",
                         'Flagged tweets = ', scales::comma_format()(sum(flagged_tweets_weekly$Flagged))),
       x = 'Week',
       y = 'Proportion of tweets') +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 40, hjust = 1))
ggsave("Plots/flagged_tweets_vlines.png",
       width = 8,
       height = 5)

# facet plot of each date
map2_dfr(.x = dates$Description,
        .y = dates$Dates, 
        .f = function(desc, date){
          tweet_tally_weekly_trimmed %>% 
            filter(Period >= (date - lubridate::years(1)),
                   Period <= (date + lubridate::years(1))) %>% 
            mutate(date = date,
                   desc = desc)
        }) %>% 
  mutate(Term = Period < date) %>% 
  ggplot(aes(x = Period, y = proportion, color = Term)) +
  geom_line() +
  geom_point() +
  geom_vline(aes(xintercept = date),
             linetype = 'dashed') +
  facet_wrap(~desc, scales = 'free_x') +
  scale_x_date(date_breaks = "3 months", date_labels = "%Y-%m") +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = 'Key dates of political and social events',
       x = NULL,
       y = 'Proportion of tweets that are flagged') +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 40, hjust = 1))
ggsave("Plots/flagged_tweets_facets.png",
       width = 11,
       height = 7)


# 2015 analysis -----------------------------------------------------------

# June 26th supreme court decision date
tweet_tally_weekly %>% 
  full_join(flagged_tweets_weekly, by = 'Period') %>%
  mutate(proportion = Flagged / n,
         Threshold = Period >= as.Date("2015-06-26")) %>% 
  filter(lubridate::year(Period) == 2015) %>% 
  ggplot(aes(x = Period, y = proportion, color = Threshold)) +
  geom_line() +
  geom_point() +
  geom_vline(xintercept = as.Date("2015-06-26"), linetype = 'dashed') +
  geom_smooth(method = 'lm') +
  scale_x_date(date_breaks = "1 month", date_labels = "%Y-%m") +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = 'Before and after marriage equality (2015-06-20)',
       x = 'Week',
       y = 'Proportional of tweets') +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 40, hjust = 1))
  
  
# July 26th 2017 -> Trump twitter military ban
tweet_tally_weekly %>% 
  full_join(flagged_tweets_weekly, by = 'Period') %>%
  mutate(proportion = Flagged / n,
         Threshold = Period >= as.Date("2016-07-26")) %>% 
  filter(lubridate::year(Period) == 2016) %>% 
  ggplot(aes(x = Period, y = proportion, color = Threshold)) +
  geom_line() +
  geom_point() +
  geom_vline(xintercept = as.Date("2016-07-26"), linetype = 'dashed') +
  geom_smooth(method = 'lm') +
  scale_x_date(date_breaks = "1 month", date_labels = "%Y-%m") +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = 'Before and after transgender ban (2016-07-26)',
       x = 'Week',
       y = 'Proportional of tweets') +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 40, hjust = 1))

# January 20th 2017 -> Trump inauguration
tweet_tally_weekly %>% 
  full_join(flagged_tweets_weekly, by = 'Period') %>%
  mutate(proportion = Flagged / n,
         Threshold = Period >= as.Date("2017-01-20")) %>% 
  filter(lubridate::year(Period) %in% 2016:2017) %>% 
  ggplot(aes(x = Period, y = proportion, color = Threshold)) +
  geom_line() +
  geom_point() +
  geom_vline(xintercept = as.Date("2017-01-20"), linetype = 'dashed') +
  geom_smooth(method = 'lm') +
  scale_x_date(date_breaks = "1 month", date_labels = "%Y-%m") +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = 'Before and after Trump inauguration (2017-01-20)',
       x = 'Week',
       y = 'Proportional of tweets') +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 40, hjust = 1))