import uuid
from flask import Flask, request
import firebase_admin
from firebase_admin import credentials, firestore

app = Flask(__name__)
cred = credentials.Certificate('firebaseServiceAccount.json')
firebase_admin.initialize_app(cred)
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
    # Generate a new session_id by grabbing first 6 values of a randomly
    # generated UUID and decode it to unicode for firestore.
    session_id = str(uuid.uuid4())[0:6]

    session_ref = db.collection(u'sessions').document(session_id)
    session_ref.set({
        u'device_ids': [device_id],
        u'user_address': '',
        u'restaurants': [],
        u'names': [name]
    })

    return {'session_id': session_id}, 201


if __name__ == "__main__":
    app.run(port=4561, host='127.0.0.1', debug=True)
