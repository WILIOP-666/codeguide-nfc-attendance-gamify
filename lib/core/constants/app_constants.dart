class AppConstants {
  // App Info
  static const String appName = 'NFC Attendance Gamify';
  static const String appVersion = '1.0.0';

  // Points System
  static const int defaultPointsPerClass = 10;
  static const int streakBonusMultiplier = 2;
  static const int perfectAttendanceBonus = 50;

  // User Roles
  static const String roleStudent = 'student';
  static const String roleAdmin = 'admin';
  static const String roleOwner = 'owner';

  // NFC
  static const int nfcTimeoutSeconds = 30;
  static const String nfcErrorDialogTitle = 'NFC Error';

  // API Timeouts
  static const int apiTimeoutSeconds = 30;
  static const int realtimeRetryAttempts = 3;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Duration
  static const Duration profileCacheDuration = Duration(minutes: 5);
  static const Duration leaderboardCacheDuration = Duration(minutes: 2);
  static const Duration merchandiseCacheDuration = Duration(hours: 1);
}