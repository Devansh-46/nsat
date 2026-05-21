<div align="center">

# 🎓 NSAT — NIU Student Aptitude Test

### A mobile & web application for conducting online aptitude tests for admission candidates at Noida International University.

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Blaze-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20iOS-blueviolet)]()
[![Functions](https://img.shields.io/badge/Cloud%20Functions-5%20deployed-4285F4?logo=googlecloud&logoColor=white)]()
[![NPF Sync](https://img.shields.io/badge/NPF%20Sync-Live-brightgreen)]()
[![Status](https://img.shields.io/badge/Status-Pre--Launch-brightgreen)]()

</div>

---

## 📖 Overview

**NSAT** lets admission candidates take their aptitude test online — from a phone or a web browser. The app verifies that a candidate has paid their application fee via NoPaperForms/Meritto, confirms their identity by email OTP, runs a timed multiple-choice test with server-side scoring, and records the result.

Built once in **Flutter**, runs on **Android, Web, and iOS** from a single codebase, with **Firebase Cloud Functions** handling all server-side logic including NPF integration, email OTP, and scoring.

> **Target:** 14 June 2026 entrance test. Dry run planned ~7 June.

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🔐 **NIU ID Login** | Students log in with their NIU ID (application number). |
| 💳 **Automatic Fee Check** | Real-time fee verification via NoPaperForms — synced every 30 minutes. |
| 🔄 **Live NPF Integration** | Student data auto-synced from Meritto/NPF; lead details fetched live at login. |
| 📧 **Email OTP** | 6-digit code sent to registered email; SHA-256 hashed server-side, 10-min expiry, 5-attempt limit. |
| 📝 **Timed Test** | Multiple-choice test with countdown timer, question palette, and auto-submit. |
| 🔒 **Server-Side Scoring** | Answers scored by Cloud Function — the client never sees the answer key. |
| 📊 **Instant Results** | Score breakdown shown immediately after submission. |
| 🔒 **One Attempt Lock** | Transactional attempt lock with crash-safe status tracking (`in_progress` → `completed`). |
| 📋 **Admin Dashboard** | Real-time Firestore-backed stats, results list with course filtering, CSV export. |
| 🎨 **Verdant Daylight UI** | Custom design system — mesh backgrounds, glass-morphism cards, Instrument Serif typography. |
| 🌐 **Cross-Platform** | Single codebase for Android, Web, and iOS. |

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
                       ┌──────────────┐     ┌──────────────┐
                       │   Result     │ ◀── │  Timed Test  │
                       │ (server-     │     │  (MCQ)       │
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

All 5 functions deployed in `asia-south1`.

| Function | Type | Purpose |
|---|---|---|
| `syncStudents` | Scheduled (30 min) | POST to NPF API, batch-writes `students` collection with pagination |
| `fetchLeadDetails` | Callable | NPF lead lookup by `lead_id`, returns name/course/email with course-key mapping |
| `sendOtp` | Callable | Generates 6-digit code, SHA-256 hashes to `otps`, sends email via SMTP |
| `verifyOtp` | Callable | Validates hash, enforces 5-attempt limit and 10-min expiry |
| `scoreSubmission` | Callable | Reads questions server-side, scores answers, writes result, flips attempt lock |

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
| `questions` | Question bank (text, options, answer, course) | Auto | Seed script |
| `results` | Score breakdown per submission | Auto | Cloud Function |
| `attempts` | One-attempt lock (`in_progress` → `completed`) | `application_no` | Client + Cloud Function |
| `otps` | Hashed 6-digit codes (10-min TTL) | `application_no` | Cloud Function |
| `_meta` | Sync metadata (last successful sync timestamp) | `npfSync` | Cloud Function |

---

## 📁 Project Structure

```
nsat/
├── lib/
│   ├── main.dart
│   ├── models/           # StudentModel, LeadDetailsModel, TestModel, etc.
│   ├── providers/        # AuthProvider, TestProvider, AdminProvider
│   ├── services/         # Firestore + Cloud Function service layer
│   ├── screens/
│   │   ├── student/      # 6 screens: login → OTP → test → result
│   │   └── admin/        # 4 screens: login, dashboard, results, notifications
│   ├── widgets/          # MeshBackground, GlassCard, Eyebrow, NoteBox, NiuButton, NiuField
│   ├── theme/            # AppColors (61 tokens), AppTheme (3 font families)
│   └── routes/
├── functions/            # TypeScript Cloud Functions
│   └── src/              # syncStudents, fetchLeadDetails, otp, scoreSubmission
├── firebase.json
├── firestore.rules       # Tightened security rules
├── seed_firestore.py     # Question bank seeder (Excel → Firestore)
├── import_students_csv.py # Bulk CSV import for historical students
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
✅ Email OTP verification<br>
✅ Timed test flow<br>
✅ Server-side scoring<br>
✅ One-attempt lock (crash-safe)<br>
✅ Verdant Daylight UI (10 screens)<br>
✅ Admin dashboard + CSV export<br>
✅ Firestore security rules<br>
✅ Android + Web<br>
🔧 End-to-end testing<br>
🔧 APK build + distribution

</td>
<td valign="top">

📋 iOS release<br>
📋 Admin test/question CRUD<br>
📋 NPF result write-back<br>
📋 FCM push notifications<br>
📋 PDF scorecard download<br>
📋 Network-loss retry on submit

</td>
</tr>
</table>

---

## 📊 Current Status

| Component | Status |
|---|---|
| UI — 10 screens (Verdant Daylight) | ✅ |
| Design system — 6 widgets + theme | ✅ |
| Firebase Blaze + Firestore | ✅ |
| Cloud Functions — 5 deployed | ✅ |
| NPF sync — live, paginated | ✅ |
| Email OTP — send + verify | ✅ |
| Server-side scoring | ✅ |
| Security rules — tightened | ✅ |
| Question bank — B.Tech (30 Q) | ✅ |
| CSV bulk import script | ✅ |
| Release APK | 🔧 |
| Google Play listing | 📋 |
| iOS build | 📋 |

---

## 📄 License

Developed for **Noida International University** ([niu.edu.in](https://niu.edu.in)). All rights reserved.

---

<div align="center">

**NSAT** · Flutter + Firebase · Noida International University

</div>