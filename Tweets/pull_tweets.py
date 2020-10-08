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

    # message at beginning
    if (i == 0):
        print("...initiating")

    # every 50 loops, print status
    if (i + 1) % 50 == 0:
        print(f"...on sampled user {i + 1}. Collected {len(pd.concat(results).index)} tweets from {len(pd.concat(results).handle.unique())} US users for this json file.")

    # every 5000 loops, save to json and empty results list (due to 1gb memory on rpi)
    if (i + 1) % 5000 == 0:
        
        # message to user
        print("...dumping memory and writing tweets out to Tweets/Data/*.json")
        
        try:
            # combine into one dataframe and write out
            all_results = pd.concat(results).reset_index(drop=True)
        
            # write out to json
            all_results.to_json('Tweets/Data/tweet_' + time.strftime("%Y%m%d_%H%M%S") + '.json')
        
            # clear list
            results = []
        except:
            continue

    # sample for user ids
    user_id = np.random.randint(low=1, high=1000000000, size=1)[0]

    # get the tweet history
    try:
        result = get_users_tweets(user_id=user_id)
    except tweepy.RateLimitError:
        print("...sleeping for 5min due to Twitter API rate limit")
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
all_results.to_json('Tweets/Data/tweet_' + time.strftime("%Y%m%d_%H%M%S") + '.json')

# check number of tweets captured
all_results.shape

# check number of users captured
len(all_results.handle.unique())
