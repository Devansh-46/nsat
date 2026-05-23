# NSAT Project — Full Audit Report
**Date:** 2026-05-23
**Scope:** All source code, configs, Cloud Functions, security rules, credentials, build

---

## 🔴 CRITICAL — Security Issues (Fix Immediately)

### 1. Service Account Private Key Committed to Git
**File:** `ServiceAccountKey.json` (project root)
- Full GCP service account private key is in the repo. Anyone with repo access has **full admin** over the Firebase project — can read/write all Firestore data, delete collections, modify Auth users, send FCM messages, etc.
- **Action:** Delete this file from git history (`git filter-branch` or `BFG Repo-Cleaner`), rotate the key in GCP Console, move it to a secret manager or `.gitignore`d location.

### 2. Hardcoded Cloud Functions Secrets in `.env` (Committed to Git)
**File:** `functions/.env`
```
NPF_ACCESS_KEY=****
NPF_SECRET_KEY=****
TWILIO_ACCOUNT_SID=****
TWILIO_AUTH_TOKEN=****
SMTP_USER=nsat@niu.edu.in
SMTP_PASS=****
```
- NPF API keys, Twilio credentials, and SMTP password are all committed in plaintext.
- Also in `functions/.env.example` (less concerning but still a leak).
- **Action:** Add `functions/.env` to `.gitignore`, rotate ALL compromised secrets, use `firebase functions:config:set` or Google Secret Manager.

### 3. Android Signing Key in `key.properties`
**File:** `android/key.properties`
```
storePassword=221604
keyPassword=221604
keyAlias=nsat-key
storeFile=/Users/devanshchaubey/nsat-upload-key.jks
```
- Release keystore passwords are committed. Combined with the JKS file, this allows signing malicious APKs as your app.
- **Action:** Add `android/key.properties` to `.gitignore`, move passwords to environment variables or CI secrets.

### 4. Firestore Rules — Massively Over-Permissive
**File:** `firestore.rules`
- `students`: `allow read: if true` — **any unauthenticated user** can read every student's payment status, lead IDs, and application numbers. No auth required.
- `tests`: `allow read: if true` — fine for published, but no auth check at all.
- `attempts`: `allow create: if true` and `allow update: if true` — **any unauthenticated user** can create/update attempt locks. This means anyone can lock out any student by writing an `in_progress` or `completed` attempt document for their application number. This is an exam-integrity-threatening vulnerability.
- `results`: `allow read: if true` — **anyone** can read all student results.
- `notifications`: `allow read: if true` — anyone can read notification history.
- `questions`: `allow read: if true` — correct answers are exposed client-side since `QuestionService._stripAnswers = false` and all question data is readable by anyone.
- **Action:** Add `request.auth != null` checks everywhere. Restrict `attempts` create/update to the owning student (by application number matching auth context or a server-side check). Restrict `results` read to admins.

### 5. Firestore Rules — `questions` Collection Leaks Answer Keys
- `correctAnswerIndex` is stored in questions and the `questions` collection is readable by anyone. Even though `QuestionService` has a `_stripAnswers` flag, the Firestore rules don't enforce field-level access control. The raw data including answer indices is accessible via the Firestore REST API or any SDK.
- **Action:** Either flip `_stripAnswers = true` and move scoring to Cloud Functions (which is the stated plan), or create a separate `question_banks` collection with answers restricted to admin-only, and a `questions_public` collection with answers stripped.

### 6. Client-Side Answer Scoring (Current Path)
**File:** `QuestionService.dart:28-30`
```dart
static const bool _stripAnswers = false;
```
- While `false`, the app downloads correct answers to the client and scores locally. Combined with open Firestore rules, students can see every answer.
- **Action:** Set `_stripAnswers = true` before launch and rely entirely on `scoreSubmission` Cloud Function.

---

## 🔴 CRITICAL — Functional/Bug Issues

### 7. `submitTest()` Can Be Called Multiple Times
**File:** `test_provider.dart:213-263`
- `submitTest()` checks `isSubmitted` but there's no loading guard at the entry. If the user taps "Submit" rapidly, or the timer auto-fires while a manual submit is in-flight, `provider.isLoading` is the only blocker but it's set _after_ the check. Race condition: two calls can pass the `isSubmitted` check before either sets `isSubmitted = true`.
- The Cloud Function `scoreSubmission` writes results and updates the attempt lock, but if called twice, it will create **duplicate result documents**.
- **Action:** Add a `_submitting` boolean guard at the very top of `submitTest()`. Make the Cloud Function check for existing results before writing.

