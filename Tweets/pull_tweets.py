import tweepy
import os
import pandas as pd
import numpy as np

# import custom functions
os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech/Tweets/Functions")
from get_users_tweets import get_users_tweets

# reset working directory
os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech")

# test the function
tmp = get_users_tweets(user_id=25073877)
tmp.head()
tmp = get_users_tweets(user_id=380871320)
tmp.head()
tmp = get_users_tweets(user_id=12)
tmp.head()

# run the function on randomly sampled tweets
results = []
for i in range(0, 1000):

    # sample for user ids
    user_id = np.random.randint(low=1, high=1000000000, size=1)[0]

    # get the tweet history
    try:
        result = get_users_tweets(user_id=user_id)
    except:
        continue

    # store the results
    results.append(result)


len(results)
sum([len(table.index) for table in results])

results_locations = [table.location[0] for table in results]
sum(results_locations != "")
np.array(results_locations)[[local != "" for local in results_locations]]

# combine into one dataframe and write out
all_results = pd.concat(results).reset_index(drop=True)
all_results.to_csv("Tweets/Data/tweet.csv")


# check location
results_is_US = [is_US(location) for location in all_results.location]

all_results.iloc[results_is_US, :].to_csv("Tweets/Data/locations.csv")
