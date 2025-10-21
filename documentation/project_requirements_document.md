# Project Requirements Document

## 1. Project Overview

This project is a mobile application built with Flutter and Supabase that digitizes student attendance using NFC cards and motivates participation through gamification. Students tap their MIFARE Classic cards on an admin’s device to check in for class; the system records attendance, automatically awards points, and updates leaderboards in real time. Teachers and administrators gain a smooth way to track attendance, while school owners can view high-level analytics on engagement.

We’re building this to replace manual attendance logs, increase student engagement, and provide actionable insights to school staff. Success means delivering a reliable NFC check-in flow, a robust backend engine that handles points, streaks, and redemptions, plus easy-to-use dashboards for three roles: Student, Admin, and Owner. Key objectives include 99% uptime for check-ins, sub-second real-time updates, and secure, role-based data access.

---

## 2. In-Scope vs. Out-of-Scope

### In-Scope (Version 1)
- User authentication with Supabase Auth (email/password) and role assignments (Student, Admin, Owner)
- Role-based routing and Row Level Security (RLS) policies
- Admin-facing NFC check-in screen (using `flutter_nfc_kit`) that records attendance and awards points via Supabase Edge Functions
- Core gamification engine: point transactions, streak calculations, achievement unlocking
- Student dashboard: attendance history, points balance, earned badges
- Admin dashboard: class list management, attendance logs, merchandise order processing
- Owner dashboard: interactive analytics charts (using `fl_chart`) and leaderboards
- Real-time updates via Supabase Realtime subscription
- Basic merchandise redemption flow (points deduction + order creation)
- Reusable Flutter widget library (StatCard, LeaderboardListItem, AchievementBadge)
- Environment variable management for Supabase credentials (`flutter_dotenv`)
- Unit tests for Edge Functions, widget tests, integration tests for critical flows

### Out-of-Scope (Planned for Later Phases)
- Offline NFC check-in support
- Advanced merchandise inventory management and supplier integrations
- Push notifications (FCM integration)
- Multi-campus or multi-tenant support
- Web or desktop clients (mobile only in v1)
- Deep custom reporting exports (CSV/PDF)
- Social or chat features among students

---

## 3. User Flow

A student opens the Flutter app and signs in with their email and password. Upon login, Supabase Auth checks their role claim and routes them to the Student Dashboard, where they immediately see their attendance history, total points, and any unlocked badges. They navigate through a bottom tab bar to view leaderboards, redeem points for merchandise, or update their profile.

An admin launches the app, signs in, and is sent to the Admin Dashboard. They tap on “Live NFC Check-In,” which activates the device’s NFC reader. When a student taps their card, the app captures the UID and calls a Supabase Edge Function `record-attendance`. That function validates the admin’s role, logs attendance, awards points, and triggers a real-time update so all connected clients (including the student’s device) refresh immediately. Owners follow a similar login flow but land on charts and data tables showing overall engagement and attendance trends.

---

## 4. Core Features

- **Authentication & Role Management**: Sign-up/sign-in with Supabase Auth, custom claims for Student/Admin/Owner, enforced via RLS.
- **NFC Attendance Check-In**: Admin screen powered by `flutter_nfc_kit`, captures card UID and calls Edge Function.
- **Supabase Edge Functions**: TypeScript functions for `record-attendance`, `calculate-leaderboard`, `process-redemption`, handling atomic point and attendance logic.
- **Real-Time Updates**: Subscriptions to attendance and points tables; UI updates without manual refresh.
- **Student Dashboard**: Attendance log, points balance, badges, and leaderboard view.
- **Admin Dashboard**: Class management, attendance logs with filtering, merchandise order processing.
- **Owner Dashboard**: Interactive analytics charts (fl_chart), system health metrics, export options.
- **Gamification Engine**: Points transactions, streak bonuses, achievements, and redemption rules.
- **Merchandise Redemption**: UI to select items, verify point balance, deduct points, and create an order record.
- **Reusable UI Components**: Custom Flutter widgets for consistent UI across 50+ screens.
- **Security & Compliance**: Environment-based config, RLS policies, server-side validation.
- **Testing Suite**: Unit tests for Edge Functions, widget tests for UI components, integration tests for NFC flow.

---

## 5. Tech Stack & Tools

- **Frontend**: Flutter (Dart) using Material Design 3.
- **State Management**: Riverpod for global and scoped state.
- **NFC**: `flutter_nfc_kit` package.
- **Charts**: `fl_chart` for interactive analytics.
- **Backend**: Supabase (PostgreSQL) with Auth, Database, Realtime, Storage.
- **Edge Functions**: Supabase Edge Functions written in TypeScript.
- **Environment Variables**: `flutter_dotenv` for Supabase URL and anon key.
- **Testing**: Flutter’s built-in widget and integration test frameworks; Jest (or Vitest) for Edge Functions.
- **IDE/Plugins**: Visual Studio Code or Android Studio, Pubspec Assist, Flutter Lints, Supabase VSCode extension.

---

## 6. Non-Functional Requirements

- **Performance**: Edge Functions respond within 200 ms; UI updates <1 s after data change.
- **Scalability**: Handle up to 1,000 concurrent users and 100 check-ins per minute.
- **Security**: All traffic over HTTPS; environment variables for secrets; strict RLS policies; server-side input validation.
- **Usability & Accessibility**: Conform to WCAG 2.1 AA where possible; high-contrast themes; clear error messaging.
- **Reliability**: 99% uptime for core features; automatic retries on transient failures.

---

## 7. Constraints & Assumptions

- Supabase services (Auth, Edge Functions, Realtime) remain within free or budgeted tier limits.
- Target devices support the `flutter_nfc_kit` package and MIFARE Classic card reading.
- Continuous internet connectivity during NFC check-in (no offline mode in v1).
- Team is proficient in Dart, TypeScript, and understands Supabase and Flutter paradigms.
- Supabase Edge Functions have enough cold-start and execution performance for real-time needs.

---

## 8. Known Issues & Potential Pitfalls

- **Supabase Rate Limits**: Hitting function invocation or database row limits could throttle check-ins. Mitigation: batch requests or add client-side debounce.
- **NFC Hardware Variability**: Some Android/iOS devices might not support certain card types. Mitigation: test on a matrix of common models and provide a manual check-in fallback.
- **RLS Misconfiguration**: Incorrect policies could expose user data. Mitigation: write comprehensive policy tests and run them in CI.
- **High-Volume Chart Data**: Rendering thousands of data points can lag. Mitigation: paginate or sample data series on the backend.
- **Offline Scenarios**: Without connectivity, check-ins fail. Mitigation: display clear error states and allow retry logic once back online.
- **Edge Function Cold Starts**: Cold starts may add latency. Mitigation: keep functions warmed or optimize code for minimal startup.

---

This PRD provides a clear, unambiguous blueprint for the AI or development team to build the NFC attendance gamification app with Flutter and Supabase. All core flows, boundaries, and quality expectations are laid out to avoid guesswork in subsequent technical documentation.