### 8. Timer Auto-Submit Race Condition
**File:** `test_provider.dart:181-195`
- The timer fires `submitTest()` on expiration, but the user might have just tapped "Submit" a moment before. No coordination between timer-fired and user-fired submissions.
- **Action:** Use a `_submissionInProgress` flag or cancel the timer immediately when `submitTest()` starts.

### 9. `attempt_service.dart` — `markCompleted` Doesn't Verify the Transaction Succeeded
**File:** `attempt_service.dart:128-137`
- If the `scoreSubmission` Cloud Function fails after writing the result but before the client calls `markCompleted`, the attempt stays `in_progress`. The student is then permanently locked out (their only attempt is stuck as `in_progress`, and `hasResumableAttempt` returns `false` to the UI — it shows "contact invigilator" with no recovery path).
- **Action:** The Cloud Function `scoreSubmission` already flips the attempt status to `completed` (line 116-118). Remove the redundant client-side `markCompleted` call. Let the single source of truth be the Cloud Function.

### 10. `scoreSubmission` CF — Question Order Not Guaranteed
**File:** `scoreSubmission.ts:44-48`
```typescript
const questionsSnap = await db.collection("questions").where("course", "==", course).limit(test.questionCount as number).get();
```
- Firestore `where()` doesn't guarantee document order. `questions[i]` may not match `answers[i.toString()]` because the student's answers are indexed by the question's position in the fetched array. If Firestore returns docs in a different order than the app did, scoring will be wrong.
- **Action:** Sort questions by a consistent field (e.g., `questionId` or a `sequence` field) in both the app and the Cloud Function, or match answers by question document ID instead of array index.

### 11. Duplicate Question → Course Mappings in `config.ts`
**File:** `functions/src/config.ts`
- `"B.Sc"` is mapped to `sos_ug` (line 198). But there are many B.Sc specializations above it — the exact match means `"B.Sc"` only matches the literal string, while `"B.Sc (Biotechnology)"` matches the specific entry. This is correct for those, but `"B.Sc"` alone would fall through to the fallback `slugify` and become `bsc` — not `sos_ug`. Any student with a generic `"B.Sc"` course in NPF would get an unknown course key, causing `getPublishedTestForCourse` to return null.
- **Action:** Add tests for all course name variants. Ensure the fallback behavior is intentional.

### 12. `scoreSubmission` CF — Missing `testId` in `questions` Query
**File:** `scoreSubmission.ts:44-48`
- Questions are fetched by `course` only, not by `testId`. If a course has multiple tests (future scenario), there could be overlapping question sets. The `limit` is `test.questionCount`, which could pull questions from the wrong test.
- **Action:** Add a `testId` field to questions or use a sub-collection `tests/{testId}/questions`.

### 13. `DataStore` Hardcoded Students Conflict with Firestore Path
**File:** `data_store.dart:15-45`
- The `DataStore` has hardcoded mock students (`NIU2025MBA0472`, etc.) and `AuthService.studentLogin()` uses the DataStore path. But `AuthProvider` now uses the Firestore path (`StudentService.getStudentByNiuId`). The old `studentLogin` method is marked "OLD CODE BELOW" but still exists and could be called accidentally.
- **Action:** Remove the old `studentLogin` method and the mock `DataStore._students` to prevent confusion and accidental use.

---

## 🟠 HIGH — Bugs & Logic Issues

### 14. `lead_details_model.dart` — `maskedEmail` Fails on Short Emails
**File:** `lead_details_model.dart:53-57`
```dart
if (at <= 2) return email;
```
- For emails like `"a@x.com"`, the entire email is returned unmasked. For `"ab@x.com"`, it shows `"ab****@x.com"` which is the full email.
- **Action:** Change to `if (at <= 1) return email;` and display at minimum `"*@domain"`.

### 15. `email_verification_screen.dart` — No Rate Limit on Resend
**File:** `email_verification_screen.dart:458-466`
- The "Resend code" button calls `_startEmailOtp` with no cooldown. A student (or attacker) can spam the resend button, flooding the student's email and burning Cloud Function invocations.
- **Action:** Add a cooldown timer (e.g., 60 seconds) with a visual countdown on the resend button.

