import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from imblearn.over_sampling import SMOTE
from sklearn.linear_model import LogisticRegression
from sklearn.naive_bayes import MultinomialNB, ComplementNB

####################### Create dtm
cv = CountVectorizer()
cv.fit(dat['Cleaned_txt'])
X = cv.transform(dat['Cleaned_txt'])
y = np.array(dat['label'])


####################### Fit NB
nb_clf = MultinomialNB()
nb_clf.fit(X, y)

####################### Fit Logistic Regression
log_reg = LogisticRegression()
log_reg.fit(X, y)



####################### Test on out of sample
hold = pipe(hold)
X_test = cv.transform(hold['Cleaned_txt'])
nb_preds = nb_clf.predict(X_test)
log_preds = log_reg.predict(X_test)
