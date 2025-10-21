import 'dart:io';
import 'package:nfc_attendance_gamify/core/config/supabase_config.dart';
import 'package:nfc_attendance_gamify/core/constants/app_constants.dart';
import 'package:nfc_attendance_gamify/data/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed. Please check your credentials.');
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in.');
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
    try {
      // Create auth user
      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'student_id': studentId,
          'role': role,
        },
      );

      if (response.user == null) {
        throw Exception('Registration failed. Please try again.');
      }

      // Create user profile
      final userProfile = UserProfile(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        role: role,
        studentId: studentId,
        program: program,
        batch: batch,
        totalPoints: 0,
        currentLevel: 1,
        attendanceStreak: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEmailVerified: false,
        isProfileComplete: true,
      );

      await SupabaseConfig.client.from('profiles').insert(userProfile.toJson());

    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseConfig.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out.');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await SupabaseConfig.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to send password reset email.');
    }
  }

  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch user profile.');
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      await SupabaseConfig.client
          .from('profiles')
          .update(profile.copyWith(updatedAt: DateTime.now()).toJson())
          .eq('id', profile.id);
    } catch (e) {
      throw Exception('Failed to update profile.');
    }
  }

  Future<bool> isEmailVerified() async {
    final user = SupabaseConfig.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  Future<void> resendEmailVerification() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user != null) {
      await SupabaseConfig.auth.resend(type: OtpType.signup, email: user.email!);
    }
  }
}