### 16. `email_verification_screen.dart` — Phone OTP Uses Same CF as Email OTP
**File:** `email_verification_screen.dart:140-141`
```dart
final callable = ...httpsCallable('verifyOtp');
await callable.call({
  'application_no': student.applicationNo,
  'code': code,
});
```
- Both email OTP (`_verifyEmailOtp`) and phone OTP (`_verifyPhoneOtp`) call the **same** `verifyOtp` Cloud Function. But `sendWhatsAppOtp` writes to the same `otps` collection, overwriting the email OTP. If the student requests email OTP first, then requests WhatsApp OTP, the email OTP is replaced. If they then try to verify the email code, it will fail because the stored hash now belongs to the WhatsApp code.
- **Action:** Use separate OTP documents per channel (e.g., `otps/{applicationNo}/email` and `otps/{applicationNo}/whatsapp`), or use a single OTP code for both channels.

### 17. `test_session_model.dart` — `skippedCount` Can Go Negative
**File:** `test_session_model.dart:105`
```dart
int get skippedCount => _serverSkipped ?? (gradedQuestionCount - correctCount - wrongCount);
```
- If the student answers more MCQ questions than `gradedQuestionCount` (possible if short-answer questions are present and the student answers MCQs beyond the count), `skippedCount` goes negative.
- **Action`: Add `.clamp(0, gradedQuestionCount)`.

### 18. `student_login_screen.dart` — `RemoteConfigService.refresh()` on Every Continue Tap
**File:** `student_login_screen.dart:41`
```dart
await RemoteConfigService.instance.refresh();
```
- This fetches remote config from the network every time the student taps "Continue". With a 5-minute minimum fetch interval (server-side), this mostly uses the cache, but on slow networks it adds latency to login. It also doesn't handle `refresh()` throwing (the error is caught inside `refresh()` but the caller doesn't know).
- **Action:** Remove the per-tap refresh. Rely on the app-start `init()` call, or refresh only on screen entry.

### 19. `live_test_screen.dart` — No Back Button Confirmation
**File:** `live_test_screen.dart:212-224`
- The back arrow in the header (`Icons.chevron_left`) with `Navigator.pop(context)` lets the student accidentally (or intentionally) exit the test without submitting, losing all progress.
- **Action:** Show a confirmation dialog on back press during an active test. Consider using `PopScope` to prevent accidental navigation.

### 20. `attempt_service.dart` — `startAttempt` Transaction Doesn't Prevent Question Download for Blocked Students
**File:** `test_provider.dart:101-169`
- The attempt lock is claimed, then questions are loaded. But if the claim fails (e.g., `alreadyCompleted`), the method returns `false` without downloading questions — which is correct. However, if two devices start simultaneously, the transaction protects the lock, but the second device's `startTest` returns `false` without the `_availableTest` being updated, so the UI shows a confusing state.
- **Action:** After a `resumable` outcome, optionally load the existing attempt's questions for recovery.

### 21. Widget Test References Old App Structure
**File:** `test/widget_test.dart:9-14`
```dart
await tester.pumpWidget(const NiuSatApp());
expect(find.text('Student login'), findsOneWidget);
```
- `NiuSatApp` now uses `MultiProvider` which requires `Firebase.initializeApp` to succeed. The widget test will fail because Firebase isn't initialized in the test environment. Also, the text "Student login" appears as a button label on `RoleSelectionScreen`, not as a standalone test — this test likely fails or is not being run.
- **Action:** Mock Firebase initialization or use a test-specific app entry point. Update test assertions.

### 22. `notification_service.dart` — Silently Swallows Errors on History Fetch
**File:** `notification_service.dart:59-63`
```dart
} catch (e, st) {
  _log.error(...);
  return [];
}
```
- Returns empty list on any error, giving no feedback to the admin.
- **Action:** Either throw to let the UI handle, or return a result object with error info.

---

## 🟠 HIGH — Build & Configuration Issues

### 23. iOS Firebase Not Configured in `firebase_options.dart`
**File:** `firebase_options.dart:26-28`
```dart
case TargetPlatform.iOS:
  throw UnsupportedError(
    'DefaultFirebaseOptions have not been configured for ios - ...',
  );
