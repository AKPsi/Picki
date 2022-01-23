import requests
import os
import uuid
import json
import sqlite3
from dotenv import load_dotenv
from flask import Flask, request
from firebase_admin import firestore, initialize_app


app = Flask(__name__)
load_dotenv()
initialize_app()
db = firestore.Client()

def connectToDB(path: str):
    con = sqlite3.connect(path)
    cur = con.cursor()
    return con, cur

def closeDB(con):
    con.close()


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
        u'likes': 0,
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

    for device_id in doc_dict['device_ids']:
        fcm_body = {
            'to': device_id,
            'notification': {
                'title': 'user_join',
                'body': {
                    'name': request.form['name'],
                    'device_id': request.form['device_id']
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
    nearby_params = {
        'location': f'{lat},{lng}',
        'rankby': 'distance',
        'type': 'restaurant',
        'key': os.environ.get('GCLOUD_MAPS_API_KEY')
        }

    nearby_resp = requests.get(url=nearby_url, params=nearby_params).json()
    restaurants = []
    added_set = set()
    i = -1
    while len(restaurants) < 10 and i + 1 < len(nearby_resp['results']):
        i += 1
        rest = nearby_resp['results'][i]
        required_fields = set(['name', 'rating', 'user_ratings_total', 'price_level', 'business_status', 'geometry'])
        if rest['name'] in added_set:
            continue
        if not all(key in rest for key in required_fields):
            continue
        if rest['business_status'] != 'OPERATIONAL':
            continue

        rest_coord = rest['geometry']['location']
        maps_dist_url = 'https://maps.googleapis.com/maps/api/distancematrix/json'
        dist_params = {
            'destinations': [f"{rest_coord['lat']},{rest_coord['lng']}"],
            'origins': [f'{lat},{lng}'],
            'units': 'imperial',
            'key': os.environ.get('GCLOUD_MAPS_API_KEY')
        }
        dist_resp = requests.get(maps_dist_url, params=dist_params).json()

        rest_place_id = rest['place_id']
        place_details_url = 'https://maps.googleapis.com/maps/api/place/details/json'
        place_details_params = {
            'place_id': rest_place_id,
            'fields': 'formatted_address',
            'key': os.environ.get('GCLOUD_MAPS_API_KEY')
            }
        place_details_resp = requests.get(place_details_url, params=place_details_params).json()

        new_rest = {}
        new_rest['name'] = rest['name']
        new_rest['rating'] = rest['rating']
        new_rest['num_ratings'] = rest['user_ratings_total']
        new_rest['price_level'] = rest['price_level']
        new_rest['address'] = place_details_resp['result']['formatted_address']
        new_rest['distance'] = dist_resp['rows'][0]['elements'][0]['distance']['text']
        added_set.add(rest['name'])
        restaurants.append(new_rest)

    session_ref.update({u'restaurants': firestore.ArrayUnion(restaurants)})

    for i in range(len(restaurants)):
        con, cur = connectToDB('app.db')
        cur.execute("INSERT INTO sessions(restaurant_id, likes, session) VALUES(?, ?, ?)", (i, 0, session_id))
        con.commit()
        closeDB(con)

    fcm_headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=' + os.environ.get('FIREBASE_SERVER_KEY')
    }

    for device_id in doc_dict['device_ids']:
        fcm_body = {
            'to': device_id,
            'notification': {
                'title': 'start',
                'body': {
                    'restaurants': restaurants
                }
            }
        }

        requests.post(
            url="https://fcm.googleapis.com/fcm/send",
            headers=fcm_headers,
            data=json.dumps(fcm_body)
        )

    return {'restaurants': restaurants}, 200


@app.route('/session/<session_id>/restaurant/<restaurant_id>', methods=['POST'])
def restaurantSwipe(session_id: str, restaurant_id: str):
    if 'like' not in request.form:
        return {
            'message': "Error! 'like' not found in request."
        }, 400
    if not db.collection(u'sessions').document(session_id).get().exists:
        return {
            'message': "Error! Invalid session ID."
        }, 400

    like = request.form['like']
    if like:
        con, cur = connectToDB('app.db')
        cur.execute("UPDATE sessions SET likes = likes + 1 WHERE restaurant_id = ? AND session = ?", (restaurant_id, session_id,))
        con.commit()
        closeDB(con)

    return {'Message': f"Vote for id {restaurant_id} in session {session_id} made."}, 200


if __name__ == "__main__":
    app.run(port=4576, host='127.0.0.1', debug=True)
