#!/usr/bin/env python3
"""
NSAT — Firestore seed script.

Seeds the `questions` and `tests` collections from the filled Excel
question bank, for the nsat-niu-app Firebase project.

WHAT IT DOES
  - Reads the Questions sheet  -> writes `questions` documents
  - Reads the Test Config sheet -> writes `tests` documents
  - Maps the Excel's letter answer (A/B/C/D) to correctAnswerIndex (0-3)
  - Maps the Excel's display course name to a canonical course KEY

CANONICAL COURSE KEY
  The Excel says "B.Tech / Engineering" (slash + spaces) — fragile as a
  join key. This script writes the canonical key "btech" into both
  `questions.course` and `tests.course`, so they match byte-for-byte.
  The pretty name is kept in `tests.title` for display. Add new courses
  to COURSE_KEY_MAP below.

BEFORE RUNNING
  1. In the Firebase console, confirm `questions` and `tests` are EMPTY.
     This script does not de-duplicate; running twice doubles the data.
  2. pip install openpyxl firebase-admin
  3. Download a service account key for nsat-niu-app:
     Firebase console -> Project settings -> Service accounts ->
     Generate new private key. Save as serviceAccountKey.json next to
     this script. NEVER commit that file — add it to .gitignore.

RUN
  python seed_firestore.py NIU-SAT_BTech_Aptitude_QuestionBank.xlsx
  Add --dry-run to print what would be written without touching Firestore.
"""

import sys
import argparse
import openpyxl

# --- Canonical course keys -------------------------------------------------
# Excel display name  ->  canonical key used in Firestore `course` fields.
COURSE_KEY_MAP = {
    "B.Tech / Engineering": "btech",
}

LETTER_TO_INDEX = {"A": 0, "B": 1, "C": 2, "D": 3}

# Header row (1-indexed) and first data row on each sheet.
QUESTIONS_HEADER_ROW = 4
TEST_CONFIG_HEADER_ROW = 4


def course_key(display_name):
    name = (display_name or "").strip()
    if name not in COURSE_KEY_MAP:
        raise ValueError(
            f"Course '{name}' has no canonical key. "
            f"Add it to COURSE_KEY_MAP before seeding."
        )
    return COURSE_KEY_MAP[name]


def parse_questions(workbook):
    """Returns a list of dicts ready for the `questions` collection."""
    ws = workbook["Questions"]
    out = []
    for i, row in enumerate(
        ws.iter_rows(min_row=QUESTIONS_HEADER_ROW + 1, values_only=True)
    ):
        course, qtext, a, b, c, d, correct, topic = row[:8]
        if course in (None, ""):
            continue  # blank trailing row

        excel_row = QUESTIONS_HEADER_ROW + 1 + i

        letter = (correct or "").strip().upper()
        if letter not in LETTER_TO_INDEX:
            raise ValueError(
                f"Questions row {excel_row}: correct_option is '{correct}', "
                f"expected one of A/B/C/D."
            )

        options = [a, b, c, d]
        if any(o in (None, "") for o in options):
            raise ValueError(
                f"Questions row {excel_row}: one or more options are blank."
            )
        if qtext in (None, ""):
            raise ValueError(f"Questions row {excel_row}: question_text is blank.")

        out.append(
            {
                "text": str(qtext).strip(),
                "options": [str(o).strip() for o in options],
                "correctAnswerIndex": LETTER_TO_INDEX[letter],
                "course": course_key(course),
                "topic": str(topic).strip() if topic not in (None, "") else "",
            }
        )
    return out


def parse_tests(workbook):
    """Returns a list of dicts ready for the `tests` collection."""
    ws = workbook["Test Config"]
    out = []
    for i, row in enumerate(
        ws.iter_rows(min_row=TEST_CONFIG_HEADER_ROW + 1, values_only=True)
    ):
        (course, title, qcount, duration, marks,
         neg_marking, neg_marks, published) = row[:8]
        if course in (None, ""):
            continue

        excel_row = TEST_CONFIG_HEADER_ROW + 1 + i

        def yes_no(v, field):
            s = str(v).strip().lower()
            if s in ("yes", "true", "1"):
                return True
            if s in ("no", "false", "0"):
                return False
            raise ValueError(
                f"Test Config row {excel_row}: {field} is '{v}', "
                f"expected yes/no."
            )

        out.append(
            {
                "title": str(title).strip(),
                "course": course_key(course),
                "questionCount": int(qcount),
                "durationMinutes": int(duration),
                "marksPerQuestion": float(marks),
                "negativeMarking": yes_no(neg_marking, "negative_marking"),
                "negativeMarksPerWrong": float(neg_marks),
                "isPublished": yes_no(published, "published"),
            }
        )
    return out


def validate(questions, tests):
    """Cross-checks the two sheets before anything is written."""
    q_courses = {q["course"] for q in questions}
    t_courses = {t["course"] for t in tests}

    missing_test = q_courses - t_courses
    if missing_test:
        raise ValueError(
            f"Questions exist for course(s) {missing_test} but no test "
            f"is configured for them."
        )

    for t in tests:
        available = sum(1 for q in questions if q["course"] == t["course"])
        if available < t["questionCount"]:
            raise ValueError(
                f"Test '{t['title']}' wants {t['questionCount']} questions "
                f"but only {available} exist for course '{t['course']}'."
            )


def main():
    parser = argparse.ArgumentParser(description="Seed NSAT Firestore.")
    parser.add_argument("excel", help="Path to the filled question-bank xlsx")
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Print what would be written without touching Firestore",
    )
    parser.add_argument(
        "--key", default="serviceAccountKey.json",
        help="Path to the Firebase service account key",
    )
    args = parser.parse_args()

    workbook = openpyxl.load_workbook(args.excel, data_only=True)
    questions = parse_questions(workbook)
    tests = parse_tests(workbook)
    validate(questions, tests)

    print(f"Parsed {len(questions)} question(s) and {len(tests)} test(s).")
    for t in tests:
        n = sum(1 for q in questions if q["course"] == t["course"])
        print(f"  - test '{t['title']}' (course={t['course']}, "
              f"published={t['isPublished']}) <- {n} questions")

    if args.dry_run:
        print("\n--dry-run: nothing written. Sample question document:")
        print(questions[0])
        print("Sample test document:")
        print(tests[0])
        return

    # --- Real write path -------------------------------------------------
    import firebase_admin
    from firebase_admin import credentials, firestore

    cred = credentials.Certificate(args.key)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    # Batched writes (Firestore batch limit is 500 ops).
    batch = db.batch()
    ops = 0
    for q in questions:
        ref = db.collection("questions").document()  # auto-id
        batch.set(ref, q)
        ops += 1
        if ops == 450:
            batch.commit()
            batch = db.batch()
            ops = 0
    for t in tests:
        ref = db.collection("tests").document()  # auto-id
        batch.set(ref, t)
        ops += 1
    if ops:
        batch.commit()

    print(f"\nDone. Wrote {len(questions)} questions and {len(tests)} tests "
          f"to Firestore.")


if __name__ == "__main__":
    main()