#!/usr/bin/env python3
"""
Check Firestore Call Document
"""

from google.cloud import firestore

PROJECT_ID = 'my-project-54928-b9704'
USER_ID = '7wll6D15YZgVrL7jEO1dJhyCUKG3'
CALL_ID = 'test_call_1760574708863'

def check_call_document():
    db = firestore.Client(project=PROJECT_ID)

    doc_ref = db.collection('users').document(USER_ID).collection('calls').document(CALL_ID)
    doc = doc_ref.get()

    if doc.exists:
        print("=" * 60)
        print(f"📄 Call Document: {CALL_ID}")
        print("=" * 60)
        data = doc.to_dict()
        for key, value in sorted(data.items()):
            print(f"{key:20s}: {value}")
        print("=" * 60)
    else:
        print(f"❌ Document not found: {CALL_ID}")

if __name__ == "__main__":
    check_call_document()
