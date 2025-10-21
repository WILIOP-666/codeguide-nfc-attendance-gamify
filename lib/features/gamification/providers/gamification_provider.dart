import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_attendance_gamify/core/config/supabase_config.dart';
import 'package:nfc_attendance_gamify/core/constants/app_constants.dart';
import 'package:nfc_attendance_gamify/data/models/gamification.dart';
import 'package:nfc_attendance_gamify/data/models/user_profile.dart';
import 'package:nfc_attendance_gamify/data/repositories/gamification_repository.dart';

class GamificationState {
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final List<PointsTransaction> transactions;
  final List<UserAchievement> achievements;
  final List<LeaderboardEntry> leaderboard;
  final List<LeaderboardEntry> batchLeaderboard;
  final List<LeaderboardEntry> programLeaderboard;
  final List<Event> upcomingEvents;
  final List<Merchandise> availableMerchandise;
  final List<MerchandiseOrder> userOrders;
  final List<Notification> notifications;
  final int unreadNotificationsCount;
  final Map<String, dynamic> userStats;

  const GamificationState({
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.transactions = const [],
    this.achievements = const [],
    this.leaderboard = const [],
    this.batchLeaderboard = const [],
    this.programLeaderboard = const [],
    this.upcomingEvents = const [],
    this.availableMerchandise = const [],
    this.userOrders = const [],
    this.notifications = const [],
    this.unreadNotificationsCount = 0,
    this.userStats = const {},
  });

  GamificationState copyWith({
    bool? isLoading,
    bool? isProcessing,
    String? error,
    List<PointsTransaction>? transactions,
    List<UserAchievement>? achievements,
    List<LeaderboardEntry>? leaderboard,
    List<LeaderboardEntry>? batchLeaderboard,
    List<LeaderboardEntry>? programLeaderboard,
    List<Event>? upcomingEvents,
    List<Merchandise>? availableMerchandise,
    List<MerchandiseOrder>? userOrders,
    List<Notification>? notifications,
    int? unreadNotificationsCount,
    Map<String, dynamic>? userStats,
  }) {
    return GamificationState(
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      transactions: transactions ?? this.transactions,
      achievements: achievements ?? this.achievements,
      leaderboard: leaderboard ?? this.leaderboard,
      batchLeaderboard: batchLeaderboard ?? this.batchLeaderboard,
      programLeaderboard: programLeaderboard ?? this.programLeaderboard,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      availableMerchandise: availableMerchandise ?? this.availableMerchandise,
      userOrders: userOrders ?? this.userOrders,
      notifications: notifications ?? this.notifications,
      unreadNotificationsCount: unreadNotificationsCount ?? this.unreadNotificationsCount,
      userStats: userStats ?? this.userStats,
    );
  }
}

class GamificationNotifier extends StateNotifier<GamificationState> {
  final GamificationRepository _repository;

  GamificationNotifier(this._repository) : super(const GamificationState());

