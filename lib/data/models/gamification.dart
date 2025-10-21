import 'package:freezed_annotation/freezed_annotation.dart';

part 'gamification.freezed.dart';
part 'gamification.g.dart';

@freezed
class PointsTransaction with _$PointsTransaction {
  const factory PointsTransaction({
    required String id,
    required String userId,
    required String transactionType, // 'attendance', 'event', 'redemption', 'bonus', 'penalty'
    required int points,
    required String description,
    String? referenceId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    String? metadata,
  }) = _PointsTransaction;

  factory PointsTransaction.fromJson(Map<String, dynamic> json) =>
      _$PointsTransactionFromJson(json);
}

@freezed
class Achievement with _$Achievement {
  const factory Achievement({
    required String id,
    required String name,
    required String description,
    required String category, // 'attendance', 'points', 'streak', 'event'
    required int threshold,
    required String icon,
    required int pointsReward,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);
}

@freezed
class UserAchievement with _$UserAchievement {
  const factory UserAchievement({
    required String id,
    required String userId,
    required String achievementId,
    required String name,
    required String description,
    required String icon,
    @JsonKey(name: 'earned_at') required DateTime earnedAt,
    @JsonKey(name: 'is_viewed') @Default(false) bool isViewed,
  }) = _UserAchievement;

  factory UserAchievement.fromJson(Map<String, dynamic> json) =>
      _$UserAchievementFromJson(json);
}

@freezed
class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required String userId,
    required String fullName,
    required String studentId,
    required String program,
    required int batch,
    required int totalPoints,
    required int currentLevel,
    required int attendanceStreak,
    required int rank,
    @JsonKey(name: 'profile_image_url') String? profileImageUrl,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _LeaderboardEntry;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);
}

@freezed
class Level with _$Level {
  const factory Level({
    required int level,
    required String name,
    required int minPoints,
    required int maxPoints,
    required String badge,
    required List<String> privileges,
  }) = _Level;

  factory Level.fromJson(Map<String, dynamic> json) =>
      _$LevelFromJson(json);
}

@freezed
class Event with _$Event {
  const factory Event({
    required String id,
    required String title,
    required String description,
    required String type, // 'seminar', 'workshop', 'competition', 'other'
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required int points,
    required String organizerId,
    @JsonKey(name: 'max_participants') int? maxParticipants,
    @JsonKey(name: 'current_participants') @Default(0) int currentParticipants,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'check_in_method') required String checkInMethod, // 'nfc', 'qr', 'manual'
    @JsonKey(name: 'qr_code_data') String? qrCodeData,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    List<String>? tags,
    String? imageUrl,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) =>
      _$EventFromJson(json);
}

@freezed
class EventParticipation with _$EventParticipation {
  const factory EventParticipation({
    required String id,
    required String eventId,
    required String userId,
    required DateTime checkInTime,
    required int pointsEarned,
    required String checkInMethod,
    String? notes,
    @JsonKey(name: 'verified_by') String? verifiedBy,
  }) = _EventParticipation;

  factory EventParticipation.fromJson(Map<String, dynamic> json) =>
      _$EventParticipationFromJson(json);
}

@freezed
class Merchandise with _$Merchandise {
  const factory Merchandise({
    required String id,
    required String name,
    required String description,
    required String category, // 'physical', 'voucher', 'privilege'
    required int pointsCost,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'stock_quantity') int? stockQuantity,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) = _Merchandise;

  factory Merchandise.fromJson(Map<String, dynamic> json) =>
      _$MerchandiseFromJson(json);
}

@freezed
class MerchandiseOrder with _$MerchandiseOrder {
  const factory MerchandiseOrder({
    required String id,
    required String userId,
    required String merchandiseId,
    required int pointsCost,
    required String status, // 'pending', 'approved', 'fulfilled', 'cancelled'
    @JsonKey(name: 'ordered_at') required DateTime orderedAt,
    @JsonKey(name: 'approved_at') DateTime? approvedAt,
    @JsonKey(name: 'fulfilled_at') DateTime? fulfilledAt,
    @JsonKey(name: 'cancelled_at') DateTime? cancelledAt,
    @JsonKey(name: 'processed_by') String? processedBy,
    String? notes,
    Map<String, dynamic>? fulfillmentDetails,
  }) = _MerchandiseOrder;

  factory MerchandiseOrder.fromJson(Map<String, dynamic> json) =>
      _$MerchandiseOrderFromJson(json);
}

@freezed
class Notification with _$Notification {
  const factory Notification({
    required String id,
    required String userId,
    required String title,
    required String message,
    required String type, // 'achievement', 'points', 'order', 'event', 'general'
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);
}