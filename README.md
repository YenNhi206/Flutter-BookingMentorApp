# MentorLink

A Flutter mobile app for booking 1-on-1 sessions with industry mentors — built for
PRM393 (Mobile Application Development). The business scenario is a Flutter
reinterpretation of a mentor-booking platform, covering three roles: **student**,
**mentor**, and **admin**.

## Business scenario

Students preparing for job interviews or upskilling often want short, paid
sessions with experienced professionals, on-demand courses, and CV feedback.
MentorLink models the full three-sided marketplace:

**Student**
1. Browse a catalog of mentors (name, title, expertise, hourly rate, rating)
2. Open a mentor's profile, read their bio and reviews
3. Book a session (pick date, time slot, duration) and pay via a simulated checkout
4. Get an in-app + OS-level notification when the booking is confirmed
5. Message the mentor directly and see the meeting location on a map
6. Browse and enroll in mentor-created courses, track lesson progress, earn a certificate
7. Paste a CV and a job description to get an on-device match score and skill gap analysis

**Mentor**
1. Dashboard with upcoming/completed sessions and total earnings
2. Confirm/complete/cancel bookings
3. Create courses (with lessons) that go through admin review before publishing

**Admin**
1. Platform-wide stats (users, mentors, bookings, revenue, bookings by status)
2. Approve/reject new mentor applications
3. Enable/disable user and mentor accounts
4. Approve/reject mentor-submitted courses
5. View all bookings across the platform

## Architecture

- **State management:** [`provider`](https://pub.dev/packages/provider) — each
  feature has a `ChangeNotifier` (`AuthProvider`, `MentorProvider`,
  `BookingProvider`, `ChatProvider`, `NotificationProvider`,
  `MentorDashboardProvider`, `CourseProvider`, `CvAnalysisProvider`,
  `AdminProvider`) that screens subscribe to via `Consumer`/`context.watch`.
- **Pattern:** Repository + MVVM-ish layering:
  `screens/` (View) → `providers/` (ViewModel) → `data/repositories/` (Repository)
  → `data/db/app_database.dart` (SQLite access via `sqflite`).
- **Database:** Local SQLite (`sqflite`) — chosen over Firebase/REST so the app
  is fully self-contained and gradeable without any external account setup.
  Tables: `users`, `mentors`, `bookings`, `chat_messages`, `notifications`,
  `reviews`, `courses`, `lessons`, `enrollments`, `cv_analyses`. Demo data is
  seeded automatically on first launch, and self-heals on upgrade if a device
  already has partial data from an earlier version (`lib/data/seed/seed_data.dart`).
- **Role-based navigation:** `app.dart` routes to `MainShell` (student),
  `MentorShell`, or `AdminShell` based on `UserProfile.role` after login.
- **Map:** [`flutter_map`](https://pub.dev/packages/flutter_map) with
  OpenStreetMap tiles — no API key required, unlike `google_maps_flutter`.
- **Local notifications:** `flutter_local_notifications` fires a real OS
  notification alongside the in-app notifications screen whenever a booking is
  confirmed or a mentor "replies" in chat.
- **CV/JD matching:** `lib/services/cv_match_service.dart` is a fully offline,
  on-device keyword matcher against a curated skill taxonomy — a deliberate
  scope simplification versus the Python/LLM pipeline a production system
  might use, so the feature works with zero network dependency or API cost.
- **Chat:** Since there's no live backend/second user account, mentor replies
  are simulated with a short delay and canned responses
  (`lib/providers/chat_provider.dart`) to demonstrate a working two-way chat UI
  and the notification pipeline. This is documented as a scope simplification
  for the report.

### Screens → assignment rubric mapping

| Sample rubric item      | Screen(s) |
|--------------------------|-----------|
| Login                    | `screens/auth/login_screen.dart`, `register_screen.dart` |
| Product list             | `screens/mentors/mentor_list_screen.dart` |
| Product detail           | `screens/mentors/mentor_detail_screen.dart` |
| Shopping cart            | `screens/booking/booking_screen.dart` |
| Checkout/billing         | `screens/booking/checkout_screen.dart` |
| Notifications            | `screens/notifications/notifications_screen.dart` |
| Map (location)           | `screens/map/session_map_screen.dart` |
| Messaging/chat           | `screens/chat/chat_list_screen.dart`, `chat_screen.dart` |
| State management         | `provider` package throughout |

### Additional features beyond the sample rubric

| Feature | Screens |
|---|---|
| Courses (browse/enroll/learn/certificate) | `screens/courses/*` |
| Mentor dashboard & course authoring | `screens/mentor/*` |
| Admin panel (stats, approvals, user/mentor/booking management) | `screens/admin/*` |
| CV/JD match analysis | `screens/cv/*` |

## Demo accounts

Seeded automatically on first launch (password for all: `Demo1234`), and also
available as one-tap chips on the login screen:

| Role    | Email              |
|---------|--------------------|
| Student | `student@demo.com` |
| Mentor  | `mentor@demo.com`  |
| Admin   | `admin@demo.com`   |

The mentor account is linked to the "Nguyễn Minh Anh" catalog profile, which
already has a published course and a pending-review course so the mentor
dashboard and admin approval queue have real data to demo immediately. One
extra mentor ("Đỗ Anh Khoa") is seeded with `pending` approval status to
demonstrate the admin's mentor-approval flow.

## Running the app

```bash
flutter pub get
flutter run
```

Requires an Android emulator, iOS Simulator, or physical device with Flutter's
toolchain set up (`flutter doctor`).

## Testing

```bash
flutter test
```

- **Unit test:** `test/unit/pricing_service_test.dart` — validates session
  price calculation and mentor double-booking (slot conflict) detection, the
  core business rules of the booking flow.
- **Widget test:** `test/widget/login_screen_test.dart` — validates the login
  form's client-side validation (empty fields, invalid email format).
- `test/widget_test.dart` — smoke test that the app boots to the login screen.

## Building a release APK / AppBundle

```bash
# APK
flutter build apk --release

# AppBundle (for Play Store)
flutter build appbundle --release
```

Output:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AppBundle: `build/app/outputs/bundle/release/app-release.aab`

**Proof of release mode:** install the release APK on a device/emulator
(`flutter install --release`, or drag the APK onto an emulator) and take a
screenshot/screen recording showing the app running — release builds strip the
debug banner and run with production-level performance, which you should
capture for the report's deployment section.

## Known limitations / future work

- No backend sync — data lives in local SQLite per device install. A future
  iteration could swap the repository layer for Firebase Firestore or a REST
  API without touching the providers or UI (the repository interfaces are
  already isolated for this).
- Chat is simulated (no second real user) since the project scope excludes a
  live multi-user backend.
- CV/JD matching is a local keyword matcher against a curated skill list, not
  an LLM/NLP pipeline — a deliberate trade-off for zero network dependency.
- Course lesson "video" content is text-only (no real video hosting/playback).
- Mentor self-registration isn't exposed in the UI yet — new mentors are
  seeded directly in `pending` status to demo the admin approval flow; a
  production version would add a "Become a mentor" application form.

This project is a scoped-down, from-scratch Flutter reinterpretation of the
mentor-booking feature set found in web-based mentor platforms; it does not
reuse any code from those projects.
