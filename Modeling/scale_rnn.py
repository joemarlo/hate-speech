import rnn_data_prep.py

# load data
bigset = pd.read_csv('Tweets/Data/bigset.csv')
# drop row errors
bigset = bigset.dropna()
# pull out text
tweets = bigset[['text']]
# run cleaning pipeline
tweets = pipe(tweets)
# embed pre trained text
X = embed_txt(tweets['Cleaned_txt'])
# predict
preds = model.predict(X)

# return predictions to df
bigset['probability'] = preds

bigset= bigset.assign(fifty_cut = [1 if probability > .5 else 0 for probability in bigset['probability']])
bigset.to_csv('post_prediction_ID_patch.csv')

bigset.to_csv('post_prediction.csv')
