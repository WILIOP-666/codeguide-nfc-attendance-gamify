import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_attendance_gamify/core/config/supabase_config.dart';
import 'package:nfc_attendance_gamify/core/constants/app_constants.dart';
import 'package:nfc_attendance_gamify/data/models/auth_state.dart';
import 'package:nfc_attendance_gamify/data/models/user_profile.dart';
import 'package:nfc_attendance_gamify/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true);

    // Listen to auth state changes
    _authSubscription = SupabaseConfig.auth.onAuthStateChange.listen(
      (data) async {
        final User? user = data.session?.user;
        if (user != null) {
          await _fetchUserProfile(user.id);
        } else {
          state = const AuthState(isAuthenticated: false);
        }
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.toString(),
        );
      },
    );

    // Check initial session
    final session = SupabaseConfig.auth.currentSession;
    if (session?.user != null) {
      await _fetchUserProfile(session!.user.id);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      final profile = await _repository.getUserProfile(userId);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userProfile: profile,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.signIn(email: email, password: password);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
    required String program,
    required int batch,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        studentId: studentId,
        program: program,
        batch: batch,
        role: role,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.resetPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _repository.updateProfile(profile);
      state = state.copyWith(userProfile: profile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// Providers
final authRepositoryProvider = Provider((ref) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

final authStateProvider = Provider((ref) {
  return ref.watch(authProvider);
});

final isSignedInProvider = Provider((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider((ref) {
  return ref.watch(authProvider).userProfile;
});

final userRoleProvider = Provider((ref) {
  return ref.watch(authProvider).userProfile?.role;
});