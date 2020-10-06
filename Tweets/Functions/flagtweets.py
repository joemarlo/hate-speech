#!/usr/bin/env python
# coding: utf-8

# # Function to flag tweets

import pandas aspd
import numpy as np

# Arguments: twitter data as a DataFrame, hate speech dictionary as a list

def flagtweet(hatespeech, data):

    # make all text in dataframe lowercase
    data['text'] = df['text'].str.lower()

    # check if elements in hatespeech are in the text (1 for true, 0 for false):
    data['flagged'] = np.multiply([any(i in words for i in hatespeech) \
    for words in data['text'].str.split().values],1)

    return data

#---Test function on sample data----:

# Create hatespeech list:
hatespeech = ['xyz' , 'two', 'abc', 'four']

# Create test dataframe with hatespeech:
df = pd.DataFrame({'userid': ['01040', '14020','10250','10424'], 'text': ["This is xyz", "def","AbC", "FoUr"]})

# Flag tweets:
test_df = flagtweet(hatespeech, df)

test_df.head()
