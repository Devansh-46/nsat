<div align="center">

# 🎓 NSAT — NIU Student Aptitude Test

### A mobile & web application for conducting online aptitude tests for admission candidates at Noida International University.

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Blaze-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20iOS-blueviolet)]()
[![Functions](https://img.shields.io/badge/Cloud%20Functions-16%20deployed-4285F4?logo=googlecloud&logoColor=white)]()
[![NPF Sync](https://img.shields.io/badge/NPF%20Sync-Live-brightgreen)]()
[![Status](https://img.shields.io/badge/Status-Live-brightgreen)]()

</div>

---

## 📖 Overview

**NSAT** lets admission candidates take their aptitude test online — from a phone or a web browser. The app verifies that a candidate has paid their application fee via NoPaperForms/Meritto, confirms their identity by two-factor verification (email OTP + WhatsApp OTP), runs a timed test with multiple-choice and short-answer questions, scores server-side, and records the result.

Built once in **Flutter**, runs on **Android, Web, and iOS** from a single codebase, with **Firebase Cloud Functions** handling all server-side logic including NPF integration, OTP delivery (email + WhatsApp), scoring, admin management, and push notifications.

**Exam date:** June 14, 2026  
**Package:** `in.edu.niu.nsat`  
**Firebase project:** `nsat-niu-app` (Blaze, `asia-south1`)  
**Domain:** [nsat.niu.edu.in](https://nsat.niu.edu.in)  
**Privacy policy:** [nsat.niu.edu.in/privacy](https://nsat.niu.edu.in/privacy)

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🔐 **NIU ID Login** | Students log in with their NIU ID (application number). No Firebase Auth for students. |
| 💳 **Automatic Fee Check** | Real-time fee verification via NoPaperForms — synced every 30 minutes. |
| 🔄 **Live NPF Integration** | Student data auto-synced from Meritto/NPF; lead details fetched live at login. |
| 📧 **Two-Factor Verification** | Email OTP (6-digit, SHA-256 hashed, 10-min expiry, 5-attempt limit) + WhatsApp OTP via Twilio. Channel-specific OTP documents prevent overwrite conflicts. |
| 📝 **Timed Test** | Multiple-choice + short-answer test with countdown timer, question palette, and auto-submit. |
| 🔒 **Server-Side Scoring** | Answers scored by Cloud Function — the client never sees the answer key. Short-answer responses saved ungraded for review. |
| 📊 **Instant Results** | Score breakdown shown immediately after submission (configurable per test). |
| 🔒 **One Attempt Lock** | Transactional attempt lock with crash-safe status tracking (`in_progress` → `completed`). |
| 📋 **Admin Dashboard** | Real-time Firestore-backed stats, results list with course filtering, CSV export, per-result detail view. |
| 🎨 **Verdant Daylight UI** | Custom design system — mesh backgrounds, glass-morphism cards, 59 color tokens, animated splash screen. |
| 🌐 **Cross-Platform** | Single codebase for Android, Web, and iOS. Web uses responsive split-layout (dark left panel + light right panel on desktop). |
| ✍️ **Short-Answer Questions** | Descriptive questions with configurable min/max word count, live word counter, and ungraded responses stored for admissions review. |
| 📱 **FCM Push Notifications** | Topic-based push notifications to all students or per-school (16 school topics + `all_students`). |
| 🏫 **Multi-School Support** | 16 school/course keys: SET, SBM, SOAHS, SOS, SOLLA, SJMC, SOLA, SOE, SOP, SON, SOFAD (each UG/PG where applicable). |
| ➖ **Negative Marking** | Configurable wrong-answer penalty per test configuration. |
| 🔑 **Admin & Superadmin RBAC** | Role-based access via Firebase Auth custom claims — superadmins can promote/demote admins, manage course access, and force password changes. |
| 📤 **CSV Export** | Export results with NIU ID, name, course, correct/wrong/skipped, net/max score, timestamp. |
| 📥 **Bulk CSV Import** | Import historical student data before auto-sync (`import_students_csv.py` with dry-run). |
| 💾 **Offline Persistence** | SharedPreferences for test results, configs, and notification history. |
| 👥 **Role Selection** | Separate entry points for student and admin users at app launch. |
| 🏷️ **Question Topic Tagging** | Optional topic field on questions for finer categorization. |
| 🕐 **Sync Metadata** | `_meta` collection tracks last successful NPF sync timestamp. |
| 🔀 **Show/Hide Results** | Per-test toggle (`showResults`) — hide scores for certain exams, show "Thank you" instead. |
| ⚙️ **Test Settings** | Superadmin screen to publish/unpublish tests, toggle result visibility and edit access. |
| 🛡️ **Crashlytics** | Real-time crash reporting via Firebase Crashlytics (mobile only). |
| 🔧 **Remote Config** | Exam window toggle, maintenance mode, and custom messages — all live from Firebase Console, no deploy needed. |
| 📈 **Firebase Analytics** | Full student journey funnel: login → fee → OTP → test → submit → result. Plus error events. |
| 📝 **Structured Logging** | Centralized `AppLogger` with debug/info/error levels. Error logs persist to Firestore `app_logs` + Crashlytics. Admin logs viewer screen. |
| 🚀 **CI/CD** | GitHub Actions auto-deploys web app to Firebase Hosting on every push to `main`. |
| 📜 **Privacy Policy** | GDPR/Play Store compliant privacy policy hosted at `/privacy`. |
| 🏫 **Course-Scoped Access** | Admins can be restricted to view results only for specific courses. |
| 🔐 **Force Password Change** | Superadmins can force newly created admins to change password on first login. |
| 🛡️ **Auto-Submit Safety Net** | Scheduled Cloud Function (`autoSubmitExpired`) runs every 2 minutes — catches students whose app crashed or lost network, scores their saved answers, and marks the attempt completed. Results flagged with `autoSubmitted: true` for admin review. |
| 🔐 **Firebase App Check** | Protects all callable Cloud Functions from unauthorized access. Play Integrity (Android), App Attest (iOS), reCAPTCHA Enterprise (Web). Currently in monitoring mode (`consumeAppCheckToken`); hard enforcement post-launch. |
| 🚫 **Screenshot Blocking** | Android `FLAG_SECURE` blocks screenshots and screen recording app-wide. Web disables right-click, Ctrl+C/A/S/U, F12, and PrintScreen. CSS `user-select: none` prevents text selection. |
| 📋 **Clipboard Lockdown** | `NoPasteFormatter` rejects paste operations in all text fields (short-answer and NiuField). `enableInteractiveSelection: false` disables long-press copy/paste menus. `SelectionContainer.disabled` wraps the live test screen to prevent question text selection on web. |
| 🖥️ **Device Fingerprinting** | Captures device metadata (brand, model, OS, screen size, browser agent) at test start. Stored in `device_fingerprints/{applicationNo}` for post-exam auditing. Supports Android, iOS, and Web via `device_info_plus`. |
| 💾 **Answer Sync (Crash Recovery)** | Client periodically saves answers to `saved_answers/{applicationNo}` every 30 seconds. Combined with `autoSubmitExpired`, this recovers partial work from app crashes, network loss, or phone death. |

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
                                             │  (Twilio)    │
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
| **Email OTP** | Nodemailer via SMTP |
| **WhatsApp OTP** | Twilio WhatsApp API |
| **Fee Data Source** | Meritto / NoPaperForms API |
| **Crash Reporting** | Firebase Crashlytics |
| **Analytics** | Firebase Analytics |
| **Remote Config** | Firebase Remote Config |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **CI/CD** | GitHub Actions → Firebase Hosting |
| **Design System** | Verdant Daylight — Instrument Serif, Inter, JetBrains Mono |

---

## ☁️ Cloud Functions

All 16 functions deployed in `asia-south1`.

| Function | Type | Purpose |
|---|---|---|
| `syncStudents` | Scheduled (30 min) | POST to NPF API, batch-writes `students` collection with pagination |
| `fetchLeadDetails` | Callable | NPF lead lookup by `lead_id`, returns name/course/email with course-key mapping |
| `sendOtp` | Callable | Generates 6-digit code, SHA-256 hashes to `otps/{id}/channels/email`, sends email via SMTP |
| `verifyOtp` | Callable | Validates hash per channel, enforces 5-attempt limit and 10-min expiry |
| `sendWhatsAppOtp` | Callable | Generates 6-digit code, hashes to `otps/{id}/channels/whatsapp`, sends via Twilio WhatsApp API |
| `scoreSubmission` | Callable | Reads questions server-side by course + testId, scores MCQ answers, saves short-answer responses ungraded, writes result, flips attempt lock |
| `sendNotification` | Callable | Sends FCM push to topic (`all_students` or `school_{key}`), writes to `notifications` collection |
| `setAdminClaim` | Callable | Creates admin with custom claim, optionally creates Firebase Auth user with force-password-change flag |
| `removeAdminClaim` | Callable | Removes admin custom claim and deletes from `admins` collection |
| `listAdmins` | Callable | Returns all admins from Firestore with their roles and course assignments |
| `clearForcePasswordChange` | Callable | Clears the force-password-change flag after admin changes password |
| `updateAdminCourses` | Callable | Assigns course-scoped result access to an admin |
| `promoteSuperadmin` | Callable | Grants superadmin custom claim + adds to `superadmins` collection |
| `demoteSuperadmin` | Callable | Removes superadmin claim + deletes from `superadmins` collection |
| `autoSubmitExpired` | Scheduled (every 2 min) | Safety net — finds expired `in_progress` attempts, reads saved answers from `saved_answers/{applicationNo}`, scores them server-side, writes results with `autoSubmitted: true`, and flips attempt status to `completed`. Includes 2-minute grace period to avoid racing with client-side submit. |
| (App Check enforcement) | Per-function config | `consumeAppCheckToken: true` added to all callable functions — logs App Check token presence without blocking. Switch to `enforceAppCheck: true` post-launch. |

> **WhatsApp OTP** uses Twilio's WhatsApp API via a Cloud Function (`sendWhatsAppOtp`). Email and WhatsApp OTPs use channel-specific sub-documents (`otps/{applicationNo}/channels/{email|whatsapp}`) to prevent overwrite conflicts.

### Environment Variables (`functions/.env`)

```env
NPF_ACCESS_KEY=...              # NoPaperForms API access key
NPF_SECRET_KEY=...              # NoPaperForms API secret key
NPF_BASE_URL=...                # NPF API base URL (https://api.nopaperforms.io)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=...                   # Email address for sending OTPs
SMTP_PASS=...                   # Gmail app password
OTP_FROM_NAME=NSAT NIU
TWILIO_ACCOUNT_SID=...          # Twilio account SID
TWILIO_AUTH_TOKEN=...           # Twilio auth token
TWILIO_WHATSAPP_FROM=...        # Twilio WhatsApp sender number
ADMIN_EMAILS=...                # Comma-separated admin email allowlist
ROOT_SUPERADMIN_EMAIL=...       # Root superadmin (cannot be demoted)
```

---

## 🗄️ Data Model

| Collection | Purpose | Doc ID | Written By |
|---|---|---|---|
| `students` | Synced from NPF every 30 min | `application_no` | Cloud Function |
| `tests` | Test config per course (publish, showResults, editResults flags) | Auto | Seed script / Admin |
| `questions` | Question bank (text, options, answer, course, type, sequence) | Auto | Seed script |
| `results` | Score breakdown per submission (incl. short-answer responses) | Auto | Cloud Function |
| `attempts` | One-attempt lock (`in_progress` → `completed`) | `application_no` | Client + Cloud Function |
| `otps` | Parent doc per student; sub-collection `channels/{email\|whatsapp}` for hashed OTP codes | `application_no` | Cloud Function |
| `notifications` | Notification history (title, body, target, timestamp) | Auto | Cloud Function |
| `admins` | Admin user records with course assignments | `email` | Cloud Function |
| `superadmins` | Superadmin registry | `email` | Cloud Function |
| `app_logs` | Structured error/info logs from client app | Auto | Client app |
| `_meta` | Sync metadata (last successful sync timestamp) | `npfSync` | Cloud Function |
| `saved_answers` | Periodic answer backup during test (crash recovery) | `application_no` | Client |
| `device_fingerprints` | Device metadata captured at test start (audit trail) | `application_no` | Client |

---

## 📁 Project Structure

```
nsat/
├── lib/
│   ├── main.dart                    # App entry, Firebase init, Provider setup, route table
│   ├── firebase_options.dart        # FlutterFire generated config (Android + Web)
│   ├── models/                      # 11 data models
│   │   ├── app_log_model.dart       #   Structured log entry
│   │   ├── attempt_model.dart       #   One-attempt lock state
│   │   ├── lead_details_model.dart  #   NPF lead (name, email, course, phone)
│   │   ├── notification_model.dart  #   Push notification record
│   │   ├── question_model.dart      #   MCQ + short-answer question
│   │   ├── result_model.dart        #   Score breakdown
│   │   ├── student_model.dart       #   Synced student record
│   │   ├── test_config_model.dart   #   Lightweight test config
│   │   ├── test_model.dart          #   Full test definition
│   │   ├── test_session_model.dart  #   In-memory test session state
│   │   └── user_model.dart          #   Admin user
│   ├── providers/                   # 3 state managers (ChangeNotifier + Provider)
│   │   ├── auth_provider.dart       #   Student login flow + admin auth
│   │   ├── test_provider.dart       #   Test lifecycle (load → answer → submit → score)
│   │   └── admin_provider.dart      #   Dashboard stats, results, admin management
│   ├── services/                    # 21 services
│   │   ├── admin_management_service.dart  #   Cloud Function calls for admin CRUD
│   │   ├── device_fingerprint_service.dart  #   Device metadata capture for audit
│   │   ├── admin_service.dart             #   Dashboard stats + results fetch
│   │   ├── analytics_service.dart         #   Firebase Analytics event logging
│   │   ├── app_logger.dart                #   Centralized structured logger
│   │   ├── attempt_service.dart           #   Attempt lock transactions
│   │   ├── auth_service.dart              #   Firebase Auth (admin only)
│   │   ├── data_store.dart                #   Legacy mock data (to be removed)
│   │   ├── fcm_service.dart               #   FCM topic subscribe/unsubscribe
│   │   ├── notification_service.dart      #   Send + fetch notifications
│   │   ├── question_service.dart          #   Firestore question queries
│   │   ├── remote_config_service.dart     #   Maintenance mode, exam window
│   │   ├── result_service.dart            #   Result reads
│   │   ├── results_exporter.dart          #   CSV export (web + mobile)
│   │   ├── scoring_service.dart           #   scoreSubmission Cloud Function call
│   │   ├── student_service.dart           #   Student lookup by NIU ID
│   │   ├── test_data_service.dart         #   Test data helpers
│   │   ├── test_management_service.dart   #   Superadmin test settings CRUD
│   │   ├── test_service.dart              #   Published test queries
│   │   ├── web_download.dart              #   Web-specific CSV download (dart:js_interop)
│   │   └── web_download_stub.dart         #   Stub for non-web platforms
│   ├── utils/
│   │   └── clipboard_guard.dart     #   NoPasteFormatter — blocks paste in text fields
│   ├── screens/
│   │   ├── student/                 # 7 student screens
│   │   │   ├── role_selection_screen.dart      #   Entry point: Student or Admin
│   │   │   ├── student_login_screen.dart       #   NIU ID + fee gate
│   │   │   ├── email_verification_screen.dart  #   Email OTP + WhatsApp OTP (2FA)
│   │   │   ├── fee_gate_screen.dart            #   Fee-not-paid blocker
│   │   │   ├── test_category_screen.dart       #   Published test + start button
│   │   │   ├── live_test_screen.dart           #   Timed test with palette + PopScope
│   │   │   └── result_screen.dart              #   Score ring + breakdown
│   │   └── admin/                   # 10 admin screens
│   │       ├── admin_login_screen.dart         #   Admin email/password login
│   │       ├── admin_dashboard_screen.dart     #   Stats + action grid
│   │       ├── results_dashboard_screen.dart   #   Filterable results table
│   │       ├── result_detail_screen.dart       #   Per-student result detail view
│   │       ├── push_notification_screen.dart   #   Send FCM notifications
│   │       ├── admin_logs_screen.dart          #   System logs viewer (filterable)
│   │       ├── manage_admins_screen.dart       #   Add/remove admins + superadmins
│   │       ├── course_access_screen.dart       #   Assign course-scoped access
│   │       ├── change_password_screen.dart     #   Force password change flow
│   │       └── test_settings_screen.dart       #   Publish/unpublish + result toggles
│   ├── widgets/                     # 12 reusable widgets
│   │   ├── mesh_background.dart     #   Animated ambient mesh gradient
│   │   ├── glass_card.dart          #   Frosted glass container
│   │   ├── eyebrow.dart            #   Uppercase label chip
│   │   ├── note_box.dart           #   Info/warning/gold callout box
│   │   ├── niu_button.dart         #   Primary/secondary/outline buttons
│   │   ├── niu_field.dart          #   Styled text input
│   │   ├── niu_app_bar.dart        #   Custom app bar
│   │   ├── stat_card.dart          #   Dashboard stat tile
│   │   ├── info_row.dart           #   Key-value info row
│   │   ├── menu_row.dart           #   Navigation menu item
│   │   ├── splash_screen.dart      #   Animated splash (crest + wordmark + progress)
│   │   └── web_split_layout.dart   #   Responsive split-layout for web
│   ├── theme/
│   │   ├── app_colors.dart          #   59 color tokens (Verdant Daylight palette)
│   │   └── app_theme.dart           #   3 font families (Instrument Serif, Inter, JetBrains Mono)
│   └── routes/
│       └── app_routes.dart          #   17 named routes
├── functions/                        # TypeScript Cloud Functions
│   ├── src/
│   │   ├── index.ts                 #   Exports all 16 functions
│   │   ├── config.ts                #   NPF/SMTP/Twilio config + course-key mapping (273 lines)
│   │   ├── admin_claims_config.ts   #   Root superadmin email
│   │   ├── syncStudents.ts          #   Scheduled NPF sync with pagination
│   │   ├── fetchLeadDetails.ts      #   NPF lead detail lookup
│   │   ├── otp.ts                   #   sendOtp + verifyOtp + sendWhatsAppOtp (channel-aware)
│   │   ├── scoreSubmission.ts       #   Server-side scoring + result write
│   │   ├── sendNotification.ts      #   FCM topic push
│   │   ├── autoSubmitExpired.ts     #   Scheduled safety net for crashed/expired attempts
│   │   └── adminClaims.ts           #   7 admin management functions
│   ├── package.json
│   └── tsconfig.json
├── web/
│   ├── index.html
│   ├── privacy/                      #   Privacy policy page (hosted at /privacy)
│   └── icons/                        #   PWA icons (192, 512, maskable)
├── .github/workflows/                #   3 CI/CD workflows
│   ├── dart.yml                     #   Flutter analyze + test
│   ├── firebase-hosting-merge.yml   #   Auto-deploy on push to main
│   └── firebase-hosting-pull-request.yml  # Preview deploy on PR
├── docs/
│   ├── AUDIT_REPORT.md              #   45-issue security & code audit with resolution status
│   ├── Data_model.md                #   Firestore data model specification
│   └── implementation_plan.md       #   Structured logging implementation plan
├── firebase.json                    #   Hosting + Functions + Firestore config
├── firestore.rules                  #   Security rules (14 collections)
├── seed_firestore.py                #   Question bank seeder (Excel → Firestore, MCQ + short-answer)
├── import_students_csv.py           #   Bulk CSV import for historical students (with dry-run)
├── setup_admin.py                   #   Bootstrap first Firebase admin user with custom claims
├── NSAT_QuestionBank_Template.xlsx  #   Excel template for question bank
└── pubspec.yaml
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.x+
- Firebase CLI + FlutterFire CLI
- Node.js 20+
- Android Studio or VS Code
- Python 3 (for seed scripts) + `openpyxl`, `firebase-admin` packages

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

python seed_firestore.py NSAT_QuestionBank_Template.xlsx  # Seed question bank

flutter run               # Android
flutter run -d chrome     # Web
flutter build appbundle --release  # Release AAB for Play Store
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

### Admin Setup

Bootstrap the first superadmin user:

```bash
python setup_admin.py
```

---

## 🗂️ Course → School Paper Mapping

16 paper keys, defined in both `functions/src/config.ts` and `seed_firestore.py` (keep in sync):

| Key | School |
|---|---|
| `soahs_ug` / `soahs_pg` | School of Allied Health & Care Sciences |
| `son` | School of Nursing |
| `set_ug` / `set_pg` | School of Engineering & Technology |
| `sbm_ug` / `sbm_pg` | School of Business Management |
| `solla_ug` / `solla_pg` | School of Law & Legal Affairs |
| `sjmc` | School of Journalism & Mass Communication |
| `sos_ug` / `sos_pg` | School of Sciences |
| `sola` | School of Liberal Arts |
| `sofad` | School of Fine Arts & Design |
| `soe` | School of Education |
| `sop` | School of Pharmacy |

---

## 🔒 Security

- **Firestore rules** cover 14 collections with role-based access (authenticated, admin, superadmin, Cloud Function only)
- **OTP** codes are SHA-256 hashed before storage; 5-attempt limit + 10-min expiry
- **Questions** collection: `correctAnswerIndex` stripped client-side; scoring is server-only
- **Results** collection: write-locked to Cloud Functions; read-locked to admins
- **Admin claims** managed through Cloud Functions with email allowlist + superadmin hierarchy
- **Release build** uses ProGuard/R8 with minification and resource shrinking enabled
- **App Check** monitors all callable Cloud Functions (Play Integrity / App Attest / reCAPTCHA Enterprise) — hard enforcement enabled post-launch
- **FLAG_SECURE** (Android) blocks screenshots and screen recording app-wide
- **Clipboard lockdown** — paste operations blocked in all text inputs; text selection disabled during live test
- **Device fingerprinting** captures device metadata at test start for post-exam audit trail

---

## 📦 Project Phases

<table>
<tr>
<th>v1.0.0 — June 14 Launch</th>
<th>v1.1.0 — Post-Approval Update</th>
</tr>
<tr>
<td valign="top">

✅ NIU ID login + fee gate<br>
✅ NPF auto-sync (every 30 min)<br>
✅ Live NPF lead fetch<br>
✅ Two-factor verification (email OTP + WhatsApp OTP via Twilio)<br>
✅ Timed test flow<br>
✅ Server-side scoring<br>
✅ One-attempt lock (crash-safe)<br>
✅ Verdant Daylight UI (17 screens + responsive web split-layout)<br>
✅ Admin dashboard + CSV export<br>
✅ Firestore security rules (14 collections)<br>
✅ Android + Web<br>
✅ FCM push notifications (topic-based)<br>
✅ Short-answer questions with word count<br>
✅ Admin & superadmin management<br>
✅ Course-scoped admin access<br>
✅ Force password change for new admins<br>
✅ Bulk CSV import script<br>
✅ Show/hide results per test<br>
✅ Test settings screen (publish/unpublish/toggles)<br>
✅ Firebase Crashlytics<br>
✅ Firebase Remote Config (maintenance mode + exam window)<br>
✅ Firebase Analytics (student journey funnel)<br>
✅ Structured logging (AppLogger → Firestore + Crashlytics)<br>
✅ Admin logs viewer<br>
✅ Result detail screen<br>
✅ CI/CD — GitHub Actions → Firebase Hosting<br>
✅ Privacy policy page<br>
✅ Custom domain (nsat.niu.edu.in)<br>
✅ Animated splash screen<br>
✅ Code audit (45 issues tracked, critical resolved)<br>
✅ Google Play Store listing + release AAB<br>
✅ End-to-end dry run

</td>
<td valign="top">

✅ Auto-submit safety net (autoSubmitExpired — every 2 min)<br>
✅ App Check (monitoring mode — Play Integrity / App Attest / reCAPTCHA)<br>
✅ Screenshot blocking (Android FLAG_SECURE + web anti-copy)<br>
✅ Clipboard lockdown (NoPasteFormatter + SelectionContainer.disabled)<br>
✅ Device fingerprinting (device_info_plus → Firestore)<br>
✅ Answer sync / crash recovery (30s periodic save)<br>
✅ Force update guard (Remote Config min_version_code)<br>
✅ Updated privacy policy + README

</td>
</tr>
</table>

<table>
<tr>
<th>Phase 2 — June 14 to July 7</th>
<th>Phase 3 — Post July</th>
</tr>
<tr>
<td valign="top">

📋 iOS release<br>
📋 Exam countdown landing page<br>
📋 Exam instructions screen<br>
📋 Admin quick stats widget<br>
📋 Session timeout (idle detection + auto-submit)<br>
📋 Student feedback form<br>
📋 Admin announcement banner (Remote Config)<br>
📋 Offline answer queue (client-side retry on submit failure)<br>
📋 Bulk notification templates<br>
📋 Question image support (Firebase Storage)<br>
📋 Automated exam scheduling (Cloud Function + schedules collection)<br>
📋 Student leaderboard (per-test, admin-configurable)<br>
📋 Webhook integration (POST results to external systems)<br>
📋 Admin test/question CRUD<br>
📋 NPF result write-back<br>
📋 Admin grading UI for short-answer questions<br>
📋 App Check hard enforcement<br>
📋 Live proctor dashboard (real-time admin monitoring)

</td>
<td valign="top">

📋 AI proctoring — camera-based monitoring, face detection (ML Kit on-device)<br>
📋 AI-powered short answer grading (Claude API integration)

</td>
</tr>
</table>

---

## 📊 Current Status

| Component | Status |
|---|---|
| **Student screens** — 7 (Verdant Daylight) | ✅ |
| **Admin screens** — 10 (dashboard, results, logs, admin mgmt, test settings) | ✅ |
| **Design system** — 12 widgets + 59 color tokens + 3 fonts | ✅ |
| **Firebase Blaze + Firestore** (11 collections) | ✅ |
| **Cloud Functions** — 16 deployed | ✅ |
| **NPF sync** — live, paginated | ✅ |
| **Email OTP** — send + verify + 60s cooldown | ✅ |
| **WhatsApp OTP** — Twilio + channel-specific storage | ✅ |
| **Server-side scoring** | ✅ |
| **Security rules** — tightened (14 collection rules) | ✅ |
| **Question bank** (MCQ + short-answer) | ✅ |
| **FCM push notifications** | ✅ |
| **Admin custom claims + superadmin hierarchy** | ✅ |
| **Course-scoped admin access** | ✅ |
| **CSV bulk import script** | ✅ |
| **Admin setup script** | ✅ |
| **Show/hide results toggle** | ✅ |
| **Test settings screen** | ✅ |
| **Result detail screen** | ✅ |
| **Firebase Crashlytics** | ✅ |
| **Firebase Remote Config** | ✅ |
| **Firebase Analytics** | ✅ |
| **Structured logging (AppLogger)** | ✅ |
| **Admin logs viewer** | ✅ |
| **Animated splash screen** | ✅ |
| **CI/CD** (GitHub Actions) | ✅ |
| **Privacy policy** | ✅ |
| **Web app** (Firebase Hosting) | ✅ |
| **Custom domain** (nsat.niu.edu.in) | ✅ |
| **Code audit** (45 issues, critical resolved) | ✅ |
| **Auto-submit safety net** (autoSubmitExpired) | ✅ |
| **App Check** — monitoring mode on all callable CFs | ✅ |
| **Screenshot blocking** (Android FLAG_SECURE + web) | ✅ |
| **Clipboard lockdown** (NoPasteFormatter + SelectionContainer) | ✅ |
| **Device fingerprinting** (device_info_plus → Firestore) | ✅ |
| **Answer sync** (crash recovery every 30s) | ✅ |
| **Google Play listing + AAB** | ✅ |
| **End-to-end dry run** | ✅ |
| Release AAB | ✅ |
| Google Play listing | ✅ |
| iOS build | 🔧 |
| App Check (Cloud Functions) | ✅ |

---

## 📐 Codebase Stats

| Category | Count | Lines |
|---|---|---|
| Models | 11 files | ~820 |
| Services | 21 files | ~2,070 |
| Providers | 3 files | ~830 |
| Widgets | 12 files | ~1,550 |
| Student Screens | 7 files | ~4,180 |
| Admin Screens | 10 files | ~3,290 |
| Cloud Functions (TS) | 10 files | ~1,600 |
| Utils | 1 file | ~30 |
| **Total Dart** | **65 files** | **~13,100** |

---

## 📄 License

Developed for **Noida International University** ([niu.edu.in](https://niu.edu.in)). All rights reserved.

---

<div align="center">

**NSAT** · Flutter + Firebase · Noida International University

</div>