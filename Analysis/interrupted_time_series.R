setwd("/home/joemarlo/Dropbox/Data/Projects/hate-speech")
source('Plots/ggplot_settings.R')
library(rdrobust)

# establish dates for each event
dates <- tibble(Description = c('Windsor v.s. US', 'Legalization of same-sex marriage', '2016 election', 'Transgender ban', 'Pulse nightclub shooting', 'Trump inauguration day'),
                Dates = c(as.Date('2013-06-26'), as.Date('2015-06-26'), as.Date('2016-11-08'), as.Date('2017-07-26'), as.Date('2016-06-12'), as.Date('2017-01-20')))
# read in the data
tweet_tally_weekly_trimmed <- read_csv("Analysis/flagged_rate_weekly.csv") %>%
  na.omit() %>%
  slice(-1) %>%
  rename(proportion = Proportion)

# cleanup df
tweet_tally <- tweet_tally_weekly_trimmed %>% 
  mutate(index = row_number(),
         proportion = proportion * 1e5)

# add cutpoints
dates <- dates %>% mutate(cutpoint = c(241, 345, 416, 454, 394, 427))

# for each event, get the coef and bandwidth specified from rdrobust 
  # and return a dataframe with the observations within the bandwidth
tweet_tally_bandwidth <- pmap_dfr(
  .l = list(dates$Description, dates$cutpoint, dates$Dates),
  function(description, cutpoint, date) {
    # model it
    model <- rdrobust(
      y = tweet_tally$proportion,
      x = tweet_tally$index,
      c = cutpoint,
      p = 1,
      bwselect = 'msetwo'
    )

    # extract bandwidths
    bandwidths <- model$bws['h', ]
    
    # filter the data to just the bandwidths
    dat <- tweet_tally %>%
      filter(index >= (cutpoint - bandwidths['left']),
             index <= (cutpoint + bandwidths['right'])) %>%
      mutate(
        group = (index >= cutpoint),
        description = description,
        cutpoint_date = date,
        estimate = model$coef['Conventional',],
        std.error = model$se['Conventional',],
        p.value_adjusted = 1 - (1 - model$pv['Conventional',])^18
        )
    
    return(dat)
    })

# model each date
results <- tweet_tally_bandwidth %>% 
  group_by(description) %>% 
  nest() %>% 
  mutate(model = map(data, function(df) lm(proportion ~ group * index, data = df)),
         tidied = map(model, function(model) broom::tidy(model))) %>% 
  unnest(tidied) %>% 
  mutate(p.value_adjusted = 1 - (1 - p.value)^18) %>% 
  select(description, term, estimate, std.error, p.value_adjusted)

# model the difference in means
results_diff_in_means <- tweet_tally_bandwidth %>% 
  group_by(description) %>% 
  nest() %>% 
  mutate(model = map(data, function(df) lm(proportion ~ group, data = df)),
         tidied = map(model, function(model) broom::tidy(model))) %>% 
  unnest(tidied) %>% 
  mutate(p.value_adjusted = 1 - (1 - p.value)^18) %>% 
  filter(term == 'groupTRUE') %>% 
  mutate(term = recode(term, groupTRUE = 'Difference in means')) %>% 
  select(description, term, estimate, std.error, p.value_adjusted)

# clean up rdrobust output for plotting
results_cutoff <- tweet_tally_bandwidth %>% 
  distinct(description, .keep_all = TRUE) %>% 
  mutate(term = 'Difference at cutoff') %>% 
  select(description, term, estimate, std.error, p.value_adjusted)

# plot the estimates
results %>% 
  filter(term == 'groupTRUE:index') %>% 
  bind_rows(results_diff_in_means) %>% 
  bind_rows(results_cutoff) %>% 
  mutate(term = recode(term, 'groupTRUE:index' = 'Slope'), 
         #https://www.researchgate.net/post/How_to_adjust_confidence_interval_for_multiple_testing
         lower = estimate - (qnorm((1-0.05/18)) * std.error),
         upper = estimate + (qnorm((1-0.05/18)) * std.error),
         sig = if_else(p.value_adjusted <= 0.05,
                       'Significant @ alpha = 0.05',
                       'Not significant @ alpha = 0.05')) %>%
  ggplot(aes(x = estimate, y = description, xmin = lower, xmax = upper, color = sig)) +
  geom_vline(xintercept = 0, color = 'grey70', linetype = 'dashed') +
  geom_point() +
  geom_linerange() +
  facet_grid(~term, scales = 'free') +
  labs(title = "Estimates of the difference in means and the change in slope pre- and post-event",
       subtitle = 'Bonferroni adjusted 95% confidence interval',
       x = NULL,
       y = NULL,
       color = NULL) +
  theme(legend.position = 'bottom')
# ggsave("Plots/flagged_tweets_estimates.png",
#        width = 11,
#        height = 4)

# plot the slopes
tweet_tally_bandwidth %>% 
  left_join(results %>% filter(term == 'groupTRUE:index'), by = 'description') %>% 
  # mutate(label = paste0(description, ": ", cutpoint_date, '\np value = ', round(p.value_adjusted, 3))) %>% 
  ggplot(aes(x = Period, y = proportion, group = group, color = group)) +
  geom_line() +
  geom_point() +
  geom_smooth(method = 'lm', formula = y ~ x, color = 'black') +
  geom_vline(aes(xintercept = cutpoint_date),
             linetype = 'dashed') +
  facet_wrap(~description, scales = 'free_x') +
  scale_x_date(date_breaks = "3 months", date_labels = "%Y-%m") +
  scale_y_continuous(labels = scales::comma_format(accuracy = 1)) +
  labs(title = 'Key dates of political and social events',
       x = NULL,
       y = 'Flagged tweets per 100,000 tweets') +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 40, hjust = 1))
# ggsave("Plots/flagged_tweets_facets_bandwidth.png",
#        width = 11,
#        height = 7)
