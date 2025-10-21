import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nfc_attendance_gamify/data/models/user_profile.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isLoading,
    @Default(false) bool isAuthenticated,
    UserProfile? userProfile,
    String? error,
  }) = _AuthState;

  const AuthState._();

  bool get isStudent => userProfile?.role == 'student';
  bool get isAdmin => userProfile?.role == 'admin';
  bool get isOwner => userProfile?.role == 'owner';
}