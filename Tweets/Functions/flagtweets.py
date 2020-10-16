# Function to flag tweets

import pandas as pd
import numpy as np

# Arguments: twitter data as a DataFrame, hate speech dictionary as a list

def flagtweet(hatespeech, data):

    # make all text in dataframe lowercase
    data['text'] = data['text'].str.lower()

    # check if elements in hatespeech are in the text (1 for true, 0 for false)
    # accounts for different variants of how the words appear in tweets (spaces before or after the word, or both):
    df = pd.DataFrame({})
    df['flagged1'] = np.multiply([any(" " + i in words for i in hatespeech) for words in data['text'].values], True)
    df['flagged2'] = np.multiply([any(i + " " in words for i in hatespeech) for words in data['text'].values],True)
    df['flagged3'] = np.multiply([any(" " + i + " " in words for i in hatespeech) for words in data['text'].values],True)
    df['flagged4'] = np.multiply([any( i == words for i in hatespeech) for words in data['text'].values],True)
    df['flagged'] = df.flagged1 | df.flagged2 | df.flagged3 | df.flagged4

    data = pd.concat([data.reset_index(drop = True), df['flagged']], axis = 1)

    return data

#---Test function on sample data----:

# Create hatespeech list:
hatespeech = ['xyz' , 'two', 'abc', 'four']

# Create test dataframe with hatespeech:
df_test = pd.DataFrame({'userid': ['01040', '14020','10250','10424', '20502'], 'text': ["This is xyz and y", "def","AbC", "FoUr", "abcdxyzasds"]})

# Flag tweets:
test_df = flagtweet(hatespeech, df_test)

test_df.head()
