from sklearn.preprocessing import OrdinalEncoder
from xgboost import XGBRegressor
from IPython.core.display import HTML
from PIL import Image
import streamlit as st
import pandas as pd
import numpy as np
import pickle as pickle

st.error(
    """
## Car Price Prediction App

##### The magic of predicting the car prices according to the 6 features of a car.
##### Come and try :cyclone:
"""
)

def user_input_features():
    make_model = st.sidebar.selectbox('Make-Model',
        ("Audi A3",
        "Audi A1",
        "Opel Astra",
        "Opel Insignia",
        "Opel Corsa",
        "Renault Clio",
        "Renault Espace",
        "Renault Duster"),
    )
    horsepower = st.sidebar.slider("Horsepower (kw)", 40, 239, 50)
    km = st.sidebar.number_input("Kilometers", value=1000, step=1)
    age = st.sidebar.radio('Age of the Car', [0, 1, 2, 3])
    gear_type = st.sidebar.selectbox('Select a Gear Type', ['Automatic', 'Manual', 'Semi-automatic'])
    gears = st.sidebar.radio('Number of Gears', [5, 6, 7, 8])
    new_df = {'make_model':make_model,
              'hp_kW':horsepower,
              'km':km,
              'age':age,
              'Gearing_Type':gear_type,
              'Gears':gears}
    features = pd.DataFrame(new_df, index=[0])
    return features
input_df = user_input_features()

data = pd.read_csv("feature_selected_df.csv")
data2 = data.drop(columns='price')
use_df = pd.concat([input_df, data2], axis=0)

cat = data2.select_dtypes('object').columns
enc = OrdinalEncoder()
use_df[cat] = enc.fit_transform(use_df[cat])
new_df = use_df[:1]

# loaded_enc = pickle.load(open('enc_pickle', 'rb'))
# new_df = pd.DataFrame(input_df, index=[0])
# new_df[new_df.select_dtypes('object').columns] = loaded_enc.transform(new_df[new_df.select_dtypes('object').columns])
st.subheader('User Input Features')
resa = new_df.astype('int')
resa = resa.rename(columns={'make_model':'Make & Model',
                      'hp_kW':'Hp',
                      'km':'Kilometers',
                      'age':'Age of the Car',
                      'Gearing_Type':'Gearing Type',
                      'Gears': 'Number of Gears'})
st.write(HTML(resa.to_html(index=False)))

load_pickle_rf = pickle.load(open('streamlit_final_rf', 'rb'))
load_pickle_xgb = pickle.load(open('streamlit_final_xgb', 'rb'))

prediction_rf = load_pickle_rf.predict(new_df)
prediction_rf = pd.DataFrame(prediction_rf, columns=['Random Forest'])
prediction_xgb = load_pickle_xgb.predict(new_df)
prediction_xgb = pd.DataFrame(prediction_xgb, columns=['XGBoost'])
st.subheader('Prediction')
st.write('Click predict to see the prediction')
if st.button("Predict"):
    res = pd.concat([prediction_rf, prediction_xgb], axis=1)
    res2 = res.astype('int')
    aa = res2.iloc[:,0].values.tolist()[0]
    bb = res2.iloc[:,1].values.tolist()[0]
    cc = abs(res2.iloc[:,0].values.tolist()[0] - res2.iloc[:,1].values.tolist()[0])
    col1, col2, col3 = st.columns(3)
    col1.metric('Random Forest', aa)
    col2.metric('XGBoost', bb)
    col3.metric('Prediction Difference', cc)
    st.write('*** Predictions in US Dollars')

    a = input_df['make_model']

    if a[0] == 'Audi A3':
        img = Image.open('audi a3.webp')
    elif a[0] == 'Audi A1':
        img = Image.open('audi a1.jpeg')
    elif a[0] == 'Opel Astra':
        img = Image.open('astra.jpeg')
    elif a[0] == 'Opel Insignia':
        img = Image.open('insignia.jpeg')
    elif a[0] == 'Opel Corsa':
        img = Image.open('corsa.jpeg')
    elif a[0] == 'Renault Clio':
        img = Image.open('clio.jpeg')
    elif a[0] == 'Renault Espace':
        img = Image.open('espace.jpeg')
    elif a[0] == 'Renault Duster':
        img = Image.open('duster.webp')
    st.error(f'**{a[0]}**')
    st.image(img, use_column_width=True)