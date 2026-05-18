<div align="center">

# 🎓 NSAT — NIU Student Aptitude Test

### A mobile & web application for conducting online aptitude tests for admission candidates at Noida International University.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20iOS-blueviolet)]()
[![Status](https://img.shields.io/badge/Status-In%20Development-orange)]()

</div>

---

## 📖 Overview

**NSAT** lets admission candidates take their aptitude test online — from a phone or a web browser, at home. The app verifies that a candidate has paid their application fee, confirms their identity by email, runs a timed multiple-choice test, and records the result.

The app is built once in **Flutter** and runs on **Android, Web, and iOS** from a single codebase, with **Firebase** as the backend.

> **Status:** Active development. The user interface is built; the Firebase backend and the payment-data integration are being wired in. See the [Project Status](#-project-status) section for details.

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🔐 **NIU ID login** | Students log in with their NIU ID (their application number). |
| 💳 **Automatic fee check** | The app confirms the application fee is paid before allowing access — no manual checking. |
| 📧 **Email verification** | A one-time code is sent to the student's registered email to confirm their identity. |
| 📝 **Timed test** | Multiple-choice test with a countdown timer, question palette, and auto-submit when time ends. |
| 📊 **Instant results** | Score breakdown — correct, wrong, skipped — shown immediately after submission. |
| 🔒 **One attempt only** | Each student can take the test exactly once; the lock is enforced server-side. |
| 🔔 **Announcements** | Push notifications for test reminders and updates. |
| 🌐 **Cross-platform** | One codebase for Android, Web, and iOS. |

---

## 🧭 How It Works — Student Journey

```
  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
  │  Enter NIU   │ ──▶ │  Fee check   │ ──▶ │ Email shown  │
  │     ID       │     │ (paid?)      │     │ for confirm  │
  └──────────────┘     └──────┬───────┘     └──────┬───────┘
                              │                    │
                       not paid │                    │ confirmed
                              ▼                    ▼
                       ┌──────────────┐     ┌──────────────┐
                       │ "Fee not     │     │  Enter email │
                       │  paid" screen│     │     OTP      │
                       └──────────────┘     └──────┬───────┘
                                                   │ verified
                                                   ▼
                       ┌──────────────┐     ┌──────────────┐
                       │   Result &   │ ◀── │  Take timed  │
                       │    score     │     │     test     │
                       └──────────────┘     └──────────────┘
```

1. **Enter NIU ID** — the student opens the app and enters their NIU ID.
2. **Fee check** — the app checks whether the application fee is paid.
   - *Not paid / ID not found* → a message explains how to complete payment or contact a counsellor.
   - *Paid* → the journey continues.
3. **Email confirmation** — the student's registered email is shown for them to confirm.
4. **Email OTP** — a one-time code is sent to that email; the student enters it to verify identity.
5. **Take the test** — the student picks their course and takes the timed test.
6. **Result** — the score and a correct/wrong/skipped breakdown are shown. One attempt only.

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart) — Android, Web, iOS from one codebase |
| **State management** | Provider |
| **Backend** | Firebase |
| **Database** | Cloud Firestore |
| **Authentication** | Firebase Authentication |
| **Server logic** | Cloud Functions |
| **Hosting (web)** | Firebase Hosting |
| **Notifications** | Firebase Cloud Messaging (FCM) |
| **Fee data source** | NoPaperForms (NPF) admissions platform API |

---

## 🗄️ Data Model

The app uses six Firestore collections. The `students` data is kept in sync with the NoPaperForms admissions platform.

| Collection | Purpose | Keyed by |
|---|---|---|
| `students` | Applicant list synced from NoPaperForms every 30 minutes (application number, payment status, lead ID) | NIU ID |
| `tests` | Test configuration per course — question count, duration, marks, negative marking | Auto ID |
| `questions` | The question bank — text, options, correct answer, course | Auto ID |
| `results` | A record per completed test — score breakdown, timestamp | Auto ID |
| `attempts` | The one-attempt lock — whether a student has already taken the test | NIU ID |
| `otps` | Short-lived email verification codes | NIU ID |

> The `students` collection is refreshed automatically; `attempts` and `otps` are kept separate so the sync can never overwrite them.

---

## 📁 Project Structure

```
lib/
├── main.dart                  # App entry point, providers, routes
├── models/                    # Data models
│   ├── user_model.dart
│   ├── question_model.dart
│   ├── test_config_model.dart
│   ├── test_session_model.dart
│   └── notification_model.dart
├── providers/                 # State management (Provider)
│   ├── auth_provider.dart
│   ├── test_provider.dart
│   └── admin_provider.dart
├── screens/
│   ├── student/               # Student-facing screens
│   │   ├── role_selection_screen.dart
│   │   ├── student_login_screen.dart
│   │   ├── fee_gate_screen.dart
│   │   ├── test_category_screen.dart
│   │   ├── live_test_screen.dart
│   │   └── result_screen.dart
│   └── admin/                 # Admin screens (Phase 2)
├── services/                  # Data & business logic
├── widgets/                   # Reusable UI components
├── theme/                     # Colours and theme
└── routes/                    # Route definitions
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- An IDE — VS Code or Android Studio
- A Firebase project *(set up by the project maintainer)*

### Setup

```bash
# 1. Clone the repository
git clone <repository-url>
cd niu_sat_app

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase (maintainer step)
#    Requires the Firebase CLI and FlutterFire CLI.
#    This generates firebase_options.dart and the platform config files.
flutterfire configure

# 4. Run the app
flutter run            # mobile
flutter run -d chrome  # web
```

> **Note:** The app needs Firebase configuration files to build and run. These are generated by `flutterfire configure` and are not committed to the repository.

---

## 📦 Project Phases

<table>
<tr>
<th>Phase 1 — First Release</th>
<th>Phase 2 — Fast Follow-up</th>
</tr>
<tr>
<td valign="top">

- NIU ID login
- Automatic fee check (NoPaperForms)
- Email OTP verification
- Timed test flow
- Results & score breakdown
- One-attempt lock
- Push notifications (announcements)
- Android + Web

</td>
<td valign="top">

- Admin web app
- Test & question management UI
- Results write-back to NoPaperForms
- Scheduled notifications
- Downloadable PDF scorecard
- iOS release
- Security hardening

</td>
</tr>
</table>

---

## 📊 Project Status

| Area | Status |
|---|---|
| User interface (all student screens) | ✅ Built |
| App theme & reusable widgets | ✅ Built |
| Firebase dependencies declared | ✅ Done |
| Firebase project & configuration | 🔧 In progress |
| Firestore data model | 🔧 In progress |
| NoPaperForms integration (Cloud Functions) | 📋 Planned |
| Email OTP verification | 📋 Planned |
| Live test wired to Firebase | 📋 Planned |
| Push notifications | 📋 Planned |
| Admin app (Phase 2) | 📋 Planned |

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