  Future<void> loadUserGamificationData(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.wait([
        loadPointsTransactions(userId),
        loadUserAchievements(userId),
        loadUserStats(userId),
        loadUserNotifications(userId),
      ]);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadPointsTransactions(String userId, {int limit = 50}) async {
    try {
      final transactions = await _repository.getPointsTransactions(userId, limit: limit);
      state = state.copyWith(transactions: transactions, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadUserAchievements(String userId) async {
    try {
      final achievements = await _repository.getUserAchievements(userId);
      state = state.copyWith(achievements: achievements);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadLeaderboard({String? filter}) async {
    try {
      final leaderboard = await _repository.getLeaderboard(filter: filter);
      state = state.copyWith(leaderboard: leaderboard);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadFilteredLeaderboards(String program, int batch) async {
    try {
      final batchLeaderboard = await _repository.getLeaderboard(filter: 'batch', batch: batch);
      final programLeaderboard = await _repository.getLeaderboard(filter: 'program', program: program);

      state = state.copyWith(
        batchLeaderboard: batchLeaderboard,
        programLeaderboard: programLeaderboard,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadUpcomingEvents() async {
    try {
      final events = await _repository.getUpcomingEvents();
      state = state.copyWith(upcomingEvents: events);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadAvailableMerchandise() async {
    try {
      final merchandise = await _repository.getAvailableMerchandise();
      state = state.copyWith(availableMerchandise: merchandise);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadUserOrders(String userId) async {
    try {
      final orders = await _repository.getUserOrders(userId);
      state = state.copyWith(userOrders: orders);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadUserNotifications(String userId) async {
    try {
      final notifications = await _repository.getUserNotifications(userId);
      final unreadCount = notifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: notifications,
        unreadNotificationsCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadUserStats(String userId) async {
    try {
      final stats = await _repository.getUserStats(userId);
      state = state.copyWith(userStats: stats);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _repository.markNotificationAsRead(notificationId);

      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadNotificationsCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await _repository.markAllNotificationsAsRead(userId);

      final updatedNotifications = state.notifications.map((n) => n.copyWith(isRead: true)).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadNotificationsCount: 0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> redeemMerchandise(String userId, String merchandiseId) async {
    state = state.copyWith(isProcessing: true, error: null);

    try {
      // Call Supabase Edge Function for redemption
      final response = await SupabaseConfig.client.functions.invoke(
        'process-redemption',
        body: {
          'user_id': userId,
          'merchandise_id': merchandiseId,
        },
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Failed to process redemption');
      }

      // Refresh user data
      await Future.wait([
        loadUserOrders(userId),
        loadUserStats(userId),
        loadPointsTransactions(userId, limit: 10),
      ]);

      state = state.copyWith(isProcessing: false);

    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> checkInEvent(String userId, String eventId, {String checkInMethod = 'manual', String? notes}) async {
    state = state.copyWith(isProcessing: true, error: null);

    try {
      // Call Supabase Edge Function for event check-in
      final response = await SupabaseConfig.client.functions.invoke(
        'record-event-attendance',
        body: {
          'user_id': userId,
          'event_id': eventId,
          'check_in_method': checkInMethod,
          'notes': notes,
        },
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Failed to check in to event');
      }

      // Refresh user data
      await Future.wait([
        loadUserStats(userId),
        loadPointsTransactions(userId, limit: 10),
        loadUserAchievements(userId),
        loadUpcomingEvents(),
      ]);

      state = state.copyWith(isProcessing: false);

    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> refreshUserData(String userId) async {
    await loadUserGamificationData(userId);
    await loadLeaderboard();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Calculate user level based on points
  int calculateUserLevel(int totalPoints) {
    if (totalPoints >= 3000) return 6; // Diamond
    if (totalPoints >= 1500) return 5; // Platinum
    if (totalPoints >= 700) return 4; // Gold
    if (totalPoints >= 300) return 3; // Silver
    if (totalPoints >= 100) return 2; // Bronze
    return 1; // Beginner
  }

  // Calculate points to next level
  int calculatePointsToNextLevel(int currentLevel, int totalPoints) {
    switch (currentLevel) {
      case 1: return 100 - totalPoints; // Beginner to Bronze
      case 2: return 300 - totalPoints; // Bronze to Silver
      case 3: return 700 - totalPoints; // Silver to Gold
      case 4: return 1500 - totalPoints; // Gold to Platinum
      case 5: return 3000 - totalPoints; // Platinum to Diamond
      case 6: return 0; // Diamond is max level
      default: return 0;
    }
  }

  // Get level progress percentage
  double getLevelProgress(int currentLevel, int totalPoints) {
    final pointsToNextLevel = calculatePointsToNextLevel(currentLevel, totalPoints);
    final pointsAtCurrentLevel = _getPointsAtCurrentLevel(currentLevel);
    final pointsNeededForNextLevel = _getPointsNeededForNextLevel(currentLevel);

    if (pointsNeededForNextLevel == 0) return 1.0;

    final currentProgress = totalPoints - pointsAtCurrentLevel;
    final totalNeeded = pointsNeededForNextLevel - pointsAtCurrentLevel;

    return (currentProgress / totalNeeded).clamp(0.0, 1.0);
  }

  int _getPointsAtCurrentLevel(int level) {
    switch (level) {
      case 1: return 0;
      case 2: return 100;
      case 3: return 300;
      case 4: return 700;
      case 5: return 1500;
      case 6: return 3000;
      default: return 0;
    }
  }

  int _getPointsNeededForNextLevel(int level) {
    switch (level) {
      case 1: return 100;
      case 2: return 300;
      case 3: return 700;
      case 4: return 1500;
      case 5: return 3000;
      case 6: return 3000; // Max level
      default: return 100;
    }
  }
}

// Providers
final gamificationRepositoryProvider = Provider((ref) => GamificationRepository());

final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  return GamificationNotifier(ref.read(gamificationRepositoryProvider));
});

final gamificationStateProvider = Provider((ref) {
  return ref.watch(gamificationProvider);
});

final transactionsProvider = Provider((ref) {
  return ref.watch(gamificationProvider).transactions;
});

final achievementsProvider = Provider((ref) {
  return ref.watch(gamificationProvider).achievements;
});

final leaderboardProvider = Provider((ref) {
  return ref.watch(gamificationProvider).leaderboard;
});

final upcomingEventsProvider = Provider((ref) {
  return ref.watch(gamificationProvider).upcomingEvents;
});

final availableMerchandiseProvider = Provider((ref) {
  return ref.watch(gamificationProvider).availableMerchandise;
});

final userOrdersProvider = Provider((ref) {
  return ref.watch(gamificationProvider).userOrders;
});

final notificationsProvider = Provider((ref) {
  return ref.watch(gamificationProvider).notifications;
});

final unreadNotificationsCountProvider = Provider((ref) {
  return ref.watch(gamificationProvider).unreadNotificationsCount;
});

final userStatsProvider = Provider((ref) {
  return ref.watch(gamificationProvider).userStats;
});