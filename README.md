<div align="center">

# 🎓 NSAT — NIU Student Aptitude Test

### A mobile & web application for conducting online aptitude tests for admission candidates at Noida International University.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Blaze-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20iOS-blueviolet)]()
[![Functions](https://img.shields.io/badge/Cloud%20Functions-5%20deployed-4285F4?logo=googlecloud&logoColor=white)]()
[![Status](https://img.shields.io/badge/Status-Pre--Launch-brightgreen)]()

</div>

---

## 📖 Overview

**NSAT** lets admission candidates take their aptitude test online — from a phone or a web browser, at home. The app verifies that a candidate has paid their application fee via NoPaperForms, confirms their identity by email OTP, runs a timed multiple-choice test, and records the result.

The app is built once in **Flutter** and runs on **Android, Web, and iOS** from a single codebase, with **Firebase** as the backend and **Cloud Functions** handling all server-side logic.

> **Status:** Pre-launch. All student screens, Cloud Functions, NPF integration, email OTP, server-side scoring, and security rules are complete. The target is the **14 June 2026** entrance test with a dry run around 7 June.

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🔐 **NIU ID login** | Students log in with their NIU ID (application number). |
| 💳 **Automatic fee check** | Real-time fee verification via NoPaperForms API — no manual checking. |
| 🔄 **Auto-sync from NPF** | Student data synced from NoPaperForms every 30 minutes via Cloud Function. |
| 📧 **Email OTP verification** | 6-digit code sent to registered email; hashed server-side with 10-min expiry and 5-attempt limit. |
| 📝 **Timed test** | Multiple-choice test with countdown timer, question palette, and auto-submit. |
| 🔒 **Server-side scoring** | Answers scored by Cloud Function — the client never sees the answer key. |
| 📊 **Instant results** | Score breakdown — correct, wrong, skipped — shown immediately. |
| 🔒 **One attempt only** | Transactional attempt lock with crash-safe status tracking. |
| 🔔 **Announcements** | Push notifications for test reminders and updates (Phase 2 for real delivery). |
| 🌐 **Cross-platform** | One codebase for Android, Web, and iOS. |
| 🎨 **Verdant Daylight UI** | Custom design system — mesh backgrounds, glass-morphism cards, Instrument Serif typography. |

---

## 🧭 How It Works — Student Journey

```
  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
  │  Enter NIU   │ ──▶ │  Fee check   │ ──▶ │ Fetch lead   │
  │     ID       │     │  (Firestore) │     │ details (NPF)│
  └──────────────┘     └──────┬───────┘     └──────┬───────┘
                              │                    │
                       not paid │                    │ approved
                              ▼                    ▼
                       ┌──────────────┐     ┌──────────────┐
                       │ "Fee not     │     │  Email OTP   │
                       │  paid" screen│     │ (6-digit)    │
                       └──────────────┘     └──────┬───────┘
                                                   │ verified
                                                   ▼
                       ┌──────────────┐     ┌──────────────┐
                       │   Result &   │ ◀── │  Take timed  │
                       │ score (server│     │     test     │
                       │   scored)    │     │              │
                       └──────────────┘     └──────────────┘
```

1. **Enter NIU ID** — student opens the app and enters their NIU ID.
2. **Fee check** — reads the `students` collection (synced from NPF every 30 min).
3. **Lead details** — Cloud Function calls NPF API to fetch name, course, email.
4. **Email OTP** — Cloud Function sends a 6-digit code; student verifies.
5. **Take the test** — timed test with question palette and progress tracking.
6. **Server-side scoring** — Cloud Function scores, writes result, flips attempt lock.
7. **Result** — score and breakdown shown instantly. One attempt only.

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart) — Android, Web, iOS from one codebase |
| **State management** | Provider |
| **Backend** | Firebase (Blaze plan) |
| **Database** | Cloud Firestore (asia-south1) |
| **Server logic** | Cloud Functions v2 (TypeScript, Node 20) |
| **Email** | Nodemailer via SMTP |
| **Notifications** | Firebase Cloud Messaging (Phase 2) |
| **Fee data source** | Meritto / NoPaperForms API (access-key + secret-key auth) |
| **Design system** | Verdant Daylight — Instrument Serif, Inter, JetBrains Mono |

---

## ☁️ Cloud Functions (5 deployed)

All functions run in `asia-south1`.

| Function | Type | Purpose |
|---|---|---|
| `syncStudents` | Scheduled (every 30 min) | Calls NPF API 1, batch-writes `students` collection |
| `fetchLeadDetails` | Callable | Calls NPF API 2 by lead_id, returns name/course/email |
| `sendOtp` | Callable | Generates 6-digit code, hashes to `otps`, emails via SMTP |
| `verifyOtp` | Callable | Checks hash, 5-attempt limit, 10-min expiry |
| `scoreSubmission` | Callable | Reads questions server-side, scores, writes result, flips attempt lock |

### Environment Variables (`functions/.env`)

```env
NPF_ACCESS_KEY=...       # NoPaperForms API access key
NPF_SECRET_KEY=...       # NoPaperForms API secret key
NPF_BASE_URL=https://api.nopaperforms.com
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=...            # Email address for OTP sending
SMTP_PASS=...            # App password (not your login password)
OTP_FROM_NAME=NSAT NIU
```

---

## 🗄️ Data Model

Six Firestore collections. The `students` data is kept in sync with NoPaperForms automatically.

| Collection | Purpose | Keyed by | Written by |
|---|---|---|---|
| `students` | Applicant list synced from NPF (application number, payment status, lead ID) | NIU ID | Cloud Function |
| `tests` | Test configuration per course — question count, duration, marks, negative marking | Auto ID | Seed script |
| `questions` | Question bank — text, options, correct answer, course | Auto ID | Seed script |
| `results` | Record per completed test — score breakdown, timestamp | Auto ID | Cloud Function |
| `attempts` | One-attempt lock with crash-safe status (`in_progress` → `completed`) | NIU ID | Client + Cloud Function |
| `otps` | Short-lived hashed email verification codes (10-min expiry) | NIU ID | Cloud Function |

> `students` is refreshed automatically every 30 minutes. `attempts` and `otps` are kept in separate collections so the NPF sync can never overwrite them.

---

## 📁 Project Structure

```
nsat/
├── lib/
│   ├── main.dart                     # Entry point, providers, routes
│   ├── models/                       # Data models
│   │   ├── student_model.dart
│   │   ├── lead_details_model.dart
│   │   ├── test_model.dart
│   │   ├── question_model.dart
│   │   ├── result_model.dart
│   │   ├── attempt_model.dart
│   │   ├── test_session_model.dart
│   │   ├── user_model.dart           # Admin only
│   │   └── notification_model.dart
│   ├── providers/                    # State management (Provider)
│   │   ├── auth_provider.dart        # Fee gate + NPF lead fetch
│   │   ├── test_provider.dart        # Test flow + server scoring
│   │   └── admin_provider.dart       # Admin dashboard + results
│   ├── services/                     # Data & business logic
│   │   ├── student_service.dart
│   │   ├── test_service.dart
│   │   ├── question_service.dart     # _stripAnswers = true
│   │   ├── scoring_service.dart      # Calls scoreSubmission Cloud Function
│   │   ├── attempt_service.dart
│   │   ├── result_service.dart
│   │   ├── admin_service.dart
│   │   ├── results_exporter.dart     # CSV export (mobile)
│   │   ├── auth_service.dart
│   │   └── notification_service.dart
│   ├── screens/
│   │   ├── student/                  # Student-facing (Verdant Daylight)
│   │   │   ├── role_selection_screen.dart
│   │   │   ├── student_login_screen.dart
│   │   │   ├── email_verification_screen.dart  # Real OTP flow
│   │   │   ├── test_category_screen.dart
│   │   │   ├── live_test_screen.dart
│   │   │   └── result_screen.dart
│   │   └── admin/
│   │       ├── admin_login_screen.dart
│   │       ├── admin_dashboard_screen.dart
│   │       ├── results_dashboard_screen.dart
│   │       └── push_notification_screen.dart
│   ├── widgets/                      # Design system components
│   │   ├── mesh_background.dart      # 4-colour radial mesh
│   │   ├── glass_card.dart           # Backdrop-blur glass card
│   │   ├── eyebrow.dart              # Uppercase tracked label
│   │   ├── note_box.dart             # Gold/green/clay semantic boxes
│   │   ├── niu_button.dart           # Pill button with variants
│   │   └── niu_field.dart            # Glass input field
│   ├── theme/
│   │   ├── app_colors.dart           # 61 Verdant Daylight tokens
│   │   └── app_theme.dart            # Instrument Serif / Inter / JetBrains Mono
│   └── routes/
│       └── app_routes.dart
├── functions/                        # Firebase Cloud Functions (TypeScript)
│   ├── src/
│   │   ├── index.ts                  # Re-exports all functions
│   │   ├── config.ts                 # NPF creds, SMTP config, course key map
│   │   ├── syncStudents.ts           # Scheduled NPF sync
│   │   ├── fetchLeadDetails.ts       # Callable: NPF lead lookup
│   │   ├── otp.ts                    # sendOtp + verifyOtp
│   │   └── scoreSubmission.ts        # Server-side scoring
│   ├── package.json
│   ├── tsconfig.json
│   ├── .env                          # Real credentials (not committed)
│   └── .env.example                  # Template
├── firebase.json
├── firestore.rules                   # Tightened security rules
├── seed_firestore.py                 # Python script to seed questions + tests
├── pubspec.yaml
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Node.js 20+ (for Cloud Functions)
- An IDE — VS Code or Android Studio

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/Devansh-46/niu-sat.git
cd nsat

# 2. Install Flutter dependencies
flutter pub get

# 3. Configure Firebase (maintainer step)
flutterfire configure

# 4. Set up Cloud Functions
cd functions
cp .env.example .env
# Edit .env with real NPF keys and SMTP credentials
npm install
npm run build

# 5. Deploy functions and rules
cd ..
firebase deploy --only functions
firebase deploy --only firestore:rules

# 6. Seed the question bank
pip install openpyxl firebase-admin
python seed_firestore.py

# 7. Run the app
flutter run            # mobile
flutter run -d chrome  # web
```

### Manual NPF Sync Trigger

The `syncStudents` function runs automatically every 30 minutes. To trigger it manually:

```bash
# Option 1: Via Firebase Console
# Go to Functions → syncStudents → "Run in Cloud Scheduler" → Force Run

# Option 2: Via gcloud CLI
gcloud scheduler jobs run firebase-schedule-syncStudents-asia-south1 \
  --project=nsat-niu-app --location=asia-south1
```

Check the sync logs:

```bash
firebase functions:log --only syncStudents
```

---

## 📦 Project Phases

<table>
<tr>
<th>Phase 1 — June 14 Launch ✅</th>
<th>Phase 2 — Post-Launch</th>
</tr>
<tr>
<td valign="top">

- NIU ID login + fee gate
- NPF auto-sync (every 30 min)
- Live NPF lead fetch (Cloud Function)
- Email OTP verification
- Timed test flow
- Server-side scoring
- Results & score breakdown
- One-attempt lock (crash-safe)
- Verdant Daylight UI redesign
- Admin dashboard + CSV export
- Tightened Firestore security rules
- Android + Web

</td>
<td valign="top">

- Admin test & question management UI
- Results write-back to NoPaperForms
- Scheduled push notifications (FCM)
- Downloadable PDF scorecard
- iOS release
- Further security hardening

</td>
</tr>
</table>

---

## 📊 Project Status

| Area | Status |
|---|---|
| Verdant Daylight UI (all 10 screens) | ✅ Complete |
| Design system (6 reusable widgets) | ✅ Complete |
| Firebase project (Blaze plan, asia-south1) | ✅ Complete |
| Cloud Functions (5 deployed) | ✅ Complete |
| NPF auto-sync (scheduled every 30 min) | ✅ Deployed |
| NPF lead fetch (callable) | ✅ Deployed |
| Email OTP (send + verify) | ✅ Deployed |
| Server-side scoring | ✅ Deployed |
| Firestore security rules (tightened) | ✅ Deployed |
| Question bank seeded (B.Tech, 30 questions) | ✅ Done |
| Firestore data model (6 collections) | ✅ Complete |
| End-to-end testing | 🔧 In progress |
| Google Play Console setup | 📋 Planned |
| Admin CRUD for tests/questions (Phase 2) | 📋 Planned |
| FCM push notifications (Phase 2) | 📋 Planned |
| iOS release (Phase 2) | 📋 Planned |

**Legend:** ✅ Done · 🔧 In progress · 📋 Planned

---

## 🤝 Contributing

This project is developed and maintained for Noida International University. For questions or contributions, please contact the project maintainer.

---

## 📄 License

This project is developed for Noida International University ([niu.edu.in](http://niu.edu.in/)). All rights reserved.

---

<div align="center">

**NSAT** — Built with Flutter & Firebase for Noida International University

</div>