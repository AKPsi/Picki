import requests
import os
from urllib.parse import quote
from dotenv import load_dotenv
from flask import Flask, request
import firebase_admin
from firebase_admin import firestore


app = Flask(__name__)
load_dotenv()
firebase_admin.initialize_app()
db = firestore.Client()


@app.route('/session', methods=['POST'])
def createSession():
    if 'name' not in request.form:
        return {
            'message': "Error! 'name' not found in request."
        }, 400
    if 'device_id' not in request.form:
        return {
            'message': "Error! 'deviceID' not found in request."
        }, 400

    name = request.form['name']
    device_id = request.form['device_id']

    session_ref = db.collection(u'sessions').document()
    session_ref.set({
        u'device_ids': [device_id],
        u'user_address': '',
        u'restaurants': [],
        u'names': [name]
    })

    return {'session_id': session_ref.id}, 201


@app.route('/session/<session_id>/address', methods=['POST'])
def addresss(session_id):
    if not db.collection(u'sessions').document(session_id).get().exists:
        return {
            'message': "Error! Invalid session ID."
        }, 400
    if 'address' not in request.form:
        return {
            'message': "Error! 'address' not found in request."
        }, 400

    url = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json'
    params = {
        'input': request.form['address'],
        'inputtype': 'textquery',
        'fields': 'formatted_address',
        'key': os.environ.get('GCLOUD_MAPS_API_KEY')
        }

    response = requests.get(url, params=params).json()
    if response['status'] != 'OK':
        return {
            'message': "Error! Invalid address."
        }, 400

    fmt_address = response['candidates'][0]['formatted_address']

    session_ref = db.collection(u'sessions').document(session_id)
    session_ref.update({u'user_address': fmt_address})

    return {'address': fmt_address}, 200


if __name__ == "__main__":
    app.run(port=4561, host='127.0.0.1', debug=True)
