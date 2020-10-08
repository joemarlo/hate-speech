import tweepy
import pandas as pd
import os

# import custom functions
#os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech/Tweets/Functions")
#os.chdir("/home/pi/hate-speech/Tweets/Functions")
script_directory = os.path.dirname(os.path.realpath(__file__))
os.chdir(script_directory)
from is_US import is_US, locations

# reset working directory
#os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech")
#os.chdir("/home/pi/hate-speech")

# import twitter credentials
from twitter_credentials import consumer_key, consumer_secret, access_key, access_secret

def get_users_tweets(user_id):
    # modified from https://gist.github.com/yanofsky/5436496
    # Twitter only allows access to a users most recent 3240 tweets with this method

    # authorize twitter, initialize
    auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_key, access_secret)
    api = tweepy.API(auth)

    #initialize a list to hold all the tweepy Tweets
    alltweets = []

    #make initial request for most recent tweets (200 is the maximum allowed count)
    new_tweets = api.user_timeline(user_id=user_id, count=200)

    #save most recent
    alltweets.extend(new_tweets)

    # if user is not in the US then stop here
    try:
        if not is_US(alltweets[0].user.location):
            return
    except IndexError:
        return

    #save the id of the oldest tweet less one
    oldest = alltweets[-1].id - 1

    #keep grabbing tweets until there are no tweets left to grab
    while len(new_tweets) > 0:
        #print(f"getting tweets before {oldest}")

        #all subsequent requests use the max_id param to prevent duplicates
        new_tweets = api.user_timeline(user_id = user_id, count=200, max_id=oldest)

        #save most recent tweets
        alltweets.extend(new_tweets)

        #update the id of the oldest tweet less one
        oldest = alltweets[-1].id - 1

        #print(f"...{len(alltweets)} tweets downloaded so far")

    #transform the tweepy tweets into a 2D array that will populate the dataframe
    outtweets = [[tweet.id_str, tweet.created_at, tweet.text, tweet.user.location, tweet.user.screen_name] for tweet in alltweets]

    # turn tweets into a dataframe
    out_df = pd.DataFrame(outtweets, columns=['id', 'created_at', 'text', 'location', 'handle'])

    return(out_df)


# the below doesn't run when script is called via 'import'
if __name__ == "__main__":
    # test the function
    get_users_tweets(25073877) #realDonaldTrump
    get_users_tweets(9024901243) #random id that doesn't work
    get_users_tweets(36523) #random id that does work
    get_users_tweets(380871320)
    get_users_tweets('realDonaldTrump') #this returns george's timeline
