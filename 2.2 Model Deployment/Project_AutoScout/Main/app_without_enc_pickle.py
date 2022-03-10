from sklearn.preprocessing import OrdinalEncoder
from flask import Flask, request, render_template
import pandas as pd
import pickle5 as pickle

app = Flask(__name__)

def prediction(make, hp, km, age, gtype, gnumber, df='feature_selected_df.csv', rf='streamlit_final_rf', xgb='streamlit_final_xgb'):

    new_df = {'make_model': make,
              'hp_kW':float(hp),
              'km':float(km),
              'age':float(age),
              'Gearing_Type':gtype,
              'Gears':float(gnumber)}
    features = pd.DataFrame(new_df, index=[0])
    
    data = pd.read_csv(df)
    data2 = data.drop(columns='price')
    use_df = pd.concat([features, data2], axis=0)

    cat = data2.select_dtypes('object').columns
    enc = OrdinalEncoder()
    use_df[cat] = enc.fit_transform(use_df[cat])
    new_df = use_df[:1]

    # loaded_enc = pickle.load(open(enc, 'rb'))
    # new_df = pd.DataFrame(features, index=[0])
    # new_df[new_df.select_dtypes('object').columns] = loaded_enc.transform(new_df[new_df.select_dtypes('object').columns])

    load_pickle_rf = pickle.load(open(rf, 'rb'))
    load_pickle_xgb = pickle.load(open(xgb, 'rb'))

    prediction_rf = load_pickle_rf.predict(new_df)
    prediction_xgb = load_pickle_xgb.predict(new_df)

    return int(round(prediction_rf[0],0)), int(round(prediction_xgb[0],0))


@app.route('/', methods=['POST', 'GET'])
def rootpage():
    res = None
    make = ''
    hp = ''
    km = ''
    age = ''
    gtype = ''
    gnumber = ''
    if request.method == 'POST':
        make = request.form.get('make')
        hp = request.form.get('hp')
        km = request.form.get('km')
        age = request.form.get('age')
        gtype = request.form.get('gtype')
        gnumber = request.form.get('gnumber')
        res = prediction(make, hp, km, age, gtype, gnumber)
    return render_template('new_index.html', res=res, make=make, hp=hp, km=km, age=age, gtype=gtype, gnumber=gnumber)

app.run()
# app.run(host='0.0.0.0', port=5000, debug=True)