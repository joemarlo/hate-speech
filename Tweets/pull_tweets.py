import tweepy
import os
import pandas as pd
import numpy as np

# import custom functions
os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech/Tweets/Functions")
from is_US import is_US, locations
os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech/Tweets/Functions")
from get_users_tweets import get_users_tweets

# reset working directory
os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech")

# NOTE: run twitter_credentials.py

# test the function
tmp = get_users_tweets(user_id=25073877)
tmp.head()
tmp = get_users_tweets(user_id=380871320)
tmp.head()
tmp = get_users_tweets(user_id=12)
tmp.head()

# run the function on randomly sampled tweets
results = []
for i in range(0, 50):

    # sample for user ids
    user_id = np.random.randint(low=1, high=1000000000, size=1)[0]

    # get the tweet history
    try:
        result = get_users_tweets(user_id=user_id)
    except:
        continue

    # store the results
    results.append(result)