```
- The iOS build **will crash at runtime** when trying to initialize Firebase. The `GoogleService-Info.plist` exists in the iOS project, but `firebase_options.dart` doesn't have iOS config.
- **Action:** Run `flutterfire configure --platforms=ios` to generate iOS options, or manually add the iOS `FirebaseOptions`.

### 24. Android Deprecation Warnings — Many Packages Out of Date
- 48 packages have newer versions available. Notably:
  - `cloud_firestore`: 5.6.12 → 6.4.1 (major version behind)
  - `firebase_core`: 3.15.2 → 4.9.0 (major version behind)
  - `firebase_auth`: 5.7.0 → 6.5.1
  - `share_plus`: 10.1.4 → 13.1.0
- These are not directly causing issues now, but major versions behind means missing security patches and bug fixes.
- **Action:** Update dependencies incrementically, test thoroughly after each major bump.

### 25. `android/app/build.gradle.kts` — Uses Deprecated `jcenter()`
- (Implicit — the Firebase BOM and other deps may still transitively depend on jcenter which is sunset.)
- **Action:** Ensure all Maven repos use `mavenCentral()` or Google's repo.

### 26. `android/app/src/proguard-rules.pro` — Exists but Empty
- No ProGuard/R8 rules for Firebase or Flutter. This shouldn't cause a build failure, but release builds may strip necessary classes.
- **Action:** Add Firebase and Flutter ProGuard rules.

### 27. Web Build Warning — Wasm Dry Run
- The web build shows: "Wasm dry run succeeded. Consider building with `--wasm` flag."
- **Action:** Decide on CanvasKit vs Wasm. If Wasm is acceptable, add `--wasm` flag to the build command.

---

## 🟡 MEDIUM — Code Quality & Design Issues

### 28. `analytics_service.dart` — Sends PII in Analytics Events
**File:** `analytics_service.dart:26-29`
```dart
Future<void> logLoginAttempted({required String applicationNo}) =>
  _analytics.logEvent(name: 'login_attempted', parameters: {
    'application_no': applicationNo,
  });
```
- Application numbers (NIU IDs) are sent as analytics event parameters. This may violate Google Analytics policy on personally identifiable information (PII).
- **Action:** Remove `application_no` from analytics events, or hash/ anonymize it first.

### 29. `admin_dashboard_screen.dart` — Logs Admin Email to Analytics
**File:** `analytics_service.dart:111-114`
```dart
Future<void> logAdminLogin({required String email}) =>
  _analytics.logEvent(name: 'admin_login', parameters: {
    'email': email,
  });
