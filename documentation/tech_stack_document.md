# Tech Stack Document for codeguide-nfc-attendance-gamify

This document explains in everyday terms why we chose each technology and how they fit together. It should help anyone understand the key building blocks without needing a deep technical background.

## Frontend Technologies

The frontend is what students, admins, and owners see and interact with on their mobile devices. We focused on a smooth user experience, clear visuals, and reusable pieces to speed up development.

**Key Technologies**
- Flutter (Dart) for building the entire app in one codebase that runs on both iOS and Android
- Riverpod for managing application state (user info, live leaderboards, achievement notifications)
- flutter_nfc_kit package for reading NFC card UIDs during check-in
- fl_chart package for drawing interactive charts in the Owner’s analytics dashboard
- Material Design 3 for a consistent look and feel across more than fifty screens
- .env files or compile-time variables for storing Supabase keys securely

**Why these choices?**
- Flutter lets us maintain one codebase for two platforms, speeding up development and ensuring consistency.
- Riverpod keeps data flow easy to understand and debug, so screens update in real time when data changes.
- Packages like flutter_nfc_kit and fl_chart provide ready-made components for NFC scanning and charts, so we don’t have to build those from scratch.
- Using Material Design 3 and a shared widget library (StatCard, LeaderboardListItem, AchievementBadge) ensures all screens look and behave similarly.

## Backend Technologies

The backend handles data storage, business logic, authentication, and real-time updates. We chose a serverless approach to focus on writing the features we need.

**Key Technologies**
- Supabase Auth for secure sign-up, login, and custom user roles (User, Admin, Owner)
- Supabase Database (PostgreSQL) for storing profiles, NFC cards, attendance records, points, achievements, orders, etc.
- Row Level Security (RLS) policies to ensure each role only sees or changes the data they’re allowed to
- Supabase Edge Functions (TypeScript) for server-side logic:
  - `record-attendance` (validate NFC check-in, award points)
  - `calculate-leaderboard` (update rankings)
  - `process-redemption` (handle merchandise orders atomically)
  - `check-achievements` (unlock badges after certain point thresholds)
- Supabase Realtime to push live updates (attendance, point totals, leaderboards) to connected devices without refreshing
- Supabase Migrations (via Supabase CLI) to version and apply database schema changes in a repeatable way

**Why these choices?**
- Supabase offers an all-in-one hosted solution (database, auth, real-time, functions) so we don’t manage servers ourselves.
- Edge Functions in TypeScript give us type safety and clear separation of business logic from the Flutter UI.
- RLS policies enforce security right at the database level so mistakes in client code can’t expose data.
- Realtime updates make the experience feel instantly responsive when students check in or redeem points.

## Infrastructure and Deployment

Reliable hosting, automated testing, and smooth deployments help us move quickly while keeping quality high.

**Key Choices**
- GitHub (or GitLab) for version control and code review
- GitHub Actions (CI/CD) to run tests and deploy Edge Functions automatically on each commit
- Docker for a reproducible development environment (especially for local Supabase emulation and migrations)
- Supabase Hosting (managed) for database and functions, removing the need to maintain servers
- Flutter build pipelines (e.g., CodeMagic or GitHub Actions) to produce signed iOS and Android app packages

**How it helps**
- Automated pipelines catch errors early (tests, linting, type checks) so issues don’t make it to production.
- Docker ensures every developer has the same setup, minimizing “works on my machine” problems.
- Managed hosting means we can scale database and functions without manual server provisioning.

## Third-Party Integrations

Beyond our core stack, we leverage a few external services to add key features quickly.

- Firebase Cloud Messaging (FCM) for push notifications (achievement unlocked, order status updates)
- Supabase Realtime API for live data streams (attendance updates, leaderboard changes)

**Benefits**
- FCM integrates easily with Flutter and Edge Functions, letting us notify users instantly.
- Supabase Realtime is built-in, so we don’t need an extra WebSocket service.

## Security and Performance Considerations

We treat security and smooth performance as top priorities to protect user data and keep the app feeling fast.

**Security Measures**
- Supabase Auth and RLS ensure users only access the data their role allows
- Environment variables (.env) keep secrets out of source control
- Server-side validation in every Edge Function before database writes
- Row Level Security as a final safety net in the database

**Performance Optimizations**
- Real-time subscriptions in the client so screens update incrementally rather than full reloads
- Reusable, lightweight Flutter widgets to minimize rebuild costs
- TypeScript in Edge Functions to catch errors at build time, reducing runtime failures
- Database indexing on key columns (e.g., NFC UID, user_id) for fast lookups

## Conclusion and Overall Tech Stack Summary

We selected this stack to meet three core goals: rapid development, robust security, and an engaging real-time experience.

- **Flutter + Riverpod** provides a single, consistent codebase for mobile apps, backed by a shared widget library and Material Design 3.
- **Supabase (Auth, Database, Realtime, Edge Functions)** offers a fully managed backend so we focus on business logic, not infrastructure.
- **CI/CD + Docker** ensures we ship high-quality code quickly and reliably.
- **FCM** and **Supabase Realtime** power push notifications and live updates that make attendance tracking and gamification feel instant.

This combination of technologies aligns perfectly with the project’s goals, giving us a scalable, secure, and user-friendly platform for NFC-driven attendance and gamified student engagement.