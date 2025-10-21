# Backend Structure Document

This document outlines the complete backend setup for the NFC-based attendance and gamification application. It covers the architecture, database design, API endpoints, hosting, infrastructure, security, and maintenance. Anyone reading this—technical or not—will understand how the backend is organized and why each component exists.

## 1. Backend Architecture

**Overall Design**
- We use a **serverless-style** backend powered by Supabase. Supabase provides managed PostgreSQL, authentication, real-time updates, and Edge Functions (serverless functions).
- Business logic (attendance recording, point calculations, redemption) lives in **TypeScript-based Edge Functions**. These functions run close to users for low latency and auto-scale with demand.
- Data access is performed through Supabase’s client libraries and built-in Row Level Security (RLS) policies, ensuring each role only sees allowed data.

**Key Frameworks & Patterns**
- Supabase Auth for user management and JWT issuance.
- Supabase Database (PostgreSQL) for reliable, relational storage.
- Supabase Edge Functions (on Deno Deploy) for business logic.
- Real-time subscriptions (via WebSockets) to push live updates to clients.
- Environment variables stored securely in Supabase project settings.

**Scalability, Maintainability & Performance**
- **Auto-scaling**: Edge Functions scale automatically with traffic.
- **Separation of Concerns**: Clear split between authentication, data storage, and business logic.
- **Re-use & Modularity**: Functions and database schemas are version-controlled, making future features easy to add.
- **Real-time**: Users see leaderboards and attendance updates instantly without polling.

## 2. Database Management

**Technologies & Types**
- Database type: **Relational (SQL)**
- Provider: **Supabase-managed PostgreSQL**
- Client access: Supabase JS/TS libraries and psql (for migrations)

**Data Organization & Access**
- Data is organized into well-named tables (e.g. `profiles`, `classes`, `attendance`).
- Each table has a primary key (`id`) and relevant foreign keys for relationships.
- **Row Level Security** policies ensure that:
  - Students see only their own attendance and points.
  - Admins can manage classes they are assigned to.
  - Owners have read/write access across the system.
- Backups happen daily and can be restored via the Supabase console.

## 3. Database Schema

Below is a human-readable overview followed by the SQL definitions for our core 16 tables.

### 3.1 Overview (Human-Readable)
1. **profiles**: User accounts (students, admins, owners) with contact info and role.
2. **nfc_cards**: Maps a physical card’s UID to a student profile.
3. **classes**: Defines courses or sessions (name, time, location).
4. **class_sessions**: Individual dates/times when a class meets.
5. **class_instructors**: Links admins to the classes they manage.
6. **attendance**: Records each student’s check-in for a session.
7. **events**: Special activities outside regular classes.
8. **event_attendance**: Records student participation in events.
9. **points_transactions**: Logs every point addition/subtraction.
10. **streaks**: Tracks ongoing attendance streaks for students.
11. **achievements**: Badges or milestones available to earn.
12. **user_achievements**: Which achievements each student has unlocked.
13. **merchandise**: Items available to redeem with points.
14. **orders**: Student redemption orders.
15. **order_items**: Line items for each order.
16. **notifications**: Messages pushed to users (achievement unlocked, order status, reminders).

### 3.2 SQL Definitions (PostgreSQL)
```sql
-- 1. profiles
enable row level security on profiles;
CREATE TABLE public.profiles (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email          text UNIQUE NOT NULL,
  full_name      text NOT NULL,
  role           text NOT NULL CHECK (role IN ('student','admin','owner')),
  avatar_url     text,
  created_at     timestamptz NOT NULL DEFAULT now()
);

-- 2. nfc_cards
enable row level security on nfc_cards;
CREATE TABLE public.nfc_cards (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  uid         text UNIQUE NOT NULL,
  profile_id  uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  assigned_at timestamptz NOT NULL DEFAULT now()
);

-- 3. classes
enable row level security on classes;
CREATE TABLE public.classes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  description text,
  location    text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- 4. class_sessions
enable row level security on class_sessions;
CREATE TABLE public.class_sessions (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id   uuid REFERENCES public.classes(id) ON DELETE CASCADE,
  session_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 5. class_instructors
enable row level security on class_instructors;
CREATE TABLE public.class_instructors (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id   uuid REFERENCES public.classes(id) ON DELETE CASCADE,
  admin_id   uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  assigned_at timestamptz NOT NULL DEFAULT now()
);

-- 6. attendance
enable row level security on attendance;
CREATE TABLE public.attendance (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id     uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  session_id     uuid REFERENCES public.class_sessions(id) ON DELETE CASCADE,
  check_in_time  timestamptz NOT NULL DEFAULT now()
);

-- 7. events
enable row level security on events;
CREATE TABLE public.events (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  description text,
  event_at    timestamptz NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- 8. event_attendance
enable row level security on event_attendance;
CREATE TABLE public.event_attendance (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id    uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_id      uuid REFERENCES public.events(id) ON DELETE CASCADE,
  check_in_time timestamptz NOT NULL DEFAULT now()
);

-- 9. points_transactions
enable row level security on points_transactions;
CREATE TABLE public.points_transactions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  points          int NOT NULL,
  type            text NOT NULL CHECK (type IN ('award','redeem','adjust')),
  description     text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- 10. streaks
enable row level security on streaks;
CREATE TABLE public.streaks (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id       uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  current_count    int NOT NULL DEFAULT 0,
  last_checkin     timestamptz NOT NULL
);

-- 11. achievements
enable row level security on achievements;
CREATE TABLE public.achievements (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name              text NOT NULL,
  description       text,
  points_required   int NOT NULL,
  icon_url          text,
  created_at        timestamptz NOT NULL DEFAULT now()
);

-- 12. user_achievements
enable row level security on user_achievements;
CREATE TABLE public.user_achievements (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  achievement_id  uuid REFERENCES public.achievements(id) ON DELETE CASCADE,
  achieved_at     timestamptz NOT NULL DEFAULT now()
);

-- 13. merchandise
enable row level security on merchandise;
CREATE TABLE public.merchandise (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  description     text,
  points_cost     int NOT NULL,
  stock_quantity  int NOT NULL,
  image_url       text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- 14. orders
enable row level security on orders;
CREATE TABLE public.orders (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id     uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  total_points   int NOT NULL,
  status         text NOT NULL CHECK (status IN ('pending','completed','cancelled')),
  ordered_at     timestamptz NOT NULL DEFAULT now()
);

-- 15. order_items
enable row level security on order_items;
CREATE TABLE public.order_items (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id        uuid REFERENCES public.orders(id) ON DELETE CASCADE,
  merchandise_id  uuid REFERENCES public.merchandise(id) ON DELETE CASCADE,
  quantity        int NOT NULL,
  item_points     int NOT NULL
);

-- 16. notifications
enable row level security on notifications;
CREATE TABLE public.notifications (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  type          text NOT NULL,
  content       text NOT NULL,
  is_read       boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now()
);
```

