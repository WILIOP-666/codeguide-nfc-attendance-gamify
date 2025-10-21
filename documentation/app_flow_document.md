# App Flow Document

## Onboarding and Sign-In/Sign-Up
A new user arrives at the application either by navigating to the web landing page or by opening the mobile app downloaded from the App Store or Google Play. The landing page greets the visitor with an overview of the app’s key benefits and includes clear buttons for signing up or signing in. When the user taps Sign Up, they are taken to a registration form where they can enter their email address and choose a secure password. The form also offers an option to sign up through a third-party provider such as Google, using OAuth to simplify the process. After entering their details and accepting the terms of service, the user clicks Create Account. A verification email is sent to the provided address, and the user is guided to check their inbox to confirm their email. Once confirmed, the user’s credentials are saved in Supabase Auth, and the app fetches the user’s profile and assigned role.

If the user already has an account, they tap Sign In and enter their email and password. The app validates the credentials with Supabase Auth, then retrieves the custom claim that indicates the user’s role: Student, Admin, or Owner. If the user forgets their password, they tap the Forgot Password link, enter their email, and receive a password reset link. Clicking that link opens a secure password reset screen where they choose a new password. After resetting, they return to the sign-in form, enter credentials, and proceed into the application.

Signing out is available from every dashboard header. When the user taps the Log Out button, the app clears their authentication tokens, returns to the landing page, and resets any in-memory state.

## Main Dashboard or Home Page
Upon successful login, the app inspects the user’s role and directs them to their role-specific dashboard. If the user is a Student, they land on the Student Home Page. This page features a header showing the student’s current points balance and latest achievement badge. Below the header, a list of upcoming classes and a quick link to their attendance history appear. A bottom navigation bar lets the student switch between Home, Achievements, Leaderboard, and Shop.

If the user is an Admin, they land on the Admin Dashboard. The header displays the admin’s name, a notification bell, and the current academic term. A sidebar on larger screens (or a slide-out drawer on mobile) houses menu entries for Live NFC Check-In, Attendance Logs, Class Management, and Merchandise Orders. The main area shows a snapshot of today’s check-in count and pending order requests.

If the user is an Owner, they arrive at the Owner Analytics Page. They see interactive charts summarizing total active users, cumulative points awarded, and monthly attendance trends. A top navigation menu offers switches between Overview, Leaderboard Analytics, Financial Summary, and System Health. The Owner can drill down into any chart to open a detailed data table view where they can filter by class or department.

From any dashboard, the user can use the navigation components—tabs on mobile, sidebar on desktop, or top menu—to move seamlessly to other parts of the app according to their role.

## Detailed Feature Flows and Page Transitions
When an Admin wants to take attendance using NFC, they tap Live NFC Check-In. This opens a screen that requests permission to use the device’s NFC hardware. Once granted, the screen displays “Ready to Scan.” The Admin holds a student’s MIFARE Classic card near the device. The flutter_nfc_kit package reads the UID and automatically calls the Supabase Edge Function named record-attendance. The function checks the Admin’s permissions, looks up the student linked to that UID, writes an attendance record to the database, creates a points transaction for the student, and returns a success response. The app then shows a brief confirmation toast with the student’s name and the points awarded.

If the Admin taps Attendance Logs, they see a paginated table showing past check-ins, sortable by date, student name, or class. Tapping a table row opens a detail view of that record, including timestamp and Admin who recorded it. From this view, the Admin can correct an entry by tapping Edit, changing the date or class, and saving. Changes propagate back to the database via another Edge Function.

In the Merchandise Orders section, the Admin sees pending requests as a list. Tapping one request opens order details, including student name, requested items, and point cost. The Admin can approve or reject the order. Approving triggers an Edge Function that deducts the points from the student account, marks the order as completed, and sends a notification. Rejecting returns the points and informs the student.

Students viewing the Shop page see a catalog of merchandise with point prices. They tap an item to open the Item Detail screen, where they read a description and tap Redeem. The app checks if they have enough points, then calls the process-redemption Edge Function. On success, the student sees a confirmation screen and receives a push notification confirming the order was placed. Their points balance updates immediately across the UI thanks to Supabase Realtime.

On the Student’s Achievements page, they scroll through badges they have unlocked. Tapping a badge shows the criteria and date achieved. The Leaderboard page displays a filtered list of top point earners. Students can switch filters by major or class year and see real-time updates as others earn points.

Owners in the Financial Summary area view revenue analytics for points redemptions if a paid merchandise system is integrated. Tapping a chart segment drills down to an order table, where they can export CSV data. In System Health, owners see uptime metrics and recent error logs pulled from the backend.

## Settings and Account Management
From any dashboard header, users tap their profile avatar to open the Profile and Settings screen. Here they can update their display name, email address, and profile photo. Changing the email triggers a verification flow similar to signup. Below personal info, users toggle notification preferences for attendance confirmations, achievement unlocks, and order updates.

A dedicated Security tab allows users to change their password by entering their current password and choosing a new one. Admins and Owners can also manage two-factor authentication settings if enabled. For Owners only, a Billing section appears where they can view subscription status, payment history, and update payment methods if the app uses a paid tier.

After saving any settings, the user taps Save Changes. The app calls the appropriate Supabase API to update the user’s record. Upon success, a banner confirms “Your settings have been updated.” The user then taps Back or the app automatically returns them to the main dashboard.

## Error States and Alternate Paths
If a user enters invalid credentials during sign-in, the app displays a clear error message such as “Email or password is incorrect” beneath the form. During registration, if the email is already in use, the form highlights the email field in red with the message “This email is already registered.”

On the Live NFC Check-In screen, if the device fails to read the card UID, the screen shows “Unable to read card. Please try again” and offers a Retry button. If the network connection drops while the app is calling an Edge Function, the app displays a banner stating “Network error. Retrying…” and automatically retries once connectivity returns. If the retry fails, the user sees “Operation failed. Please check your connection and try again.”

When a user attempts to redeem an item without sufficient points, the Redeem button becomes disabled and a tooltip reads “Not enough points to redeem this item.” If an Admin tries to access Owner-only pages, the app immediately redirects them back to the Admin Dashboard and shows a brief alert indicating insufficient permissions.

If any Supabase Edge Function returns an unexpected error or the system is under maintenance, all users see a maintenance page with a friendly illustration and the message “Service is temporarily unavailable. Please try again later.” The page includes a Retry button that periodically checks if the service is back online.

## Conclusion and Overall App Journey
From the moment a visitor opens the app’s landing page, they are guided through a clear sign-up or sign-in flow. Once authenticated, the user’s role—Student, Admin, or Owner—drives them to a tailored dashboard. Students check their attendance history, track points, unlock achievements, and redeem merchandise. Admins use NFC to record attendance, manage logs, and process orders. Owners monitor real-time analytics, manage system health, and oversee financial metrics. Throughout every interaction, the app handles errors gracefully, keeps data secure with Supabase Auth and Row Level Security, and updates the interface instantly using Supabase Realtime. In day-to-day use, a student will tap their card to check in, watch their points grow on their home page, unlock badges, and spend points in the shop. Admins ensure classes are recorded accurately and orders fulfilled. Owners keep a bird’s-eye view on overall engagement, helping the institution stay on top of attendance and gamification success.