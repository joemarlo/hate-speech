import tweepy
import os
import time
import pandas as pd
import numpy as np

# import custom functions
#os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech/Tweets/Functions")
os.chdir("/home/pi/hate-speech/Tweets/Functions")
from get_users_tweets import get_users_tweets

# reset working directory
#os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech")
os.chdir("/home/pi/hate-speech")

# test the function
#get_users_tweets(user_id=25073877)
#get_users_tweets(user_id=380871320)
#get_users_tweets(user_id=12)

# run the function on randomly sampled tweets
# rate limit is 100,000 requests per day
# and 900 requests per 15min
# https://developer.twitter.com/en/docs/twitter-api/v1/tweets/timelines/faq
results = []
for i in range(0, 40000):

    # every 50 loops, print status
    if (i + 1) % 50 == 0:
        print(f"...on sampled user {i + 1}. Collected {len(pd.concat(results).index)} tweets from {len(pd.concat(results).handle.unique())} US users so far.")

    # sample for user ids
    user_id = np.random.randint(low=1, high=1000000000, size=1)[0]

    # get the tweet history
    try:
        result = get_users_tweets(user_id=user_id)
    except tweepy.RateLimitError:
        print("...sleeping for 5min due to rate limit")
        time.sleep((5 * 60) + 1)
        continue
    except:
        continue

    # store the results
    results.append(result)


# combine into one dataframe and write out
all_results = pd.concat(results).reset_index(drop=True)
#all_results.to_csv("Tweets/Data/tweet_20201006_1700.tsv", sep='\t') #this has issues with all delimiters tested

# first add a date column formated in string b/c pandas json formatting is weird
all_results['Date'] = all_results['created_at'].apply(lambda x: x.strftime('%Y-%m-%d'))

# write out to json (this doesn't have delimter issues)
all_results.to_json('Tweets/Data/tweet_20201007_2105.json')

# check number of tweets captured
all_results.shape

# check number of users captured
len(all_results.handle.unique())
