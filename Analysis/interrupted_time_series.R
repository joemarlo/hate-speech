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
dates$cutpoint <- c(241, 345, 416, 454, 394, 427)

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
        p.value = model$pv['Conventional',],
        p.value_adjusted = 1 - (1 - p.value)^12
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
  mutate(p.value_adjusted = 1 - (1 - p.value)^12) %>% 
  select(description, term, estimate, std.error, p.value, p.value_adjusted) %>% 
  ungroup()

# clean up rdrobust output for plotting
results_cutoff <- tweet_tally_bandwidth %>% 
  distinct(description, .keep_all = TRUE) %>% 
  mutate(term = 'Prevalence') %>% 
  select(description, term, estimate, std.error, p.value, p.value_adjusted)

# plot the estimates
results %>% 
  filter(term == 'groupTRUE:index') %>% 
  bind_rows(results_cutoff) %>% 
  mutate(term = recode(term, 'groupTRUE:index' = 'Incidence'), 
         #https://www.researchgate.net/post/How_to_adjust_confidence_interval_for_multiple_testing
         lower = estimate - (qnorm((1-0.05/12)) * std.error),
         upper = estimate + (qnorm((1-0.05/12)) * std.error),
         sig = if_else(p.value_adjusted <= 0.05,
                       'Significant @ alpha = 0.05',
                       'Not significant @ alpha = 0.05')) %>%
  ggplot(aes(x = estimate, y = description, xmin = lower, xmax = upper, color = sig)) +
  geom_vline(xintercept = 0, color = 'grey70', linetype = 'dashed') +
  geom_point() +
  geom_linerange() +
  facet_grid(~term, scales = 'free') +
  labs(title = "Estimates of the prevalance and incidence",
       subtitle = 'Bonferroni adjusted values',
       x = NULL,
       y = NULL,
       color = NULL) +
  theme(legend.position = 'bottom')
# ggsave("Plots/flagged_tweets_estimates.png",
#        width = 9,
#        height = 4)

# table of pvalues
coef_table <- results %>% 
  filter(term == 'groupTRUE:index') %>% 
  bind_rows(results_cutoff) %>% 
  mutate(term = recode(term, 'groupTRUE:index' = 'Incidence')) %>% 
  select(description, term, estimate, p.value, p.value_adjusted) %>%
  pivot_wider(names_from = 'term', values_from = c('estimate', 'p.value', 'p.value_adjusted'))

# sort and clean up
coef_table[match(c("2016 election", "Legalization of same-sex marriage", 'Pulse nightclub shooting', 'Transgender ban', 'Trump inauguration day', 'Windsor v.s. US'), coef_table$description),] %>% 
  select(description, estimate_Incidence, p.value_Incidence, p.value_adjusted_Incidence, estimate_Prevalence, p.value_Prevalence, p.value_adjusted_Prevalence) %>% 
  knitr::kable(digits = 3)

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
  scale_color_manual(values = c('#00BFC4', '#F8766D')) +
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


# Windsor vs US -----------------------------------------------------------

# https://blog.twitter.com/official/en_us/a/2013/keep-up-with-conversations-on-twitter.html
tmp <- tweet_tally_bandwidth %>%
  filter(description == 'Windsor v.s. US') %>% 
  mutate(group = if_else(Period <= as.Date('2013-06-26'), "before",
                         if_else(Period <= as.Date('2013-08-28'), 'middle',
                         'after')))
tmp %>% 
  ggplot(aes(x = Period, y = proportion, group = group, color = group)) +
  geom_line() +
  geom_point() +
  geom_smooth(data = tmp %>% filter(group %in% c("before", 'after')),
              method = 'lm', formula = y ~ x, color = 'black') +
  geom_vline(aes(xintercept = as.Date('2013-06-26')), linetype = 'dashed') +
  geom_vline(aes(xintercept = as.Date('2013-08-28')), linetype = 'dashed') +
  annotate(geom = 'text', x = as.Date('2013-06-10'), y = 40, 
           label = 'Windsor vs. U.S.', angle = 90) +
  annotate(geom = 'text', x = as.Date('2013-09-10'), y = 80, 
           label = 'Twitter policy change', angle = 90) +
  scale_color_manual(values = c('#F8766D', '#00BFC4', 'grey50')) +
  scale_x_date(date_breaks = "3 months", date_labels = "%Y-%m") +
  scale_y_continuous(labels = scales::comma_format(accuracy = 1)) +
  labs(title = 'Two key dates occuring within two months of each other: Windsor vs. U.S. and Twitter policy change',
       x = NULL,
       y = 'Flagged tweets per 100,000 tweets') +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 40, hjust = 1))
# ggsave("Plots/flagged_tweets_policy_change.png",
#        width = 10,
#        height = 7)