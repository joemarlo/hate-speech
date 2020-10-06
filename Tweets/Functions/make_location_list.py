import pandas as pd
import os
import requests
from bs4 import BeautifulSoup

os.chdir("/home/joemarlo/Dropbox/Data/Projects/hate-speech")

cities = pd.read_csv("Tweets/Functions/raw_cities.csv")

# trim "city", "county", 'town' as these often are not included
# e.g. Denver City should just be "Denver"
cities['NAME'] = cities['NAME'].str.replace(' city| county| town|balance of | \(pt\.\)', '', case=False)
cities['NAME'] = cities['NAME'].str.strip()

# manual exclusions
#'Ada' b/c it matches "Canada"
cities = cities.loc[cities['NAME']!='Ada',:].reset_index(drop=True)

# grab top 1000 values by population (includes states and counties)
top_locations = cities.sort_values("POPESTIMATE2019", ascending=False).iloc[0:2000, :].reset_index(drop=True)
len(top_locations.NAME.unique())
top_locations = top_locations.drop(columns=['STNAME', 'POPESTIMATE2019']).drop_duplicates()

# add state abbreviations by scraping the table
URL = "https://www.ssa.gov/international/coc-docs/states.html"
page = requests.get(URL)
soup = BeautifulSoup(page.content, 'html.parser')
tables = soup.find_all("table")
table = tables[0]
tab_data = [[cell.text for cell in row.find_all(["th","td"])]
                        for row in table.find_all("tr")]

# convert html to dataframe
state_abbrev = pd.DataFrame(tab_data, columns=['Name', 'State_abbrev'])

# trim leading spaces
state_abbrev['State_abbrev'] = state_abbrev['State_abbrev'].str.strip()

# add abbrev to top locations df
top_locations['State_abbrev'] = state_abbrev['State_abbrev']

# rename columns
top_locations = top_locations.rename(columns={"NAME": "Case_insensitive", "State_abbrev": "Case_sensitive"}).reset_index(drop=True)

# write out
top_locations.to_csv("Tweets/Functions/cleaned_locations.csv")
