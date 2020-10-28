# Detecting hate speech

Final project for NYU Statistical Consulting class.

**Warning: this project contains vulgar and offensive language.**

## Background
Hate speech on social media has been identified as a major problem, yet little is know about the prevalence and patterns of hate speech on social media sites. In a [2019 paper](https://alexandra-siegel.com/wp-content/uploads/2019/05/Siegel_et_al_election_hatespeech_qjps.pdf), Siegel and colleagues investigated the prevalence of racially motivated hate speech on twitter in the months before, during and after the 2016 presidential election. For this project, we aim to replicate these research methods to investigate LGBTQ+ directed hate speech.

### Research question
How has the prevalence of LGBTQ+ directed hate speech on Twitter changed from the summer of 2015 through winter of 2017?

### Methods Summary
Using random number generation, we will randomly select ~250,000 twitter user IDs from locations within the United States. After identifying a random sample of users, the [tweepy API](http://docs.tweepy.org/en/latest/) will be used to pull all users tweets from June of 2015 through June of 2017.

We have developed a content dictionary of words associated with LGBTQ+ directed hate speech obtained from [hatebase](https://hatebase.org/), a non-profit that identifies hate speech terms for academic and governmental research. The content dictionary will be used to identify all tweets that contain a word that is related to documented hate speech. While this approach is an effective filter, it is not an effective classifier. The content dictionary alone flags many tweets that are not actually hate speech but contain words that, in a different context, could be associated with hate speech. As an example, tweets explicitly condemning hate speech could be picked up the content dictionary. To refine the effectiveness of the content dictionary, we will follow the methods used by Siegel and colleagues (2019) and create a Naive Bayes machine learning classifier that will be used to classify hate speech among all the tweets flagged by the content dictionary. After using the content dictionary to filter tweets from the ~250,000 users we will select a random subset of 15,000 tweets that will be used to train and test the machine learning classifier. After building the model the classifier will be used to label the remaining tweets flagged by the content dictionary.

## Documentation

### Sources
- [Tweepy](http://docs.tweepy.org/en/latest/)
- [Hate speech](https://hatebase.org/)
- [Top US cities by population](https://www.census.gov/data/tables/time-series/demo/popest/2010s-total-cities-and-towns.html#ds)
