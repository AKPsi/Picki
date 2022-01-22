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


if __name__ == "__main__":
    app.run(port=4561, host='127.0.0.1', debug=True)
