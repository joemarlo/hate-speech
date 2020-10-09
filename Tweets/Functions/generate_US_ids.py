import os
import time
import pandas as pd
import numpy as np
import tweepy

# import custom functions
#os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech/Tweets/Functions")
os.chdir("/home/pi/hate-speech/Tweets/Functions")
from is_US import is_US, locations

# reset working directory
#os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech")
os.chdir("/home/pi/hate-speech")

# import twitter credentials
from twitter_credentials import consumer_key, consumer_secret, access_key, access_secret

# authorize twitter, initialize
auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_key, access_secret)
api = tweepy.API(auth)


US_ids = []
US_ids_locations = []
for i in range(0, 25000):

    # message at beginning
    if (i == 0):
        print("...initiating")

    # every 50 loops, print status
    if (i + 1) % 50 == 0:
        print(f"...on batch {i + 1}. {len(US_ids)} US IDs found so far.")

    # generate 100 random ids
    batch = list(np.random.randint(low=1, high=10000000000, size=100))

    # get attributes of those ids
    try:
        batch_attributes = api.lookup_users(user_ids=batch)
    except tweepy.RateLimitError:
        print("...sleeping for 5min due to Twitter API rate limit")
        time.sleep((5 * 60) + 1)
        continue
    except:
        continue

    # check if users are in the US and add to list
    for id in batch_attributes:
        if is_US(id.location):
            US_ids.append(id.id)
            US_ids_locations.append(id.location)


# convert into a dataframe
US_ids_df = pd.DataFrame({'ID': US_ids, 'location': US_ids_locations})

# read in latest list of ids
US_ids_df_old = pd.read_csv("Tweets/Functions/US_ids.csv").drop("Unnamed: 0", axis=1)

# append new ids to old list
US_ids_df = US_ids_df.append(US_ids_df_old, ignore_index=True)

# remove duplicates
US_ids_df = US_ids_df.drop_duplicates()

# write out
US_ids_df.to_csv("Tweets/Functions/US_ids.csv")
