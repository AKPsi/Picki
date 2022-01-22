from google.cloud import firestore
from firebase_admin import messaging

db = firestore.Client()

message = messaging.Message(
    notification = messaging.Notification(
        title = "notification"
    ),
    data = {
        'newActivity': 'True'
    }, 
    token="dNge2OfQN0wLiXluAvfGmw:APA91bFkwp_XeKHAwBn-MSkGb_kyn04wf0B9cfCqVPlRF1FM2h-cpeR5W9TLpB0Afuj9HMX8EIWjHC7NqQ5to4xN194dGb6n4Epoyzc8oik0bY_mNLFea_MwH2yOfl44cWaF3_vWFWir"
)

messaging.send(message)