## 4. API Design and Endpoints

We follow a **RESTful** approach through Supabase’s auto-generated APIs and custom Edge Functions.

**Authentication APIs (built-in Supabase Auth)**
- POST `/auth/v1/signup` – Create a new user.
- POST `/auth/v1/token` – Login and receive JWT.
- POST `/auth/v1/logout` – End session.

**Supabase Table Endpoints** (auto-generated)
- GET `/rest/v1/profiles` – List or filter user profiles.
- GET `/rest/v1/classes` – List or filter classes.
- GET `/rest/v1/attendance` – Fetch attendance records.
- POST `/rest/v1/attendance` – (Admins) create attendance manually.
- GET `/rest/v1/points_transactions` – View points history.
- GET `/rest/v1/merchandise` – Browse items.
- POST `/rest/v1/orders` – Place a redemption order.
- GET `/rest/v1/notifications` – Pull user notifications.

**Custom Edge Function Endpoints**
- POST `/functions/v1/record-attendance` – Validate NFC UID, record attendance, award points.
- POST `/functions/v1/calculate-leaderboard` – Compute and return class or overall leaderboards.
- POST `/functions/v1/process-redemption` – Atomically deduct points and create order items.
- POST `/functions/v1/check-achievements` – Evaluate and issue new achievements after transactions.

Each function checks JWT, enforces RLS, and returns clear success/error responses.

## 5. Hosting Solutions

- **Database & Auth** are hosted by Supabase on managed PostgreSQL clusters (AWS/Google Cloud under the hood).
- **Edge Functions** deploy globally on Deno Deploy (provided by Supabase), ensuring low-latency access worldwide.
- **Backups & Maintenance** are handled automatically by Supabase (daily snapshots).

**Benefits**
- **Reliability**: 99.9% uptime SLA on database and functions.
- **Scalability**: Auto-scales with traffic, no server management.
- **Cost-Effectiveness**: Pay-as-you-go pricing, minimal ops overhead.

## 6. Infrastructure Components

- **Load Balancer**: Supabase’s internal load balancing distributes database and function calls.
- **CDN**: Static assets (images, icons) served via a CDN (e.g., Supabase Storage + edge cache).
- **Caching**: HTTP caching headers on static resources and query caching for frequent read endpoints.
- **Realtime Server**: Supabase Realtime uses WebSockets to broadcast database changes to subscribed clients.
- **Environment Configuration**: All secrets (DB URL, anon key, service role key) live in Supabase settings.

Together, these components ensure fast response times, high availability, and an interactive user experience.

## 7. Security Measures

- **Authentication**: Supabase Auth issues JWTs; refresh tokens handled securely.
- **Authorization**: Row Level Security (RLS) policies on every table. Only allowed roles can read/write each table.
- **Data Encryption**: TLS for data in transit; AES-256 at rest (managed by Supabase).
- **Environment Variables**: Sensitive keys never in code; stored in Supabase env settings.
- **Rate Limiting & Throttling**: Built into Supabase endpoint tiers; additional limits can be configured on Edge Functions.
- **Audit Logging**: Supabase logs admin actions, function invocations, and SQL queries.
- **Compliance**: GDPR-ready infrastructure; data residency options available.

## 8. Monitoring and Maintenance

- **Monitoring Tools**: Supabase console provides metrics on query performance, function latency, and error rates.
- **Alerts**: Configure email/slack alerts on high error rates or latency spikes.
- **Logging**: Edge Function logs accessible in the Supabase dashboard; integrate with external log aggregators if needed.
- **Backups & Rollbacks**: Daily backups; point-in-time restores via Supabase UI.
- **Migrations**: Use supabase CLI for versioned schema migrations stored in Git.
- **Regular Audits**: Quarterly review of RLS policies, dependency updates, and security scans.

## 9. Conclusion and Overall Backend Summary

This backend leverages Supabase’s managed services to deliver a **scalable**, **secure**, and **cost-efficient** foundation for NFC attendance and gamification. Key highlights:

- A **modern serverless architecture** with Edge Functions for business logic.
- A **relational database** with RLS, ensuring data privacy across three user roles.
- **Real-time updates** for live leaderboards and attendance dashboards.
- **Comprehensive security**: JWT auth, RLS, encryption, and audit logging.
- **Automated maintenance**: Backups, monitoring, and migrations handled by Supabase.

This setup aligns with the project goals—robust attendance tracking, engaging gamification, and clear role separation—while minimizing operational overhead. Future features can be added by extending the schema and Edge Functions, maintaining the same patterns for consistency and reliability.