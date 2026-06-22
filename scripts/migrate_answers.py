import sys
import argparse
import firebase_admin
from firebase_admin import credentials, firestore

def main():
    parser = argparse.ArgumentParser(description="Migrate answers from questions collection to answers collection.")
    parser.add_argument("mode", choices=["copy", "cleanup"], help="Mode: 'copy' to copy fields, 'cleanup' to delete fields from questions")
    parser.add_argument("--key", default="serviceAccountKey.json", help="Path to the Firebase service account key")
    args = parser.parse_args()

    cred = credentials.Certificate(args.key)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    questions_ref = db.collection("questions")
    docs = list(questions_ref.stream())

    print(f"Found {len(docs)} questions.")
    batch = db.batch()
    ops = 0
    total_processed = 0

    if args.mode == "copy":
        print("Starting COPY mode...")
        for doc in docs:
            data = doc.to_dict()
            answer_data = {}
            if "correctAnswerIndex" in data:
                answer_data["correctAnswerIndex"] = data["correctAnswerIndex"]
            if "correctAnswerTexts" in data:
                answer_data["correctAnswerTexts"] = data["correctAnswerTexts"]
            
            if answer_data:
                ans_ref = db.collection("answers").document(doc.id)
                batch.set(ans_ref, answer_data, merge=True)
                ops += 1
                total_processed += 1
            
            if ops >= 400:
                batch.commit()
                batch = db.batch()
                ops = 0
                print(f"  Committed batch (total {total_processed})...")
        
        if ops > 0:
            batch.commit()
            print(f"  Committed final batch (total {total_processed}).")
        print("Copy complete.")

    elif args.mode == "cleanup":
        print("Starting CLEANUP mode...")
        for doc in docs:
            data = doc.to_dict()
            updates = {}
            if "correctAnswerIndex" in data:
                updates["correctAnswerIndex"] = firestore.DELETE_FIELD
            if "correctAnswerTexts" in data:
                updates["correctAnswerTexts"] = firestore.DELETE_FIELD
            
            if updates:
                batch.update(doc.reference, updates)
                ops += 1
                total_processed += 1
            
            if ops >= 400:
                batch.commit()
                batch = db.batch()
                ops = 0
                print(f"  Committed batch (total {total_processed})...")
        
        if ops > 0:
            batch.commit()
            print(f"  Committed final batch (total {total_processed}).")
        print("Cleanup complete.")

if __name__ == "__main__":
    main()
