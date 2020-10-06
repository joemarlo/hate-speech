import pandas as pd
import os

os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech")

# read in the list of locations to match
locations = pd.read_csv("Tweets/Functions/cleaned_locations.csv").drop("Unnamed: 0", axis=1)

def is_US(tweet_location, locations=locations):
    # function takes in the twitter user's self described location and returns
    #   True/False if any of the text matches the top 1000 US cities, a US state
    #   full name or US state abbreviation
    # function checks to see if the entire location in the locations dataframe is
    #   contained within tweet_location

    # check if string first
    if (not isinstance(tweet_location, str)):
        return(False)

    # case insensitive match
    insensitive_match = any([(location.lower() in tweet_location.lower()) for location in locations.Case_insensitive])

    # case sensitive match
    sensitive_match = any([(location in tweet_location) for location in locations.Case_sensitive.dropna()])

    return(any([insensitive_match, sensitive_match]))


# stuff only to run when not called via 'import' here
if __name__ == "__main__":
    # test the function
    is_US("New york, NY")
    is_US("alksjdl")
    is_US("mo")
    is_US("MO")
    is_US("Denver")
