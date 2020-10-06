import tweepy
import os
import pandas as pd

# import custom functions
os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech/Tweets/Functions")
from is_US import is_US
from is_US import locations

# reset working directory
os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech")
