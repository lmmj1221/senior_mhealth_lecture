#!/usr/bin/env python3
"""
Test Audio Upload Script
Firestore Î¨∏ÏÑú ?ùÏÑ± + Storage ?åÏùº ?ÖÎ°ú???êÎèô??"""

import os
import sys
from datetime import datetime
from google.cloud import firestore
from google.cloud import storage

# ?ÑÎ°ú?ùÌä∏ ?§Ï†ï
PROJECT_ID = 'senior-mhealth-202373080'
STORAGE_BUCKET = 'senior-mhealth-202373080.firebasestorage.app'
USER_ID = 'sample_user'
SENIOR_ID = 'test_senior_001'

def create_call_document(call_id):
    """Firestore??call Î¨∏ÏÑú ?ùÏÑ±"""
    print(f"?ìù Creating Firestore document...")

    db = firestore.Client(project=PROJECT_ID)

    call_data = {
        'userId': USER_ID,
        'seniorId': SENIOR_ID,
        'callId': call_id,
        'status': 'pending',
        'analysisStatus': 'waiting',
        'createdAt': firestore.SERVER_TIMESTAMP,
        'updatedAt': firestore.SERVER_TIMESTAMP
    }

    doc_ref = db.collection('users').document(USER_ID).collection('calls').document(call_id)
    doc_ref.set(call_data)

    print(f"??Firestore document created: users/{USER_ID}/calls/{call_id}")

def upload_to_storage(local_file_path, call_id):
    """Storage???åÏùº ?ÖÎ°ú??""
    print(f"?ì§ Uploading file to Storage...")

    storage_client = storage.Client(project=PROJECT_ID)
    bucket = storage_client.bucket(STORAGE_BUCKET)

    # Storage Í≤ΩÎ°ú ?ùÏÑ±
    file_name = os.path.basename(local_file_path)
    storage_path = f"calls/{USER_ID}/{SENIOR_ID}/{call_id}/{file_name}"

    blob = bucket.blob(storage_path)
    blob.upload_from_filename(local_file_path)

    print(f"??File uploaded to: gs://{STORAGE_BUCKET}/{storage_path}")
    return storage_path

def main():
    # ?åÏùº Í≤ΩÎ°ú ?§Ï†ï
    if len(sys.argv) >= 2:
        local_file_path = sys.argv[1]
    else:
        # ?∏ÏûêÍ∞Ä ?ÜÏúºÎ©?data ?¥Îçî?êÏÑú Ï≤?Î≤àÏß∏ m4a ?åÏùº ?¨Ïö©
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(script_dir)
        data_dir = os.path.join(project_root, 'data')

        m4a_files = [f for f in os.listdir(data_dir) if f.endswith('.m4a')]

        if not m4a_files:
            print("??No .m4a files found in data folder")
            sys.exit(1)

        local_file_path = os.path.join(data_dir, m4a_files[0])
        print(f"?ìÅ Auto-selected file: {m4a_files[0]}")

    # ?åÏùº Ï°¥Ïû¨ ?ïÏù∏
    if not os.path.exists(local_file_path):
        print(f"??File not found: {local_file_path}")
        sys.exit(1)

    # Call ID ?ùÏÑ±
    timestamp = int(datetime.now().timestamp() * 1000)
    call_id = f"test_call_{timestamp}"

    print("=" * 60)
    print("?? Starting Upload Process")
    print("=" * 60)
    print(f"Project ID: {PROJECT_ID}")
    print(f"User ID: {USER_ID}")
    print(f"Senior ID: {SENIOR_ID}")
    print(f"Call ID: {call_id}")
    print(f"Local File: {local_file_path}")
    print("=" * 60)

    try:
        # 1. Firestore Î¨∏ÏÑú ?ùÏÑ±
        create_call_document(call_id)

        # 2. Storage???åÏùº ?ÖÎ°ú??        storage_path = upload_to_storage(local_file_path, call_id)

        print("=" * 60)
        print("?éâ Upload Complete!")
        print("=" * 60)
        print(f"?ìã Call ID: {call_id}")
        print(f"?ìÅ Storage Path: {storage_path}")
        print(f"?îç Monitor logs with:")
        print(f"   gcloud functions logs read processVoiceFile --limit=20")
        print("=" * 60)

    except Exception as e:
        print(f"??Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
