import os, json
import glob
from pandas import json_normalize

# Set path to JSON files in directory:
path_to_json = 'Data/'
json_files = [pos_json for pos_json in os.listdir(path_to_json) if pos_json.endswith('.json')]

# Read all JSON files in directory and store in dataframe:
dfs = []
for index, js in enumerate(json_files):
    with open(os.path.join(path_to_json, js)) as json_file:
        json_text = json.load(json_file)
        data = pd.DataFrame(json_text)
        dfs.append(data)

df = pd.concat(dfs)

# Load hatespeech:
hatespeech = pd.read_csv("Dictionary/hatespeech.csv", header=None)
hatespeech = list(hatespeech[0])

# Run flagtweet function on tweet data
df = flagtweet(hatespeech, df)

# Check number of flagged tweets:
df.flagged.value_counts()
