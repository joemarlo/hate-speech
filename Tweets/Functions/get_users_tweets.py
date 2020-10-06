import tweepy
import pandas as pd
import os

os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech")

def get_users_tweets(user_id):
    # modified from https://gist.github.com/yanofsky/5436496
    # Twitter only allows access to a users most recent 3240 tweets with this method

    #authorize twitter, initialize tweepy
    auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_key, access_secret)
    api = tweepy.API(auth)

    #initialize a list to hold all the tweepy Tweets
    alltweets = []

    #make initial request for most recent tweets (200 is the maximum allowed count)
    try:
        new_tweets = api.user_timeline(user_id = user_id, count=200)
    except:
        return # return nothing if user id doesn't exist

    #save most recent tweets
    alltweets.extend(new_tweets)

    #save the id of the oldest tweet less one
    oldest = alltweets[-1].id - 1

    #keep grabbing tweets until there are no tweets left to grab
    while len(new_tweets) > 0:
        print(f"getting tweets before {oldest}")

        #all subsiquent requests use the max_id param to prevent duplicates
        new_tweets = api.user_timeline(screen_name = screen_name,count=200,max_id=oldest)

        #save most recent tweets
        alltweets.extend(new_tweets)

        #update the id of the oldest tweet less one
        oldest = alltweets[-1].id - 1

        print(f"...{len(alltweets)} tweets downloaded so far")

    #transform the tweepy tweets into a 2D array that will populate the csv
    outtweets = [[tweet.id_str, tweet.created_at, tweet.text, tweet.user.location, tweet.user.screen_name] for tweet in alltweets]

    out_df = pd.DataFrame(outtweets, columns=['id', 'created_at', 'text', 'location', 'handle'])

    return(out_df)

# test the function
get_users_tweets(25073877) #realDonaldTrump
get_users_tweets(9024901243) #random id that doesn't work
get_users_tweets(36523) #random id that does work
get_users_tweets('realDonaldTrump') #this returns george's timeline
