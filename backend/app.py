import requests
import os
import uuid
import json
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
            'message': "Error! 'device_id' not found in request."
        }, 400

    name = request.form['name']
    device_id = request.form['device_id']

    session_id = str(uuid.uuid4())[0:6]
    while db.collection(u'sessions').document(session_id).get().exists:
        session_id = str(uuid.uuid4())[0:6]

    session_ref = db.collection(u'sessions').document(session_id)
    session_ref.set({
        u'device_ids': [device_id],
        u'user_address': '',
        u'restaurants': [],
        u'names': [name]
    })

    return {'session_id': session_ref.id}, 201


@app.route('/session/<session_id>/address', methods=['POST'])
def address(session_id: str):
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


@app.route('/session/<session_id>', methods=['POST'])
def joinLobby(session_id: str):
    if 'name' not in request.form:
        return {
            'message': "Error! 'name' not found in request."
        }, 400
    if 'device_id' not in request.form:
        return {
            'message': "Error! 'device_id' not found in request."
        }, 400
    if not db.collection(u'sessions').document(session_id).get().exists:
        return {
            'message': "Error! Invalid session ID."
        }, 400

    session_ref = db.collection(u'sessions').document(session_id)
    session_ref.update({
        u'names': firestore.ArrayUnion([request.form['name']]),
        u'device_ids': firestore.ArrayUnion([request.form['device_id']])
        })

    fcm_headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=' + os.environ.get('FIREBASE_SERVER_KEY')
    }

    doc_dict = session_ref.get().to_dict()

    for name, device_id in zip(doc_dict['names'], doc_dict['device_ids']):
        fcm_body = {
            'to': device_id,
            'notification': {
                'title': 'user_join',
                'body': {
                    'name': name,
                    'device_id': device_id
                }
            }
        }

        requests.post(
            url="https://fcm.googleapis.com/fcm/send",
            headers=fcm_headers,
            data=json.dumps(fcm_body)
        )

    return {'session_id': session_id}, 200


if __name__ == "__main__":
    app.run(port=4561, host='127.0.0.1', debug=True)
