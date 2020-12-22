import pandas as pd
from nltk.corpus import stopwords
import re
import tensorflow as tf
from sklearn.model_selection import train_test_split
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
import numpy as np
# load coded data
f1 = pd.read_excel('coded/tweet_tagging.xlsx')
f1 = f1.iloc[:,[1, 2]]
f1.columns = ['label', 'text']
f2 = pd.read_csv('coded/bilal.csv')
f2 = f2.iloc[:,[8,3]]
f2.columns = ['label', 'text']

f3 = pd.read_excel('coded/coded.xlsx')
f3 = f3.iloc[:,[7,2]]
f3.columns = ['label', 'text']

#dat = pd.concat([f1, f2]).reset_index(drop = True)

dat = pd.concat([f1, f2, f3]).reset_index(drop = True)

dat = dat.dropna()

dat['label'][dat['label'] > 0] = 1

dat, hold = train_test_split(dat, test_size=0.1, random_state=46,shuffle=True)


# clean text
def pipe(dat):
    dat['text'] = dat['text'].str.replace("@[\w]*","")
    dat['text'] = dat['text'].str.replace("http.?://[^\s]+[\s]?","")
    dat['text'] = dat['text'].str.replace("rt", "")
    dat['text'] = dat['text'].str.replace("\n", "")
    dat['text'] = dat['text'].str.replace("[^a-zA-Z\s]", "")
    dat['text'] = dat['text'].str.lower()


    dat.reset_index(drop=True, inplace = True)

    stop_words = stopwords.words('english')
    def clean(text):
        text = text.split()
        text=" ".join([word for word in text if not word in stop_words])
        return(text)

    cleaned = list()
    rejected = list()
    for i in range(len(dat)):
        try:
            cleaned.append(clean(dat['text'][i]))
        except:
            rejected.append(i)

    dat["Cleaned_txt"]= cleaned
    return(dat)

dat = pipe(dat)
X = dat["Cleaned_txt"]
y = dat['label']

# split train and test set
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=46,shuffle=True)

# define embedings
max_lenght=50
tokenizer = Tokenizer()
tokenizer.fit_on_texts(X_train)
word_index = tokenizer.word_index # creating word dict for words in training
sequences = tokenizer.texts_to_sequences(X_train)  # replacing words with the number corresponding to them in the dictionary(word_index)
X_train_padded = pad_sequences(sequences, padding='post',maxlen=max_lenght) # padding words
X_test_sequences = tokenizer.texts_to_sequences(X_test)
X_test_padded = pad_sequences(X_test_sequences,padding="post",maxlen=max_lenght)
vocab_size = len(tokenizer.word_index)+1
embedding_dim=50


model = tf.keras.Sequential([
    tf.keras.layers.Embedding(vocab_size, embedding_dim, input_length=50),
    tf.keras.layers.Dropout(0.5),
    tf.keras.layers.Bidirectional(tf.keras.layers.LSTM(100, return_sequences = True)),
    tf.keras.layers.Bidirectional(tf.keras.layers.LSTM(32)),
    tf.keras.layers.Flatten(),
    tf.keras.layers.Dense(32, activation='relu'),
    tf.keras.layers.Dropout(0.5),
    tf.keras.layers.Dense(1, activation='sigmoid')
])
model.compile(loss='binary_crossentropy',optimizer='adam',metrics=[tf.keras.metrics.AUC()])
model.summary()

num_epochs = 3
history=model.fit(X_train_padded,y_train, epochs=num_epochs, validation_data=(X_test_padded,y_test))



def embed_txt(text):
    X_test_sequences = tokenizer.texts_to_sequences(text)
    X_test_padded = pad_sequences(X_test_sequences,padding="post",maxlen=max_lenght)
    vocab_size = len(tokenizer.word_index)+1
    embedding_dim=50
    return(X_test_padded)

hold_cleaned = pipe(hold)
X_hold = embed_txt(hold_cleaned['text'])
y_hold = hold_cleaned['label']

preds = model.predict(X_hold)