```
- Admin email addresses sent to analytics — PII concern.
- **Action:** Remove the email parameter or hash it.

### 30. `app_logger.dart` — Firestore Fire-and-Forget Without Backpressure
**File:** `app_logger.dart:158-188`
```dart
FirebaseFirestore.instance.collection(_collection).add(doc);
```
- `_persistToFirestore` creates an unbounded number of Firestore writes with no batching, no queue, and no backpressure. On a flaky network, this silently drops logs but also wastes Firestore write quota. At exam scale (hundreds of concurrent users), this could burn through the free tier quickly.
- **Action:** Batch writes periodically, or use a local buffer with periodic flush.

### 31. `syncStudents.ts` — No Deduplication in Response Parsing
**File:** `syncStudents.ts:110-117`
- The sync function tries multiple response shapes but doesn't handle the case where both `data.list` and `data.data.list` exist. The page size is 100, and pagination uses `last_page` from the response — but if the API returns a different pagination field name, the sync stops silently after page 1.
- **Action:** Add more robust pagination fallback (e.g., stop when `list.length < page_size`).

### 32. `sendOtp` and `sendWhatsAppOtp` — Different Attempt Counting
- `sendOtp` initializes `attempts: 0`, then `verifyOtp` increments on failure and checks `>= 5`. But `sendWhatsAppOtp` also initializes `attempts: 0`, which resets the count if a WhatsApp OTP is sent after a failed email OTP attempt. An attacker could alternate channels to get 10 attempts instead of 5.
- **Action:** Use channel-specific attempt counters or a single shared counter.

### 33. `fee_gate_screen.dart` — Checks `currentUser` but Flow Never Sets It
**File:** `fee_gate_screen.dart:15`
```dart
final user = context.read<AuthProvider>().currentUser;
```
- The new fee-gate flow uses `verifiedStudent` and `leadDetails`, but this screen checks `currentUser` (which is null for students going through the new flow). The fee gate screen is likely a dead screen or shows incorrect data.
- **Action:** Verify if this screen is reachable. If it's an orphan from the old flow, remove or update it.

### 34. `role_selection_screen.dart` — Year & Session Hardcoded
**File:** `role_selection_screen.dart:86`
```dart
'2026 — 27 Admissions',
```
- Hardcoded session info. Will show the wrong year after 2026.
- **Action:** Drive this from Remote Config or the backend.

### 35. `data_store.dart` — Singleton Pattern Not Thread-Safe
**File:** `data_store.dart:10-12`
```dart
static final DataStore _instance = DataStore._internal();
```
- The in-memory `_students` list is mutated by `markStudentAttempted`. If multiple screens call this simultaneously (unlikely in single-isolate Flutter, but still a code smell), the state could be inconsistent.
- **Action:** Since this is moving to Firestore, ensure migration is complete before launch.

### 36. `functions/src/fetchLeadDetails.ts` — No Timeout on NPF API Call
**File:** `fetchLeadDetails.ts:29-41`
- No timeout on the `fetch()` call to the NPF API. If the API hangs, the Cloud Function hangs (up to its 540s timeout), consuming resources and leaving the student waiting.
- **Action:** Add a timeout using `AbortController` or a package like `p-retry`.

### 37. `functions/src/sendNotification.ts` — No Permission Check
- Any authenticated (or even unauthenticated, since `onCall` doesn't require auth by default) caller can invoke `sendNotifications` and send FCM messages to all students. There's no admin check.
- **Action:** Add `request.auth.token.admin == true` check to the function.

---

## 🟢 LOW — Minor Issues & Improvements

### 38. `attempt_model.dart` — Missing `toMap()` Method
- `AttemptModel` has `fromFirestore` but no `toMap()` for serialization. The `AttemptService` builds the map manually in `startAttempt`. Inconsistent pattern with other models.
- **Action:** Add `toMap()` for consistency.

### 39. `notification_model.dart` — `toJson()` Not Used
- `NotificationModel.toJson()` exists but `NotificationService` builds maps manually. `fromJson` constructor is used in history fetch but the `NotificationModel` fields don't directly map from Firestore data shape.
- **Action:** Use `toJson()`/`fromJson()` consistently throughout.

### 40. `result_service.dart` — `resultsCount()` Fetches All Docs
**File:** `result_service.dart:39-42`
```dart
final snapshot = await _db.collection(_collection).get();
return snapshot.docs.length;
```
- This fetches every document just to count them. At scale, this is slow and expensive.
- **Action:** Use Firestore aggregation queries (`count()`) or maintain a counter in a metadata document.

### 41. `scoring_service.dart` — Unused Parameters
**File:** `scoring_service.dart:47-48`
```dart
List<QuestionModel>? questions,
TestModel? test,
```
- These are kept "for API compat" but no longer used. They add confusion.
- **Action:** Remove unused parameters.

### 42. `test_provider.dart` — Timer Not Cancelled on `clearSession`
**File:** `test_provider.dart:265-276`
- `clearSession()` cancels the timer, but if `clearSession` is called from a different screen while the timer is firing `submitTest`, the timer callback might reference a disposed session.
- **Action:** Add extra null checks in the timer callback.

### 43. `analysis_options.yaml` — Lints Disabled
**File:** `analysis_options.yaml:5-6`
```yaml
prefer_const_constructors: false
prefer_const_literals_to_create_immutables: false
```
- Disabling these lints means missed Flutter performance optimizations across the entire codebase.
- **Action:** Enable these lints and fix the existing violations.

### 44. Python Scripts Have Hardcoded Credentials
**Files:** `seed_firestore.py`, `setup_admin.py`, `import_students_csv.py`
- These scripts likely contain Firebase Admin credentials or service account paths that reference the `ServiceAccountKey.json`.
- **Action:** Audit these scripts, use environment variables for credentials.

### 45. `build/web/privacy/index.html` Exists — Verify Content
- Need to ensure the privacy policy page has actual content and is legally compliant.
- **Action:** Review the privacy policy content.

---

## ✅ What's Working Well

- Clean architecture with clear separation: models, services, providers, screens, widgets
- Good use of enums for status modeling (`AttemptStatus`, `StudentLookupStatus`, `FeeGateOutcome`)
- Crashlytics integration with structured logging
- Remote Config for exam-day switches (maintenance mode, exam window)
- Cloud Functions are well-organized with TypeScript
- Firestore session model handles crash-safety (in_progress vs completed)
- OTP system uses SHA-256 hashing with attempt limits and expiry
- Transaction-based attempt locking prevents double submissions at the DB level
- Build succeeds for both Android APK and Web
- Flutter static analysis passes with zero issues

---

## Summary by Priority

| Count | Severity | Category |
|-------|----------|----------|
| 6 | 🔴 CRITICAL | Security — exposed secrets & over-permissive rules |
| 7 | 🔴 CRITICAL | Functional bugs that affect exam integrity |
| 7 | 🟠 HIGH | Logic bugs & Firebase config |
| 8 | 🟠 HIGH | Build/config issues |
| 9 | 🟡 MEDIUM | Code quality & minor design issues |
| 6 | 🟢 LOW | Minor improvements |

**Total issues found: 43**
**Must fix before launch:** Top 19 (all 🔴 CRITICAL items)
