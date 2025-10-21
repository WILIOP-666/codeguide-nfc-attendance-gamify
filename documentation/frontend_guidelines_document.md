# Frontend Guidelines for NFC Attendance & Gamification App

This document describes how the Flutter-based frontend of the NFC attendance and gamification app is structured, styled, and maintained. It’s written in everyday language so that anyone—regardless of technical background—can follow along.

## 1. Frontend Architecture

Our frontend follows a layered, component-based structure to keep things clear and easy to maintain:

• **Layers and Directories**
  - **data/**: Holds classes that talk to Supabase (authentication, fetching attendance, points, etc.).
  - **state/**: Contains Riverpod providers and state classes that bridge UI and data.
  - **widgets/**: Reusable UI building blocks (stats cards, lists, buttons).
  - **screens/**: Full pages or flows, organized by user role (`/user`, `/admin`, `/owner`).

• **Why it works**
  - **Scalable**: You can add new screens or widgets without touching unrelated code.
  - **Maintainable**: Clear separation means bugs are easier to find and fix.
  - **Performant**: Layers minimize unnecessary rebuilds and network calls.

## 2. Design Principles

We follow three bedrock principles across the app:

• **Usability**: Controls are large enough to tap, flows are clear, and feedback is immediate (snack bars, loading indicators).

• **Accessibility**: We use semantic Flutter widgets, maintain color contrast ratios, and label interactive elements for screen readers.

• **Responsiveness**: Layouts adapt to phones and tablets. We use `Flexible`, `Expanded`, and adaptive text scaling to ensure a consistent look on all screen sizes.

### Applying These Principles

• **Button Sizes & Touch Targets**: Minimum 48×48dp for interactive elements.

• **Screen Reader Support**: `Semantics` widgets wrap complex UI for better narration.

• **Adaptive Layout**: Breakpoints adjust padding, column counts, and font sizes automatically.

## 3. Styling and Theming

We rely on Material Design 3 for a modern, cohesive feel. Here’s how it’s set up:

### Approach and Tools

• **Framework**: Flutter’s built-in Material theming.

• **Pre-Processor**: None—Flutter’s theme system handles colors, fonts, and shapes directly.

### Visual Style

• **Style**: Modern, flat surfaces with subtle elevation and rounded corners (Material 3 “surface” look).

• **Glassmorphism Accents**: On select overlay dialogs, we use semi-transparent cards with backdrop blur for depth.

### Color Palette

| Role      | Light Mode    | Dark Mode     |
|-----------|---------------|---------------|
| Primary   | #6750A4       | #D0BCFF       |
| Secondary | #625B71       | #CCC2DC       |
| Tertiary  | #7D5260       | #EFB8C8       |
| Background| #FEF7FF       | #1E1B1E       |
| Error     | #B3261E       | #F2B8B5       |

### Typography

• **Font Family**: Roboto

• **Weights & Sizes**:
  - Headline1: 96sp
  - Headline2: 60sp
  - Headline3: 48sp
  - Body1: 16sp
  - Button: 14sp, uppercase

## 4. Component Structure

Our component (widget) library lives in `/widgets`:

• **StatCard**: Displays a number and label (points, streaks).

• **LeaderboardListItem**: Shows user photo, name, rank, and points.

• **AchievementBadge**: Circular icon + text for unlocked badges.

• **DataTableList**: Scrollable list with headers, used for attendance logs and orders.

• **ChartWidget**: Wraps `fl_chart` line/bar charts for analytics.

Why this matters:

- **Reuse**: One widget is used in multiple screens (e.g., StatCard appears on User, Admin, Owner dashboards).
- **Maintainability**: Changing a widget in one place updates all instances automatically.

## 5. State Management

We use Riverpod to handle state across the app:

• **Global Providers**: 
  - `authProvider`: Tracks current user’s session and role.
  - `attendanceProvider`: Streams real-time attendance via Supabase Realtime.
  - `leaderboardProvider`: Fetches and updates leaderboard data.

• **Why Riverpod?**
  - **Auto-dispose**: Frees memory when screens go away.
  - **Scoped overrides**: Easy to mock data in tests.
  - **No context needed**: Makes it simple to read/write state from any widget.

## 6. Routing and Navigation

We rely on GoRouter for declarative routing:

• **Routes**:
  - `/login` → Sign-in screen
  - `/user/dashboard` → Student view
  - `/admin/dashboard` → Attendance & order management
  - `/owner/dashboard` → Analytics charts

• **Role-based Redirects**:
  - After login, GoRouter checks `authProvider`. Depending on whether the user is a Student, Admin, or Owner, they’re redirected to their specific dashboard.

• **Nested Navigation**: Tabs and sub-routes are nested under each dashboard route, keeping URLs and navigation stacks predictable.

## 7. Performance Optimization

To keep the app snappy:

• **Const Widgets**: Mark as many widgets as `const` as possible to avoid rebuilds.

• **Deferred Imports**: Heavy screens (e.g., Owner’s full analytics panel) load only when navigated to.

• **Image Caching**: Profile photos and badge icons use `cached_network_image`.

• **Chunked Lists**: Large attendance logs are paginated or virtualized to avoid UI jank.

• **Network Throttling in Dev**: We test with slow connections to ensure graceful loading indicators.

## 8. Testing and Quality Assurance

Our testing pyramid includes:

• **Unit Tests**:
  - Dart `test` for pure logic (e.g., point calculation algorithms, date utilities).
  - Riverpod providers mocked to verify state changes.

• **Widget Tests**:
  - Render widgets in isolation (e.g., StatCard, DataTableList) and verify layout, text, and interaction.

• **Integration Tests**:
  - End-to-end flows using `integration_test`: login → NFC check-in → points awarded → leaderboard update.

• **Tools**:
  - `flutter_test` and `integration_test`
  - `mocktail` for mocking Supabase responses

• **CI Pipeline**:
  - Runs tests on every pull request
  - Lints code with `flutter analyze`
  - Checks formatting with `flutter format --set-exit-if-changed`

## 9. Conclusion and Overall Frontend Summary

This Flutter frontend is built to be clear, consistent, and reliable. By:

- Separating code into data, state, widgets, and screens layers,
- Adopting Material Design 3 with a defined color palette,
- Emphasizing accessibility and responsiveness,
- Relying on Riverpod for state and GoRouter for navigation,
- Optimizing performance with const widgets and lazy loading,
- Backing everything up with robust tests,

we ensure a polished, maintainable, and scalable application. Anyone joining the project can find their way around, add new features, or fix defects without a steep learning curve. This setup aligns directly with our goals: fast development, high quality, and an engaging user experience for Students, Admins, and Owners alike.