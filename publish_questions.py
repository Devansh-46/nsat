import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

docs = db.collection('questions').where('course', '==', 'BTECH').get()
if not docs:
    print('No questions found. Creating some...')
    for i in range(5):
        db.collection('questions').add({
            'course': 'BTECH',
            'text': f'Sample Question {i+1} for B.Tech',
            'type': 'multipleChoice',
            'options': ['Option A', 'Option B', 'Option C', 'Option D'],
            'correctAnswerIndex': 0,
            'topic': 'General'
        })
    print('Questions created!')
