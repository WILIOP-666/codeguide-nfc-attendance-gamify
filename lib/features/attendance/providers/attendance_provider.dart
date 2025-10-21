import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_attendance_gamify/core/constants/app_constants.dart';
import 'package:nfc_attendance_gamify/core/config/supabase_config.dart';
import 'package:nfc_attendance_gamify/data/models/attendance_record.dart';
import 'package:nfc_attendance_gamify/data/models/nfc_card.dart';
import 'package:nfc_attendance_gamify/data/models/user_profile.dart';
import 'package:nfc_attendance_gamify/data/repositories/attendance_repository.dart';

class AttendanceState {
  final bool isLoading;
  final bool isRecording;
  final String? error;
  final List<AttendanceRecord> todayAttendance;
  final List<AttendanceRecord> weeklyAttendance;
  final int todayCheckIns;
  final int weeklyCheckIns;
  final List<UserProfile> recentStudents;

  const AttendanceState({
    this.isLoading = false,
    this.isRecording = false,
    this.error,
    this.todayAttendance = const [],
    this.weeklyAttendance = const [],
    this.todayCheckIns = 0,
    this.weeklyCheckIns = 0,
    this.recentStudents = const [],
  });

  AttendanceState copyWith({
    bool? isLoading,
    bool? isRecording,
    String? error,
    List<AttendanceRecord>? todayAttendance,
    List<AttendanceRecord>? weeklyAttendance,
    int? todayCheckIns,
    int? weeklyCheckIns,
    List<UserProfile>? recentStudents,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      error: error ?? this.error,
      todayAttendance: todayAttendance ?? this.todayAttendance,
      weeklyAttendance: weeklyAttendance ?? this.weeklyAttendance,
      todayCheckIns: todayCheckIns ?? this.todayCheckIns,
      weeklyCheckIns: weeklyCheckIns ?? this.weeklyCheckIns,
      recentStudents: recentStudents ?? this.recentStudents,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AttendanceRepository _repository;

  AttendanceNotifier(this._repository) : super(const AttendanceState()) {
    _initializeAttendanceData();
  }

  Future<void> _initializeAttendanceData() async {
    await loadTodayAttendance();
    await loadWeeklyAttendance();
  }

  Future<void> loadTodayAttendance() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final today = DateTime.now();
      final attendance = await _repository.getAttendanceByDate(today);
      final checkIns = attendance.where((a) => a.checkInMethod == 'nfc' || a.checkInMethod == 'manual').length;

      state = state.copyWith(
        isLoading: false,
        todayAttendance: attendance,
        todayCheckIns: checkIns,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadWeeklyAttendance() async {
    state = state.copyWith(isLoading: true);

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final attendance = await _repository.getAttendanceByDateRange(weekStart, weekEnd);
      final checkIns = attendance.where((a) => a.checkInMethod == 'nfc' || a.checkInMethod == 'manual').length;

      state = state.copyWith(
        isLoading: false,
        weeklyAttendance: attendance,
        weeklyCheckIns: checkIns,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> recordNfcCheckIn({
    required String nfcUid,
    required String cardType,
    String? classId,
    String? notes,
  }) async {
    state = state.copyWith(isRecording: true, error: null);

    try {
      final currentUser = SupabaseConfig.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Call Supabase Edge Function to record attendance
      final response = await SupabaseConfig.client.functions.invoke(
        'record-attendance',
        body: {
          'nfc_uid': nfcUid,
          'card_type': cardType,
          'admin_id': currentUser.id,
          'class_id': classId,
          'check_in_method': 'nfc',
          'notes': notes,
        },
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Failed to record attendance');
      }

      // Refresh attendance data
      await loadTodayAttendance();

      state = state.copyWith(isRecording: false);

    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> recordManualCheckIn({
    required String studentId,
    required String classId,
    String? notes,
  }) async {
    state = state.copyWith(isRecording: true, error: null);

    try {
      final currentUser = SupabaseConfig.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Call Supabase Edge Function to record manual attendance
      final response = await SupabaseConfig.client.functions.invoke(
        'record-attendance',
        body: {
          'student_id': studentId,
          'class_id': classId,
          'admin_id': currentUser.id,
          'check_in_method': 'manual',
          'notes': notes,
        },
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Failed to record attendance');
      }

      // Refresh attendance data
      await loadTodayAttendance();

      state = state.copyWith(isRecording: false);

    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<UserProfile?> getStudentByNfcCard(String nfcUid) async {
    try {
      return await _repository.getStudentByNfcCard(nfcUid);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<List<UserProfile>> searchStudents(String query) async {
    try {
      return await _repository.searchStudents(query);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<void> loadRecentStudents() async {
    try {
      final students = await _repository.getRecentStudents();
      state = state.copyWith(recentStudents: students);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final attendanceRepositoryProvider = Provider((ref) => AttendanceRepository());

final attendanceProvider = StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier(ref.read(attendanceRepositoryProvider));
});

final attendanceStateProvider = Provider((ref) {
  return ref.watch(attendanceProvider);
});

final todayAttendanceProvider = Provider((ref) {
  return ref.watch(attendanceProvider).todayAttendance;
});

final weeklyAttendanceProvider = Provider((ref) {
  return ref.watch(attendanceProvider).weeklyAttendance;
});

final recentStudentsProvider = Provider((ref) {
  return ref.watch(attendanceProvider).recentStudents;
});