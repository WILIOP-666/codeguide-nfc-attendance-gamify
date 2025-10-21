import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nfc_attendance_gamify/core/config/supabase_config.dart';
import 'package:nfc_attendance_gamify/data/models/attendance_record.dart';
import 'package:nfc_attendance_gamify/data/models/user_profile.dart';

class AttendanceRepository {
  Future<List<AttendanceRecord>> getAttendanceByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await SupabaseConfig.client
          .from('attendance')
          .select()
          .gte('check_in_time', startOfDay.toIso8601String())
          .lt('check_in_time', endOfDay.toIso8601String())
          .order('check_in_time', ascending: false);

      return (response as List).map((json) => AttendanceRecord.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch attendance records: $e');
    }
  }

  Future<List<AttendanceRecord>> getAttendanceByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final response = await SupabaseConfig.client
          .from('attendance')
          .select()
          .gte('check_in_time', startDate.toIso8601String())
          .lte('check_in_time', endDate.toIso8601String())
          .order('check_in_time', ascending: false);

      return (response as List).map((json) => AttendanceRecord.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch attendance records: $e');
    }
  }

  Future<UserProfile?> getStudentByNfcCard(String nfcUid) async {
    try {
      // First, find the NFC card
      final nfcCardResponse = await SupabaseConfig.client
          .from('nfc_cards')
          .select('user_id')
          .eq('uid', nfcUid)
          .eq('is_active', true)
          .maybeSingle();

      if (nfcCardResponse == null) {
        return null;
      }

      // Then, get the user profile
      final profileResponse = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', nfcCardResponse['user_id'])
          .single();

      return UserProfile.fromJson(profileResponse);
    } catch (e) {
      throw Exception('Failed to find student by NFC card: $e');
    }
  }

  Future<List<UserProfile>> searchStudents(String query) async {
    try {
      final response = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('role', 'student')
          .or('full_name.ilike.%$query%,student_id.ilike.%$query%,email.ilike.%$query%')
          .limit(10);

      return (response as List).map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search students: $e');
    }
  }

  Future<List<UserProfile>> getRecentStudents() async {
    try {
      final response = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('role', 'student')
          .order('updated_at', ascending: false)
          .limit(10);

      return (response as List).map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recent students: $e');
    }
  }

  Future<AttendanceRecord?> getTodayAttendanceForStudent(String studentId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await SupabaseConfig.client
          .from('attendance')
          .select()
          .eq('user_id', studentId)
          .gte('check_in_time', startOfDay.toIso8601String())
          .lt('check_in_time', endOfDay.toIso8601String())
          .maybeSingle();

      return response != null ? AttendanceRecord.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch today\'s attendance: $e');
    }
  }

  Future<List<AttendanceRecord>> getAttendanceHistoryForStudent(
      String studentId, {
        int limit = 20,
        int offset = 0,
      }) async {
    try {
      final response = await SupabaseConfig.client
          .from('attendance')
          .select()
          .eq('user_id', studentId)
          .order('check_in_time', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => AttendanceRecord.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch attendance history: $e');
    }
  }

  Future<int> getAttendanceCountForClass(String classId) async {
    try {
      final response = await SupabaseConfig.client
          .from('attendance')
          .select('id')
          .eq('class_id', classId);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to fetch attendance count: $e');
    }
  }

  Future<Map<String, dynamic>> getAttendanceStats(DateTime startDate, DateTime endDate) async {
    try {
      final response = await SupabaseConfig.client
          .from('attendance')
          .select('check_in_time, points_earned, user_id')
          .gte('check_in_time', startDate.toIso8601String())
          .lte('check_in_time', endDate.toIso8601String());

      final List<Map<String, dynamic>> records = List.from(response);
      final totalCheckIns = records.length;
      final totalPoints = records.fold<int>(0, (sum, record) => sum + (record['points_earned'] ?? 0));
      final uniqueStudents = records.map((r) => r['user_id']).toSet().length;

      return {
        'totalCheckIns': totalCheckIns,
        'totalPoints': totalPoints,
        'uniqueStudents': uniqueStudents,
        'averagePointsPerCheckIn': totalCheckIns > 0 ? (totalPoints / totalCheckIns).round() : 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch attendance stats: $e');
    }
  }

  Future<void> createAttendanceRecord(AttendanceRecord record) async {
    try {
      await SupabaseConfig.client.from('attendance').insert(record.toJson());
    } catch (e) {
      throw Exception('Failed to create attendance record: $e');
    }
  }

  Future<void> updateAttendanceRecord(AttendanceRecord record) async {
    try {
      await SupabaseConfig.client
          .from('attendance')
          .update(record.toJson())
          .eq('id', record.id);
    } catch (e) {
      throw Exception('Failed to update attendance record: $e');
    }
  }

  Future<void> deleteAttendanceRecord(String recordId) async {
    try {
      await SupabaseConfig.client
          .from('attendance')
          .delete()
          .eq('id', recordId);
    } catch (e) {
      throw Exception('Failed to delete attendance record: $e');
    }
  }

  // Real-time subscription to attendance changes
  Stream<List<AttendanceRecord>> getAttendanceStream() {
    return SupabaseConfig.client
        .from('attendance')
        .stream(primaryKey: ['id'])
        .order('check_in_time', ascending: false)
        .map((data) => data.map((json) => AttendanceRecord.fromJson(json)).toList());
  }

  // Real-time subscription for specific student attendance
  Stream<List<AttendanceRecord>> getStudentAttendanceStream(String studentId) {
    return SupabaseConfig.client
        .from('attendance')
        .stream(primaryKey: ['id'])
        .eq('user_id', studentId)
        .order('check_in_time', ascending: false)
        .map((data) => data.map((json) => AttendanceRecord.fromJson(json)).toList());
  }
}