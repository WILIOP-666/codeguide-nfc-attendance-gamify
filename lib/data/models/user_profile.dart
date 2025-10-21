import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String email,
    required String fullName,
    required String role,
    required String studentId,
    required String program,
    required int batch,
    required int totalPoints,
    required int currentLevel,
    required int attendanceStreak,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? avatarUrl,
    String? phoneNumber,
    @Default(false) bool isEmailVerified,
    @Default(false) bool isProfileComplete,
    @Default([]) List<String> achievements,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

@freezed
class AttendanceRecord with _$AttendanceRecord {
  const factory AttendanceRecord({
    required String id,
    required String userId,
    required String classId,
    required DateTime checkInTime,
    required int pointsEarned,
    required String checkInMethod,
    @Default(false) bool wasLate,
    String? nfcCardId,
    String? adminId,
    String? notes,
  }) = _AttendanceRecord;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRecordFromJson(json);
}

@freezed
class ClassSession with _$ClassSession {
  const factory ClassSession({
    required String id,
    required String courseName,
    required String courseCode,
    required String lecturerName,
    required DateTime startTime,
    required DateTime endTime,
    required String room,
    required int points,
    @Default(false) bool isActive,
    @Default([]) List<String> attendeeIds,
  }) = _ClassSession;

  factory ClassSession.fromJson(Map<String, dynamic> json) =>
      _$ClassSessionFromJson(json);
}