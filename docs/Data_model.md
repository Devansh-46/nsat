# NSAT — Firestore Data Model

This document is the single source of truth for the NSAT database structure.
Create the collections, write the security rules, and build the app's data layer
against this document. Keep it updated whenever the structure changes.

**Database:** Cloud Firestore
**Last updated:** 18 May 2026

---

## Overview

The app uses **six collections**:

| Collection | Purpose | Written by |
|---|---|---|
| `students`  | Applicant list synced from NoPaperForms (NPF) | NPF sync function only |
| `tests`     | Test configuration per course | Project team / admin (Phase 2) |
| `questions` | The question bank | Project team / admin (Phase 2) |
| `results`   | One record per completed test | Student app, on submission |
| `attempts`  | The one-attempt lock | Student app, when a test starts |
| `otps`      | Short-lived email verification codes | Cloud Functions only |

**Key principle:** `students`, `attempts`, and `otps` are all keyed by the
**NIU ID** (the student's `application_no`). Keeping them as separate
collections means the 30-minute NPF sync — which overwrites `students` — can
never erase a student's attempt lock or OTP state.

---

## 1. `students`

A local copy of NPF applicant data, refreshed every 30 minutes by the sync
function. The app reads this collection to check fee status at login.

- **Document ID:** `application_no` (the NIU ID)
- **Written by:** the NPF sync Cloud Function only. The app never writes here.

| Field | Type | Description |
|---|---|---|
| `application_no` | string | NIU ID. Same as the document ID. |
| `payment_status` | string | From NPF. Either `"Payment Approved"` or `"Payment Pending"`. |
| `lead_id`        | string | NPF lead identifier. Used to fetch the registered email at login. |
| `lastSyncedAt`   | timestamp | When this record was last refreshed from NPF. |

**Notes**
- The registered email is **not** stored here — it is fetched live from NPF
  via `lead_id` during login.
- Fee gate rule: only `payment_status == "Payment Approved"` may proceed.
  Any other value (including `"Payment Pending"`) is treated as not paid.

---

## 2. `tests`

One document per course's test configuration.

- **Document ID:** auto-generated
- **Written by:** project team directly (Phase 1); admin app (Phase 2)

| Field | Type | Description |
|---|---|---|
| `title`                 | string  | Test title shown to students. |
| `course`                | string  | Course / programme this test belongs to. |
| `questionCount`         | number  | How many questions the test presents. |
| `durationMinutes`       | number  | Test length in minutes. |
| `marksPerQuestion`      | number  | Marks awarded per correct answer. |
| `negativeMarking`       | boolean | Whether wrong answers lose marks. |
| `negativeMarksPerWrong` | number  | Marks deducted per wrong answer. `0` if no negative marking. |
| `isPublished`           | boolean | If `true`, the test is live for students. |

---

## 3. `questions`

One document per question. The question bank is seeded from the Excel template.

- **Document ID:** auto-generated
- **Written by:** project team via seed script (Phase 1); admin app (Phase 2)

| Field | Type | Description |
|---|---|---|
| `text`               | string | The question text. |
| `options`            | array of string | The answer choices (4 options). |
| `correctAnswerIndex` | number | Index (0–3) of the correct option. |
| `course`             | string | Course this question belongs to. Must match a `tests.course` value. |
| `topic`              | string | Optional topic tag. |

**Note:** `correctAnswerIndex` is sensitive — security rules must prevent the
student app from reading it directly. The score is calculated in a trusted
place (Cloud Function), not on the device. See Security Rules below.

---

## 4. `results`

One document per completed test, written when a student submits.

- **Document ID:** auto-generated
- **Written by:** the student app, once, on submission

| Field | Type | Description |
|---|---|---|
| `application_no` | string | NIU ID of the student. |
| `studentName`    | string | Student's name. |
| `course`         | string | Course the test was for. |
| `testId`         | string | Reference to the `tests` document used. |
| `correctCount`   | number | Number of correct answers. |
| `wrongCount`     | number | Number of wrong answers. |
| `skippedCount`   | number | Number of unanswered questions. |
| `netScore`       | number | Final score after negative marking. |
| `maxScore`       | number | Maximum possible score. |
| `submittedAt`    | timestamp | When the test was submitted. |

---

## 5. `attempts`

Enforces the one-attempt rule. A document existing here means that student has
already taken the test.

- **Document ID:** `application_no` (the NIU ID)
- **Written by:** the student app, when a test starts

| Field | Type | Description |
|---|---|---|
| `hasAttempted` | boolean | Always `true` when the document exists. |
| `attemptedAt`  | timestamp | When the attempt began. |

**Notes**
- The attempt check is a fast read: "does a document with this NIU ID exist?"
- This document should be created in the **same transaction** that starts the
  test, so a student cannot start two tests at once.
- This collection is never touched by the NPF sync.

---

## 6. `otps`

Short-lived email verification codes. One document per student login attempt.

- **Document ID:** `application_no` (the NIU ID)
- **Written by:** Cloud Functions only. The app never reads or writes here directly.

| Field | Type | Description |
|---|---|---|
| `codeHash`  | string | The OTP code, **hashed** — never stored in plain text. |
| `expiresAt` | timestamp | When the code expires (recommended: 10 minutes after creation). |
| `verified`  | boolean | `true` once the student enters the correct code. |
| `createdAt` | timestamp | When the code was generated. |

**Notes**
- The code is generated, hashed, and verified inside Cloud Functions. The app
  only sends the code the user typed and receives a pass/fail result.
- An expired or already-verified code must be rejected.
- A new login overwrites the previous document for that NIU ID.

---

## Security Rules — intent

Detailed rules are written separately, but the data model assumes:

- `students` — readable by the app for the fee check; **writable only** by the
  sync function (server-side).
- `tests` — readable by the app; not writable by the app.
- `questions` — the app may read question text and options, but **not**
  `correctAnswerIndex`. Scoring happens server-side.
- `results` — the app may create its own result; it must not edit others'.
- `attempts` — the app may create its own attempt lock; it must not delete it.
- `otps` — **not** accessible from the app at all; Cloud Functions only.

---

## Identifiers — summary

| Identifier | What it is | Where it comes from |
|---|---|---|
| `application_no` | NIU ID — the primary key for a student | Entered by the student; matches NPF |
| `lead_id` | NPF's internal lead key | Synced from NPF; used to fetch email |
| `testId` | A `tests` document reference | Generated when a test is created |

The **NIU ID (`application_no`)** is the identifier that ties a student across
`students`, `attempts`, `otps`, and `results`.
