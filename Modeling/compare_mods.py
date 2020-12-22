hold_cleaned = pipe(hold)
X_hold = embed_txt(hold_cleaned['text'])
y_hold = hold_cleaned['label']

preds = model.predict(X_hold)

fpr, tpr, thresholds = metrics.roc_curve(hold['label'], preds, pos_label=1)
metrics.auc(fpr, tpr)

metrics.precision_score(hold['label'], pred_rnn)
metrics.recall_score(hold['label'], pred_rnn)


result_table = pd.DataFrame(columns=['classifiers', 'fpr','tpr','auc'])
model = ['RNN', 'Naive Bayes', 'Logistic Regression']
fpr = [fpr, nb_fpr, log_fpr]
tpr = [tpr, nb_tpr, log_tpr]
auc = [metrics.auc(fpr, tpr), metrics.auc(nb_fpr, nb_tpr), metrics.auc(log_fpr, log_tpr)]

roc = pd.DataFrame(model, fpr, tpr, auc)
result_table = dict({'classifiers':'RNN'
                                    'fpr':fpr,
                                    'tpr':tpr,
                                    'auc':auc}, ignore_index=True)


plt.plot(fpr, tpr, label = 'RNN auc = .817')
plt.plot(nb_fpr, nb_tpr, label = 'Naive Bayes auc = .809')
plt.plot(log_fpr, log_tpr, label = 'Logistic Regression = .817')
plt.xticks(np.arange(0.0, 1.1, step=0.1))
plt.yticks(np.arange(0.0, 1.1, step=0.1))
plt.xlabel("False Positive Rate", fontsize=15)
plt.ylabel("True Positive Rate", fontsize=15)
plt.legend(prop={'size':13}, loc='lower right')
plt.title('AUC ROC Curves', fontweight='bold', fontsize=15)


p = sns.kdeplot(prop_plt['probability']).set(title='Distribution on RNN predictions', xlabel='Probability that a Tweet is Anti-LGBTQ+', ylabel='Density')
p.set_title('')
p.


# Log regression and NB
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
nb_probs = nb_clf.predict_proba(X_test)[::,1]
log_preds = log_reg.predict(X_test)
log_probs = log_reg.predict_proba(X_test)[::,1]


metrics.precision_score(hold['label'], log_preds)
metrics.recall_score(hold['label'], log_preds)
log_fpr, log_tpr, log_thresholds = metrics.roc_curve(hold['label'], log_probs, pos_label=1)
metrics.auc(fpr, tpr)


metrics.precision_score(hold['label'], nb_preds)
metrics.recall_score(hold['label'], nb_preds)
nb_fpr, nb_tpr, nb_thresholds = metrics.roc_curve(hold['label'], nb_probs, pos_label=1)
metrics.auc(fpr, tpr)
