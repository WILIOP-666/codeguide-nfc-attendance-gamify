import 'package:freezed_annotation/freezed_annotation.dart';

part 'nfc_card.freezed.dart';
part 'nfc_card.g.dart';

@freezed
class NfcCard with _$NfcCard {
  const factory NfcCard({
    required String id,
    required String uid,
    required String userId,
    required String cardType,
    required bool isActive,
    required DateTime registeredAt,
    required DateTime lastUsed,
    @Default(0) int usageCount,
    String? notes,
    String? registeredBy,
  }) = _NfcCard;

  factory NfcCard.fromJson(Map<String, dynamic> json) =>
      _$NfcCardFromJson(json);
}

@freezed
class NfcScanResult with _$NfcScanResult {
  const factory NfcScanResult({
    required String uid,
    required String type,
    required String? technology,
    Map<String, dynamic>? additionalData,
    required DateTime scannedAt,
    @Default(false) bool isValid,
    String? errorMessage,
  }) = _NfcScanResult;
}

@freezed
class AttendanceCheckIn with _$AttendanceCheckIn {
  const factory AttendanceCheckIn({
    required String nfcCardId,
    required String classId,
    required String adminId,
    required DateTime checkInTime,
    @Default(false) bool isManualCheckIn,
    String? studentName,
    String? studentId,
    String? notes,
  }) = _AttendanceCheckIn;
}