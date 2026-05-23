<div align="center">

# 🎓 NSAT — NIU Student Aptitude Test

### A mobile & web application for conducting online aptitude tests for admission candidates at Noida International University.

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Blaze-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20iOS-blueviolet)]()
[![Functions](https://img.shields.io/badge/Cloud%20Functions-8%20deployed-4285F4?logo=googlecloud&logoColor=white)]()
[![NPF Sync](https://img.shields.io/badge/NPF%20Sync-Live-brightgreen)]()
[![Status](https://img.shields.io/badge/Status-Pre--Launch-brightgreen)]()

</div>

---

## 📖 Overview

**NSAT** lets admission candidates take their aptitude test online — from a phone or a web browser. The app verifies that a candidate has paid their application fee via NoPaperForms/Meritto, confirms their identity by two-factor verification (email OTP + WhatsApp OTP), runs a timed test with multiple-choice and short-answer questions, scores server-side, and records the result.

Built once in **Flutter**, runs on **Android, Web, and iOS** from a single codebase, with **Firebase Cloud Functions** handling all server-side logic including NPF integration, email OTP, and scoring.


---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🔐 **NIU ID Login** | Students log in with their NIU ID (application number). |
| 💳 **Automatic Fee Check** | Real-time fee verification via NoPaperForms — synced every 30 minutes. |
| 🔄 **Live NPF Integration** | Student data auto-synced from Meritto/NPF; lead details fetched live at login. |
| 📧 **Two-Factor Verification** | Email OTP (6-digit, SHA-256 hashed, 10-min expiry, 5-attempt limit) + WhatsApp OTP via Firebase Auth phone verification. |
| 📝 **Timed Test** | Multiple-choice test with countdown timer, question palette, and auto-submit. |
| 🔒 **Server-Side Scoring** | Answers scored by Cloud Function — the client never sees the answer key. |
| 📊 **Instant Results** | Score breakdown shown immediately after submission. |
| 🔒 **One Attempt Lock** | Transactional attempt lock with crash-safe status tracking (`in_progress` → `completed`). |
| 📋 **Admin Dashboard** | Real-time Firestore-backed stats, results list with course filtering, CSV export. |
| 🎨 **Verdant Daylight UI** | Custom design system — mesh backgrounds, glass-morphism cards, Instrument Serif typography. |
| 🌐 **Cross-Platform** | Single codebase for Android, Web, and iOS. Web uses responsive split-layout (dark left panel + light right panel on desktop). |
| ✍️ **Short-Answer Questions** | Descriptive questions with configurable min/max word count, live word counter, and ungraded responses stored for admissions review. |
| 📱 **FCM Push Notifications** | Topic-based push notifications to all students or per-school (15 school topics + `all_students`). |
| 🏫 **Multi-School Support** | 15 school/course keys: SET, SBM, SOAHS, SOS, SOLLA, SJMC, SOLA, SOE, SOP, SON (each UG/PG where applicable). |
| ➖ **Negative Marking** | Configurable wrong-answer penalty per test configuration. |
| 🔑 **Admin Custom Claims** | Role-based access control via Firebase Auth custom claims + email whitelist. |
| 📤 **CSV Export** | Export results with NIU ID, name, course, correct/wrong/skipped, net/max score, timestamp. |
| 📥 **Bulk CSV Import** | Import historical student data before auto-sync (`import_students_csv.py` with dry-run). |
| 💾 **Offline Persistence** | SharedPreferences for test results, configs, and notification history. |
| 👥 **Role Selection** | Separate entry points for student and admin users at app launch. |
| 🏷️ **Question Topic Tagging** | Optional topic field on questions for finer categorization. |
| 🕐 **Sync Metadata** | `_meta` collection tracks last successful NPF sync timestamp. |
| 🔀 **Show/Hide Results** | Per-test toggle (`showResults`) — hide scores for certain exams, show "Thank you" instead. |
| 🛡️ **Crashlytics** | Real-time crash reporting via Firebase Crashlytics (mobile only). |
| 🔧 **Remote Config** | Exam window toggle, maintenance mode, and custom messages — all live from Firebase Console, no deploy needed. |
| 📈 **Firebase Analytics** | Full student journey funnel: login → fee → OTP → test → submit → result. Plus error events. |
| 🚀 **CI/CD** | GitHub Actions auto-deploys web app to Firebase Hosting on every push to `main`. |
| 📜 **Privacy Policy** | GDPR/Play Store compliant privacy policy hosted at `/privacy`. |

---

## 🧭 Student Journey

```
  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
  │  Enter NIU   │ ──▶ │  Fee Check   │ ──▶ │ Fetch Lead   │
  │     ID       │     │  (Firestore) │     │ Details (NPF)│
  └──────────────┘     └──────┬───────┘     └──────┬───────┘
                               │                    │
                        not paid │                    │ approved
                               ▼                    ▼
                        ┌──────────────┐     ┌──────────────┐
                        │  "Fee not    │     │  Email OTP   │
                        │   paid"      │     │  (6-digit)   │
                        └──────────────┘     └──────┬───────┘
                                                    │ verified
                                                    ▼
                                             ┌──────────────┐
                                             │ WhatsApp OTP │
                                             │  (Firebase   │
                                             │   Auth)      │
                                             └──────┬───────┘
                                                    │ verified
                                                    ▼
                        ┌──────────────┐     ┌──────────────┐
                        │   Result     │ ◀── │  Timed Test  │
                        │ (server-     │     │  (MCQ + SAQ) │
                        │  scored)     │     │              │
                        └──────────────┘     └──────────────┘
```

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.41 (Dart 3.11) |
| **State Management** | Provider |
| **Backend** | Firebase Blaze (asia-south1) |
| **Database** | Cloud Firestore |
| **Server Logic** | Cloud Functions v2 (TypeScript, Node 20) |
| **Email** | Nodemailer via SMTP |
| **Fee Data Source** | Meritto / NoPaperForms API |
| **Design System** | Verdant Daylight — Instrument Serif, Inter, JetBrains Mono |

---

## ☁️ Cloud Functions

All 8 functions deployed in `asia-south1`.

| Function | Type | Purpose |
|---|---|---|
| `syncStudents` | Scheduled (30 min) | POST to NPF API, batch-writes `students` collection with pagination |
| `fetchLeadDetails` | Callable | NPF lead lookup by `lead_id`, returns name/course/email with course-key mapping |
| `sendOtp` | Callable | Generates 6-digit code, SHA-256 hashes to `otps`, sends email via SMTP |
| `verifyOtp` | Callable | Validates hash, enforces 5-attempt limit and 10-min expiry |
| `scoreSubmission` | Callable | Reads questions server-side, scores answers (MCQ + short-answer), writes result, flips attempt lock |
| `sendNotification` | Callable | Sends FCM push to topic (`all_students` or `school_{key}`), writes to `notifications` collection |
| `setAdminClaim` | Callable | Sets `admin` custom claim on a Firebase Auth user (requires existing admin + email whitelist) |
| `removeAdminClaim` | Callable | Removes `admin` custom claim from a Firebase Auth user (requires existing admin) |

> **WhatsApp OTP** is handled directly by Firebase Auth (`verifyPhoneNumber` + `signInWithCredential`) on the client — no Cloud Function needed. The email OTP path uses Cloud Functions to keep the OTP secret server-side.

### Environment Variables (`functions/.env`)

```env
NPF_ACCESS_KEY=...        # NoPaperForms API access key
NPF_SECRET_KEY=...        # NoPaperForms API secret key
NPF_BASE_URL=...          # NPF API base URL
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=...             # Email address for sending OTPs
SMTP_PASS=...             # Gmail app password
OTP_FROM_NAME=NSAT NIU
```

---

## 🗄️ Data Model

| Collection | Purpose | Doc ID | Written By |
|---|---|---|---|
| `students` | Synced from NPF every 30 min | `application_no` | Cloud Function |
| `tests` | Test config per course | Auto | Seed script |
| `questions` | Question bank (text, options, answer, course, type) | Auto | Seed script |
| `results` | Score breakdown per submission (incl. short-answer responses) | Auto | Cloud Function |
| `attempts` | One-attempt lock (`in_progress` → `completed`) | `application_no` | Client + Cloud Function |
| `otps` | Hashed 6-digit codes (10-min TTL) | `application_no` | Cloud Function |
| `notifications` | Notification history (title, body, target, timestamp) | Auto | Cloud Function |
| `_meta` | Sync metadata (last successful sync timestamp) | `npfSync` | Cloud Function |

---

## 📁 Project Structure

```
nsat/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── models/           # 10 models: Student, LeadDetails, Test, TestConfig, TestSession, Question (MCQ + short-answer), Result, Attempt, Notification, User
│   ├── providers/        # AuthProvider, TestProvider, AdminProvider
│   ├── services/         # 14 services: Auth, Student, Test, TestData, Question, Attempt, Scoring, Result, Admin, Notification, FCM, Analytics, RemoteConfig, ResultsExporter, DataStore (legacy mock)
│   ├── screens/
│   │   ├── student/      # 7 screens: role selection → login → email verification → fee gate → test category → live test → result
│   │   └── admin/        # 4 screens: login, dashboard, results, push notifications
│   ├── widgets/          # 11 widgets: MeshBackground, GlassCard, Eyebrow, NoteBox, NiuButton, NiuField, NiuAppBar, StatCard, InfoRow, MenuRow, WebSplitLayout
│   ├── theme/            # AppColors (61+ tokens), AppTheme (3 font families)
│   └── routes/           # AppRoutes (10 named routes)
├── functions/             # TypeScript Cloud Functions
│   └── src/              # 8 files: index, config, syncStudents, fetchLeadDetails, otp, scoreSubmission, sendNotification, adminClaims
├── web/
│   ├── index.html
│   ├── privacy/          # Privacy policy page (hosted at /privacy)
│   └── icons/            # PWA icons (192, 512, maskable)
├── .github/workflows/    # CI/CD: dart.yml, firebase-hosting-merge.yml, firebase-hosting-pull-request.yml
├── firebase.json
├── firestore.rules       # Tightened security rules
├── seed_firestore.py     # Question bank seeder (Excel → Firestore, MCQ + short-answer)
├── import_students_csv.py # Bulk CSV import for historical students (with dry-run)
├── setup_admin.py        # Bootstrap first Firebase admin user with custom claims
├── test_categories.txt   # 15 school/course keys
└── pubspec.yaml
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.x+
- Firebase CLI + FlutterFire CLI
- Node.js 20+
- Android Studio or VS Code

### Quick Start

```bash
git clone https://github.com/Devansh-46/nsat.git
cd nsat
flutter pub get
flutterfire configure

cd functions
cp .env.example .env     # Fill in real credentials
npm install && npm run build
cd ..

firebase deploy --only functions
firebase deploy --only firestore:rules

python seed_firestore.py  # Seed question bank

flutter run               # Android
flutter run -d chrome     # Web
flutter build apk --release  # Release APK
```

### NPF Sync

Runs automatically every 30 minutes. Manual trigger via Cloud Scheduler in GCP Console, or:

```bash
gcloud scheduler jobs run firebase-schedule-syncStudents-asia-south1 \
  --project=nsat-niu-app --location=asia-south1
```

### Bulk CSV Import

For importing historical student data before the auto-sync picks up:

```bash
python import_students_csv.py students_export.csv --dry-run  # Preview
python import_students_csv.py students_export.csv             # Import
```

---

## 📦 Project Phases

<table>
<tr>
<th>Phase 1 — June 14 Launch</th>
<th>Phase 2 — Post-Launch</th>
</tr>
<tr>
<td valign="top">

✅ NIU ID login + fee gate<br>
✅ NPF auto-sync (every 30 min)<br>
✅ Live NPF lead fetch<br>
✅ Two-factor verification (email OTP + WhatsApp OTP via Firebase Auth)<br>
✅ Timed test flow<br>
✅ Server-side scoring<br>
✅ One-attempt lock (crash-safe)<br>
✅ Verdant Daylight UI (11 screens + responsive web split-layout)<br>
✅ Admin dashboard + CSV export<br>
✅ Firestore security rules<br>
✅ Android + Web<br>
✅ FCM push notifications (topic-based)<br>
✅ Short-answer questions with word count<br>
✅ Admin custom claims + management<br>
✅ Bulk CSV import script<br>
✅ Show/hide results per test<br>
✅ Firebase Crashlytics<br>
✅ Firebase Remote Config (maintenance mode + exam window)<br>
✅ Firebase Analytics (student journey funnel)<br>
✅ CI/CD — GitHub Actions → Firebase Hosting<br>
✅ Privacy policy page<br>
🔧 Google Play Store listing + AAB<br>
✅ Custom domain (nsat.niu.edu.in)<br>
🔧 End-to-end dry run

</td>
<td valign="top">

🔧 iOS release<br>
📋 Admin test/question CRUD<br>
📋 NPF result write-back<br>
📋 PDF scorecard download<br>
📋 Network-loss retry on submit<br>
📋 Admin grading UI for short-answer questions<br>
🔧 App Check (protect Cloud Functions from abuse)

</td>
</tr>
</table>

---

## 📊 Current Status

| Component | Status |
|---|---|
| UI — 11 screens (Verdant Daylight) | ✅ |
| Design system — 8 widgets + theme | ✅ |
| Firebase Blaze + Firestore | ✅ |
| Cloud Functions — 8 deployed | ✅ |
| NPF sync — live, paginated | ✅ |
| Email OTP — send + verify | ✅ |
| Server-side scoring | ✅ |
| Security rules — tightened | ✅ |
| Question bank — B.Tech (MCQ + short-answer) | ✅ |
| Short-answer questions | ✅ |
| FCM push notifications | ✅ |
| Admin custom claims | ✅ |
| CSV bulk import script | ✅ |
| Admin setup script | ✅ |
| Show/hide results toggle | ✅ |
| Firebase Crashlytics | ✅ |
| Firebase Remote Config | ✅ |
| Firebase Analytics | ✅ |
| CI/CD (GitHub Actions) | ✅ |
| Privacy policy | ✅ |
| Web app (Firebase Hosting) | ✅ |
| Custom domain (nsat.niu.edu.in) | ✅ |
| Release AAB | 🔧 |
| Google Play listing | 📋 |
| iOS build | 🔧 |
| App Check (Cloud Functions) | 🔧 |

---

## 📄 License

Developed for **Noida International University** ([niu.edu.in](https://niu.edu.in)). All rights reserved.

---

<div align="center">

**NSAT** · Flutter + Firebase · Noida International University

</div>