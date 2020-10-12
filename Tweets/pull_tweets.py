import tweepy
import os
import time
import pandas as pd
import numpy as np

# import custom functions
#os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech/Tweets/Functions")
os.chdir("/home/pi/hate-speech/Tweets/Functions")
script_directory = os.path.dirname(os.path.realpath(__file__))
os.chdir(os.path.join(script_directory, "Functions"))
from get_users_tweets import get_users_tweets

# reset working directory
#os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech")
os.chdir("/home/pi/hate-speech")

# read in the list of locations to match
US_ids = pd.read_csv("Tweets/Functions/US_ids_20201009_162551.csv").drop("Unnamed: 0", axis=1)


# run the function on randomly sampled tweets
# rate limit is 100,000 requests per day
# and 900 requests per 15min
# https://developer.twitter.com/en/docs/twitter-api/v1/tweets/timelines/faq
results = []
for i in range(0, len(US_ids.ID)):

    # message at beginning
    if (i == 0):
        print("...initiating")

    # every 50 loops, print status
    if (i + 1) % 50 == 0:
        try:
            print(f"...on sampled user {i + 1}. Collected {len(pd.concat(results).index)} tweets from {len(pd.concat(results).handle.unique())} users for this json file.")
        except:
            print(f"...on sampled user {i + 1}")

    # every 250 loops, save to json and empty results list (due to 1gb memory on raspberry pi)
    if (i + 1) % 250 == 0:

        try:
            # combine into one dataframe and write out
            all_results = pd.concat(results).reset_index(drop=True)

            # write out to json
            all_results.to_json('Tweets/Data/tweet_' + time.strftime("%Y%m%d_%H%M%S") + '.json')

            # message to user
            print("...dumping memory and writing tweets out to Tweets/Data/*.json")

            # clear list
            results = []
        except:
            # clear list and print message to user
            results = []
            print("...dumping memory because error writing tweets out to Tweets/Data/*.json")
            continue

    # get the user id from the list
    user_id = US_ids.ID[i]

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
# write out to json
all_results.to_json('Tweets/Data/tweet_' + time.strftime("%Y%m%d_%H%M%S") + '.json')
print("...script finished. Just wrote out last json file.")
