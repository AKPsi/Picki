import requests
import os
import uuid
import json
from dotenv import load_dotenv
from flask import Flask, request
import firebase_admin
from firebase_admin import firestore


RADIUS = 15000  # 15,000 m radius


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
        u'latitude': 0,
        u'longitude': 0,
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

    if 'address' in request.form:
        url = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json'
        params = {
            'input': request.form['address'],
            'inputtype': 'textquery',
            'fields': 'geometry',
            'key': os.environ.get('GCLOUD_MAPS_API_KEY')
            }

        response = requests.get(url, params=params).json()
        if response['status'] != 'OK':
            return {
                'message': "Error! Invalid address."
            }, 400

        print(response)
        location = response['candidates'][0]['geometry']['location']
        lat, lng = location['lat'], location['lng']
    elif 'latitude' and 'longitude' in request.form:
        lat, lng = request.form['latitude'], request.form['longitude']
    else:
        return {
            'message': "Error! neither address, latitutde, nor longitude found in request."
        }, 400

    session_ref = db.collection(u'sessions').document(session_id)
    session_ref.update({u'latitude': lat, u'longitude': lng})

    return {'latitude': lat, 'longitude': lng}, 200


@app.route('/session/<session_id>', methods=['POST'])
def joinLobby(session_id: str):
    if not db.collection(u'sessions').document(session_id).get().exists:
        return {
            'message': "Error! Invalid session ID."
        }, 400
    if 'name' not in request.form:
        return {
            'message': "Error! 'name' not found in request."
        }, 400
    if 'device_id' not in request.form:
        return {
            'message': "Error! 'device_id' not found in request."
        }, 400

    session_ref = db.collection(u'sessions').document(session_id)
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

    session_ref.update({
        u'names': firestore.ArrayUnion([request.form['name']]),
        u'device_ids': firestore.ArrayUnion([request.form['device_id']])
        })    

    return {'session_id': session_id, 'names': doc_dict['names']}, 200


@app.route('/session/<session_id>/start', methods=['POST'])
def start(session_id: str):
    if not db.collection(u'sessions').document(session_id).get().exists:
        return {
            'message': "Error! Invalid session ID."
        }, 400

    session_ref = db.collection(u'sessions').document(session_id)
    doc_dict = session_ref.get().to_dict()

    lat, lng = doc_dict['latitude'], doc_dict['longitude']

    nearby_url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
    params = {
        'location': f'{lat},{lng}',
        'radius': RADIUS,
        'type': 'restaurant',
        'key': os.environ.get('GCLOUD_MAPS_API_KEY')
        }

    resp = requests.get(url=nearby_url, params=params)
    return resp.json(), 200

    # fcm_headers = {
    #     'Content-Type': 'application/json',
    #     'Authorization': 'key=' + os.environ.get('FIREBASE_SERVER_KEY')
    # }

    # for device_id in doc_dict['device_ids']:
    #     fcm_body = {
    #         'to': device_id,
    #         'notification': {
    #             'title': 'start',
    #             'body': {
    #                 'restaurants': []
    #             }
    #         }
    #     }

    #     requests.post(
    #         url="https://fcm.googleapis.com/fcm/send",
    #         headers=fcm_headers,
    #         data=json.dumps(fcm_body)
    #     )


if __name__ == "__main__":
<<<<<<< HEAD
    app.run(port=4576, host='127.0.0.1', debug=True)
=======
    app.run(port=5000, host='0.0.0.0', debug=True)
>>>>>>> 43556fae1a765b08c30b198f129d4e4534330bc3
