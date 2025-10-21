# Security Guidelines for codeguide-nfc-attendance-gamify

This document defines security best practices and requirements for the Flutter/Supabase NFC Attendance & Gamification application. It aligns with Security by Design, Least Privilege, Defense in Depth, and Secure Defaults principles to ensure a robust, maintainable, and production-ready solution.

## 1. Authentication & Access Control

- **Supabase Auth & Custom Claims**  
  • Enforce strong password policies: minimum 12 characters, mixed case, numbers, symbols.  
  • Enable multi-factor authentication (MFA) for Admin and Owner roles.  
  • Use Supabase custom JWT claims to store user roles (User, Admin, Owner).  
  
- **Session Management**  
  • Use secure, HttpOnly, `SameSite=Strict` cookies where possible.  
  • Configure idle timeouts (e.g., 15 min) and absolute session timeouts (e.g., 24 hours).  
  • Provide explicit logout and revoke refresh tokens on sign-out.  

- **Row-Level Security (RLS)**  
  • Define RLS policies for all tables: only Owners may read system metrics; Admins may insert to `attendance` and manage classes; Users may read only their own profiles, attendance, and point balances.  
  • Test RLS policies with impersonation to validate no over-exposure of data.  

## 2. Input Validation & Processing

- **Edge Function Inputs**  
  • For every Supabase Edge Function (e.g., `record-attendance`, `process-redemption`), validate inputs against a strict schema (Zod or TypeBox).  
  • Reject requests that fail type, range, or format checks; return generic errors without internal details.  

- **NFC UID Handling**  
  • Sanitize and validate the UID format in the Edge Function.  
  • Rate-limit NFC check-in endpoints per Admin device to prevent replay attacks.  

- **Prevent Injection Attacks**  
  • Use Supabase’s parameterized queries; avoid dynamic SQL string concatenation.  
  • Never interpolate user input directly into SQL or JSON without validation.  

## 3. Data Protection & Privacy

- **Encryption In Transit & At Rest**  
  • Enforce HTTPS/TLS 1.2+ for all client–server and Edge Function calls.  
  • Supabase database is encrypted at rest; verify AES-256 encryption configuration.  

- **Secret Management**  
  • Store Supabase URL, anon/public key, and service_role key in secure CI/CD secrets—never in source code or `pubspec.yaml`.  
  • Use Flutter’s secure storage (keychain/keystore) for any temporary tokens.  

- **Data Minimization & Masking**  
  • Return only necessary fields in API responses (e.g., do not return service_role keys).  
  • Mask personal data (e.g., email, names) in logs and error messages.  

## 4. API & Edge Function Security

- **Authentication & Authorization**  
  • Every Edge Function must verify the Supabase JWT and check custom claims.  
  • Implement fine-grained permission checks before performing any database action.  

- **Rate Limiting & Throttling**  
  • Apply rate limits per IP and per user on critical endpoints (e.g., check-in, redemption).  
  • Integrate a server-side rate limiter or middleware in Edge Functions.  

- **Error Handling**  
  • Catch all exceptions; log detailed errors to a private monitoring service (e.g., Sentry) but return only sanitized, user-friendly messages.  
  • Avoid leaking stack traces or internal database errors in responses.  

## 5. Mobile Application Security

- **Secure Network Configuration**  
  • Pin Supabase certificate in Flutter’s `http` client to prevent man-in-the-middle attacks.  
  • Enforce `strictTransportSecurity` and configure CORS on Supabase to allow only the mobile app’s custom scheme.  

- **Storage & Secrets**  
  • Use `flutter_secure_storage` for storing any short-lived tokens; do not use `SharedPreferences` or `localStorage`.  
  • Obfuscate and minify Dart code in release builds to reduce reverse-engineering risk.  

- **NFC Permissions & Lifecycle**  
  • Request NFC permission at runtime with a clear privacy rationale.  
  • Stop NFC reader sessions when the check-in screen is disposed to avoid background scanning.  

- **Client-Side Input Validation**  
  • Validate form inputs (e.g., redemption quantity) before submission, but never rely solely on client checks.  
  • Implement CSRF protection on any webviews (if used) by injecting anti-CSRF tokens.  

## 6. Infrastructure & CI/CD Security

- **CI/CD Pipelines**  
  • Store secrets (Supabase keys, Sentry DSN) in the pipeline’s secret manager.  
  • Integrate static analysis tools: Dart analyzer, SonarQube, or similar for code quality.  
  • Run dependency vulnerability scans (e.g., `pub outdated --mode=null-safety`, Snyk).  

- **Environment Segregation**  
  • Use separate Supabase projects for development, staging, and production.  
  • Enforce stricter RLS policies and MFA in production.  

- **Monitoring & Alerting**  
  • Enable Supabase Audit Logs and forward them to a secure log aggregation service.  
  • Configure alerts for suspicious activities (e.g., repeated failed login attempts, rate limit breaches).  

## 7. Dependency Management

- **Secure Dependencies**  
  • Audit all Flutter packages and Edge Function libraries for known vulnerabilities.  
  • Pin package versions in `pubspec.lock` and `package.json` (for Edge Functions).  

- **Regular Updates**  
  • Schedule monthly dependency review and upgrades.  
  • Test UI and Edge Functions after every dependency update in CI before merging.  

## 8. Testing & Validation

- **Automated Test Suite**  
  • Unit tests for Flutter widgets (e.g., NFC flow error states) and Edge Function logic.  
  • Integration tests for end-to-end flows: sign-in, NFC check-in, points redemption.  

- **Security Testing**  
  • Perform regular penetration tests (targeting API, NFC workflow, RLS bypass).  
  • Use OWASP ZAP or similar tools to scan for injection, XSS (in any webviews), and insecure configurations.  

---
By embedding these controls throughout design, implementation, and deployment, the `codeguide-nfc-attendance-gamify` application will meet high standards of confidentiality, integrity, and availability while providing a secure and seamless user experience.