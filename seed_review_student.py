#!/usr/bin/env python3
"""
Seed the Play/App Store review-bypass student into Firestore.

Creates (or merges into) a single `students/NIU-26-15350` document so the
store reviewer can clear the fee gate and reach the dummy "review_demo"
paper. This is the student-collection counterpart to the OTP bypass
(REVIEW_BYPASS_ID / REVIEW_BYPASS_CODE) in functions and the fetchLeadDetails
routing to courseKey "review_demo".

The `students` collection is normally written ONLY by the NPF sync Cloud
Function (syncStudents.ts) and import_students_csv.py. NPF has no such lead,
so this reviewer doc must be seeded by hand. syncStudents uses merge writes
and never deletes docs that NPF omits, so this seeded doc survives the
every-30-minute sync.

Field names match StudentModel.fromFirestore / syncStudents.ts exactly:
    application_no  -> doc id and field
    payment_status  -> "Payment Approved"  (the string isFeeApproved checks)
    lead_id         -> "NIU-26-15350"       (what the client passes into
                                             fetchLeadDetails; must equal
                                             REVIEW_BYPASS_ID for the bypass)

# REMOVE BEFORE June 14 exam
This reviewer student doc must be deleted together with the OTP bypass and
the fetchLeadDetails review routing. Run with --delete to remove it.

BEFORE RUNNING
    1. pip install firebase-admin
    2. Place a service account key for nsat-niu-app at serviceAccountKey.json
       next to this script (same key import_students_csv.py uses).

RUN
    python seed_review_student.py            # create / merge the reviewer doc
    python seed_review_student.py --dry-run  # print without writing
    python seed_review_student.py --delete   # remove the reviewer doc
"""

import os
import argparse

import firebase_admin
from firebase_admin import credentials, firestore

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SERVICE_ACCOUNT_KEY = os.path.join(SCRIPT_DIR, "serviceAccountKey.json")

# Must match REVIEW_BYPASS_ID in functions/.env and the OTP bypass.
REVIEW_BYPASS_ID = "NIU-26-15350"

REVIEW_STUDENT = {
    "application_no": REVIEW_BYPASS_ID,
    "payment_status": "Payment Approved",  # exact string StudentModel.isFeeApproved checks
    "lead_id": REVIEW_BYPASS_ID,           # what fetchLeadDetails receives; must == REVIEW_BYPASS_ID
    "importedFrom": "review_bypass_seed",
}


def get_db():
    if not os.path.exists(SERVICE_ACCOUNT_KEY):
        raise SystemExit(
            f"ERROR: {SERVICE_ACCOUNT_KEY} not found.\n"
            "Place your nsat-niu-app service account key there."
        )
    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
    firebase_admin.initialize_app(cred)
    return firestore.client()


def main():
    parser = argparse.ArgumentParser(
        description="Seed (or delete) the review-bypass student doc."
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Print what would be written without touching Firestore",
    )
    parser.add_argument(
        "--delete", action="store_true",
        help="Delete the reviewer student doc instead of creating it",
    )
    args = parser.parse_args()

    action = "DELETE" if args.delete else "WRITE"
    print(f"{'DRY RUN — ' if args.dry_run else ''}{action} students/{REVIEW_BYPASS_ID}")
    if not args.delete:
        for k, v in REVIEW_STUDENT.items():
            print(f"  {k}: {v}")

    if args.dry_run:
        print("\n--dry-run: nothing written.")
        return

    db = get_db()
    doc_ref = db.collection("students").document(REVIEW_BYPASS_ID)

    if args.delete:
        doc_ref.delete()
        print(f"\nDeleted students/{REVIEW_BYPASS_ID}.")
        return

    payload = dict(REVIEW_STUDENT)
    payload["lastSyncedAt"] = firestore.SERVER_TIMESTAMP
    payload["importedAt"] = firestore.SERVER_TIMESTAMP
    # merge=True so a later NPF sync (which never deletes) can't clobber the doc
    # and so re-running this script is idempotent.
    doc_ref.set(payload, merge=True)
    print(f"\nDone. students/{REVIEW_BYPASS_ID} is fee-approved and routes to review_demo.")


if __name__ == "__main__":
    main()
