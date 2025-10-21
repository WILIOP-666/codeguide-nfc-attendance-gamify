import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nfc_attendance_gamify/core/config/supabase_config.dart';
import 'package:nfc_attendance_gamify/data/models/gamification.dart';

class GamificationRepository {
  // Points Transactions
  Future<List<PointsTransaction>> getPointsTransactions(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('points_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => PointsTransaction.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch points transactions: $e');
    }
  }

  Future<PointsTransaction?> getLatestTransaction(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('points_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? PointsTransaction.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch latest transaction: $e');
    }
  }

  // Achievements
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .order('earned_at', ascending: false);

      return (response as List).map((json) => UserAchievement.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user achievements: $e');
    }
  }

  Future<List<Achievement>> getAvailableAchievements() async {
    try {
      final response = await SupabaseConfig.client
          .from('achievements')
          .select()
          .eq('is_active', true)
          .order('category', ascending: true);

      return (response as List).map((json) => Achievement.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch achievements: $e');
    }
  }

  Future<UserAchievement?> getUnreadAchievementsCount(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('user_achievements')
          .select('id')
          .eq('user_id', userId)
          .eq('is_viewed', false);

      return UserAchievement.fromJson({
        'id': 'count',
        'user_id': userId,
        'achievement_id': 'unread_count',
        'name': 'Unread',
        'description': '${(response as List).length} unread achievements',
        'icon': '🏆',
        'earned_at': DateTime.now().toIso8601String(),
        'is_viewed': false,
      });
    } catch (e) {
      throw Exception('Failed to fetch unread achievements: $e');
    }
  }

  Future<void> markAchievementAsViewed(String userId, String achievementId) async {
    try {
      await SupabaseConfig.client
          .from('user_achievements')
          .update({'is_viewed': true})
          .eq('user_id', userId)
          .eq('achievement_id', achievementId);
    } catch (e) {
      throw Exception('Failed to mark achievement as viewed: $e');
    }
  }

  // Leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard({
    String? filter,
    String? program,
    int? batch,
    int limit = 50,
  }) async {
    try {
      var query = SupabaseConfig.client
          .from('profiles')
          .select('id, full_name, student_id, program, batch, total_points, current_level, attendance_streak, updated_at')
          .eq('role', 'student')
          .order('total_points', ascending: false)
          .limit(limit);

      // Apply filters
      if (program != null) {
        query = query.eq('program', program);
      }
      if (batch != null) {
        query = query.eq('batch', batch);
      }

      final response = await query;

      // Add rank to each entry
      final List<LeaderboardEntry> leaderboard = [];
      for (int i = 0; i < response.length; i++) {
        final entry = response[i];
        leaderboard.add(LeaderboardEntry.fromJson({
          ...entry,
          'rank': i + 1,
          'profile_image_url': null,
        }));
      }

      return leaderboard;
    } catch (e) {
      throw Exception('Failed to fetch leaderboard: $e');
    }
  }

  Future<LeaderboardEntry?> getUserLeaderboardPosition(String userId, {String? program, int? batch}) async {
    try {
      var query = SupabaseConfig.client
          .from('profiles')
          .select('id, full_name, student_id, program, batch, total_points, current_level, attendance_streak, updated_at')
          .eq('role', 'student')
          .order('total_points', ascending: false);

      // Apply filters
      if (program != null) {
        query = query.eq('program', program);
      }
      if (batch != null) {
        query = query.eq('batch', batch);
      }

      final response = await query;

      // Find user's position
      for (int i = 0; i < response.length; i++) {
        final entry = response[i];
        if (entry['id'] == userId) {
          return LeaderboardEntry.fromJson({
            ...entry,
            'rank': i + 1,
            'profile_image_url': null,
          });
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch user leaderboard position: $e');
    }
  }

  // Events
  Future<List<Event>> getUpcomingEvents({int limit = 20}) async {
    try {
      final now = DateTime.now();
      final response = await SupabaseConfig.client
          .from('events')
          .select()
          .eq('is_active', true)
          .gte('start_time', now.toIso8601String())
          .order('start_time', ascending: true)
          .limit(limit);

      return (response as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming events: $e');
    }
  }

  Future<List<Event>> getPastEvents({int limit = 20}) async {
    try {
      final now = DateTime.now();
      final response = await SupabaseConfig.client
          .from('events')
          .select()
          .eq('is_active', true)
          .lt('start_time', now.toIso8601String())
          .order('start_time', ascending: false)
          .limit(limit);

      return (response as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch past events: $e');
    }
  }

  Future<List<EventParticipation>> getUserEventParticipation(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('event_participation')
          .select('*, events(*)')
          .eq('user_id', userId)
          .order('check_in_time', ascending: false);

      return (response as List).map((json) => EventParticipation.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user event participation: $e');
    }
  }

  Future<Event?> getEventById(String eventId) async {
    try {
      final response = await SupabaseConfig.client
          .from('events')
          .select()
          .eq('id', eventId)
          .single();

      return Event.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch event: $e');
    }
  }

  // Merchandise
  Future<List<Merchandise>> getAvailableMerchandise({String? category}) async {
    try {
      var query = SupabaseConfig.client
          .from('merchandise')
          .select()
          .eq('is_active', true)
          .order('points_cost', ascending: true);

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query;

      return (response as List).map((json) => Merchandise.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch merchandise: $e');
    }
  }

  Future<Merchandise?> getMerchandiseById(String merchandiseId) async {
    try {
      final response = await SupabaseConfig.client
          .from('merchandise')
          .select()
          .eq('id', merchandiseId)
          .eq('is_active', true)
          .single();

      return Merchandise.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch merchandise: $e');
    }
  }

  Future<List<MerchandiseOrder>> getUserOrders(String userId, {int limit = 50}) async {
    try {
      final response = await SupabaseConfig.client
          .from('merchandise_orders')
          .select('*, merchandise(*)')
          .eq('user_id', userId)
          .order('ordered_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) => MerchandiseOrder.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user orders: $e');
    }
  }

  Future<List<MerchandiseOrder>> getAllOrders({int limit = 100}) async {
    try {
      final response = await SupabaseConfig.client
          .from('merchandise_orders')
          .select('*, merchandise(*), profiles!merchandise_orders_user_id_fkey(full_name, student_id)')
          .order('ordered_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) => MerchandiseOrder.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all orders: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status, {String? processedBy}) async {
    try {
      final updateData = {
        'status': status,
      };

      // Add timestamp based on status
      final now = DateTime.now().toIso8601String();
      switch (status) {
        case 'approved':
          updateData['approved_at'] = now;
          break;
        case 'fulfilled':
          updateData['fulfilled_at'] = now;
          break;
        case 'cancelled':
          updateData['cancelled_at'] = now;
          break;
      }

      if (processedBy != null) {
        updateData['processed_by'] = processedBy;
      }

      await SupabaseConfig.client
          .from('merchandise_orders')
          .update(updateData)
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Notifications
  Future<List<Notification>> getUserNotifications(String userId, {int limit = 50}) async {
    try {
      final response = await SupabaseConfig.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) => Notification.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await SupabaseConfig.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await SupabaseConfig.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to fetch unread notifications count: $e');
    }
  }

  // User Stats
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await SupabaseConfig.client.rpc('calculate_user_stats', params: {
        'p_user_id': userId,
      });

      return Map<String, dynamic>.from(response ?? {});
    } catch (e) {
      // Fallback to manual calculation if RPC doesn't exist
      return await _calculateUserStatsManually(userId);
    }
  }

  Future<Map<String, dynamic>> _calculateUserStatsManually(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Get attendance stats
      final todayAttendance = await SupabaseConfig.client
          .from('attendance')
          .select('id, points_earned')
          .eq('user_id', userId)
          .gte('check_in_time', startOfDay.toIso8601String());

      final weeklyAttendance = await SupabaseConfig.client
          .from('attendance')
          .select('id, points_earned')
          .eq('user_id', userId)
          .gte('check_in_time', startOfWeek.toIso8601String());

      final monthlyAttendance = await SupabaseConfig.client
          .from('attendance')
          .select('id, points_earned')
          .eq('user_id', userId)
          .gte('check_in_time', startOfMonth.toIso8601String());

      // Get event stats
      final eventParticipation = await SupabaseConfig.client
          .from('event_participation')
          .select('id, points_earned')
          .eq('user_id', userId);

      // Get achievement stats
      final achievements = await SupabaseConfig.client
          .from('user_achievements')
          .select('id')
          .eq('user_id', userId);

      final todayPoints = todayAttendance.fold<int>(0, (sum, a) => sum + (a['points_earned'] ?? 0));
      final weeklyPoints = weeklyAttendance.fold<int>(0, (sum, a) => sum + (a['points_earned'] ?? 0));
      final monthlyPoints = monthlyAttendance.fold<int>(0, (sum, a) => sum + (a['points_earned'] ?? 0));
      final eventPoints = eventParticipation.fold<int>(0, (sum, e) => sum + (e['points_earned'] ?? 0));

      return {
        'today_check_ins': todayAttendance.length,
        'weekly_check_ins': weeklyAttendance.length,
        'monthly_check_ins': monthlyAttendance.length,
        'total_events': eventParticipation.length,
        'total_achievements': achievements.length,
        'today_points': todayPoints,
        'weekly_points': weeklyPoints,
        'monthly_points': monthlyPoints,
        'event_points': eventPoints,
      };
    } catch (e) {
      throw Exception('Failed to calculate user stats: $e');
    }
  }

  // Real-time subscriptions
  Stream<List<PointsTransaction>> getTransactionsStream(String userId) {
    return SupabaseConfig.client
        .from('points_transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => PointsTransaction.fromJson(json)).toList());
  }

  Stream<List<Notification>> getNotificationsStream(String userId) {
    return SupabaseConfig.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Notification.fromJson(json)).toList());
  }

  Stream<List<LeaderboardEntry>> getLeaderboardStream({String? program, int? batch}) {
    var query = SupabaseConfig.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('role', 'student')
        .order('total_points', ascending: false);

    if (program != null) {
      query = query.eq('program', program);
    }
    if (batch != null) {
      query = query.eq('batch', batch);
    }

    return query.map((data) {
      final List<LeaderboardEntry> leaderboard = [];
      for (int i = 0; i < data.length; i++) {
        final entry = data[i];
        leaderboard.add(LeaderboardEntry.fromJson({
          ...entry,
          'rank': i + 1,
          'profile_image_url': null,
        }));
      }
      return leaderboard;
    });
  }
}