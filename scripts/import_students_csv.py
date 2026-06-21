#!/usr/bin/env python3
"""
Import students from a CSV file into the Firestore `students` collection.

Usage:
    python import_students_csv.py <csv_file> [--dry-run]

The CSV must have at least these columns (case-insensitive, flexible naming):
    - application_no / Application No / application_number / NIU ID
    - payment_status / Payment Status
    - lead_id / Lead ID (optional — will default to empty string)

Any extra columns are ignored. The script uses merge writes so existing
fields (like `lastSyncedAt` from the auto-sync) are preserved.

Examples:
    python import_students_csv.py students_export.csv --dry-run
    python import_students_csv.py students_export.csv
"""

import csv
import sys
import os
import argparse
from datetime import datetime

# ── Firebase Admin setup ─────────────────────────────────────────────
import firebase_admin
from firebase_admin import credentials, firestore

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SERVICE_ACCOUNT_KEY = os.path.join(SCRIPT_DIR, "serviceAccountKey.json")

# ── Column name mapping (flexible) ──────────────────────────────────
# Maps various CSV column names to our canonical field names.
COLUMN_ALIASES = {
    "application_no": "application_no",
    "application_number": "application_no",
    "applicationno": "application_no",
    "niu id": "application_no",
    "niu_id": "application_no",
    "niuid": "application_no",
    "application no": "application_no",
    "application no.": "application_no",
    "payment_status": "payment_status",
    "payment status": "payment_status",
    "paymentstatus": "payment_status",
    "lead_id": "lead_id",
    "lead id": "lead_id",
    "leadid": "lead_id",
}


def normalize_header(header: str) -> str:
    """Map a CSV header to our canonical field name."""
    cleaned = header.strip().lower().replace("-", "_")
    return COLUMN_ALIASES.get(cleaned, cleaned)


def read_csv(filepath: str) -> list[dict]:
    """Read CSV and return list of student dicts with canonical keys."""
    students = []
    with open(filepath, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        if reader.fieldnames is None:
            print("ERROR: CSV has no headers")
            sys.exit(1)

        # Map headers
        header_map = {}
        for h in reader.fieldnames:
            canonical = normalize_header(h)
            header_map[h] = canonical

        print(f"CSV headers: {reader.fieldnames}")
        print(f"Mapped to:   {list(header_map.values())}")

        # Check required columns
        mapped_fields = set(header_map.values())
        if "application_no" not in mapped_fields:
            print("\nERROR: No 'application_no' column found.")
            print("Expected one of: Application No, application_no, NIU ID, etc.")
            sys.exit(1)
        if "payment_status" not in mapped_fields:
            print("\nWARNING: No 'payment_status' column — will default to 'Payment Pending'")

        for row in reader:
            mapped = {}
            for orig_key, value in row.items():
                canonical = header_map.get(orig_key, orig_key)
                mapped[canonical] = value.strip() if value else ""

            app_no = mapped.get("application_no", "").strip()
            if not app_no:
                continue  # skip blank rows

            students.append({
                "application_no": app_no,
                "payment_status": mapped.get("payment_status", "Payment Pending").strip() or "Payment Pending",
                "lead_id": mapped.get("lead_id", "").strip(),
            })

    return students


def import_to_firestore(students: list[dict], dry_run: bool = False):
    """Batch-write students to Firestore."""
    if not dry_run:
        if not os.path.exists(SERVICE_ACCOUNT_KEY):
            print(f"ERROR: {SERVICE_ACCOUNT_KEY} not found")
            print("Place your Firebase service account key file there.")
            sys.exit(1)

        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
        firebase_admin.initialize_app(cred)
        db = firestore.client()

    # Stats
    total = len(students)
    approved = sum(1 for s in students if s["payment_status"] == "Payment Approved")
    pending = total - approved

    print(f"\n{'DRY RUN — ' if dry_run else ''}Import summary:")
    print(f"  Total students:    {total}")
    print(f"  Payment Approved:  {approved}")
    print(f"  Payment Pending:   {pending}")
    print()

    if dry_run:
        # Show first 5 samples
        print("First 5 rows:")
        for s in students[:5]:
            print(f"  {s['application_no']:20s}  {s['payment_status']:20s}  {s['lead_id']}")
        if total > 5:
            print(f"  ... and {total - 5} more")
        print("\nRe-run without --dry-run to import.")
        return

    # Batch writes (max 500 per Firestore batch)
    batch_size = 500
    written = 0

    for i in range(0, total, batch_size):
        chunk = students[i:i + batch_size]
        batch = db.batch()

        for student in chunk:
            doc_ref = db.collection("students").document(student["application_no"])
            batch.set(doc_ref, {
                "application_no": student["application_no"],
                "payment_status": student["payment_status"],
                "lead_id": student["lead_id"],
                "lastSyncedAt": firestore.SERVER_TIMESTAMP,
                "importedFrom": "csv",
                "importedAt": firestore.SERVER_TIMESTAMP,
            }, merge=True)

        batch.commit()
        written += len(chunk)
        print(f"  Written {written}/{total}...")

    print(f"\nDone! {written} students imported to Firestore.")


def main():
    parser = argparse.ArgumentParser(
        description="Import students from CSV into Firestore"
    )
    parser.add_argument("csv_file", help="Path to the CSV file")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview without writing to Firestore",
    )
    args = parser.parse_args()

    if not os.path.exists(args.csv_file):
        print(f"ERROR: File not found: {args.csv_file}")
        sys.exit(1)

    students = read_csv(args.csv_file)
    if not students:
        print("No valid student rows found in CSV.")
        sys.exit(1)

    import_to_firestore(students, dry_run=args.dry_run)


if __name__ == "__main__":
    main()