import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nfc_attendance_gamify/data/models/auth_state.dart';
import 'package:nfc_attendance_gamify/features/auth/screens/auth_screen.dart';
import 'package:nfc_attendance_gamify/features/auth/screens/login_screen.dart';
import 'package:nfc_attendance_gamify/features/auth/screens/signup_screen.dart';
import 'package:nfc_attendance_gamify/features/dashboard/screens/admin_dashboard_screen.dart';
import 'package:nfc_attendance_gamify/features/dashboard/screens/owner_dashboard_screen.dart';
import 'package:nfc_attendance_gamify/features/dashboard/screens/student_dashboard_screen.dart';
import 'package:nfc_attendance_gamify/features/auth/screens/splash_screen.dart';

class AppRouter {
  final AuthState authState;

  AppRouter(this.authState);

  GoRouter get config => GoRouter(
        initialLocation: '/',
        redirect: (context, state) {
          final isAuthenticated = authState.isAuthenticated;
          final isLoading = authState.isLoading;
          final location = state.location;

          // Show splash screen while loading
          if (isLoading) {
            return '/splash';
          }

          // Redirect to appropriate route based on auth state
          if (!isAuthenticated && !location.startsWith('/auth')) {
            return '/auth/login';
          }

          if (isAuthenticated) {
            final userProfile = authState.userProfile;
            if (userProfile != null) {
              if (location.startsWith('/auth')) {
                // Redirect to appropriate dashboard based on role
                switch (userProfile.role) {
                  case 'student':
                    return '/student';
                  case 'admin':
                    return '/admin';
                  case 'owner':
                    return '/owner';
                  default:
                    return '/student';
                }
              }
            }
          }

          return null;
        },
        routes: [
          // Splash Screen
          GoRoute(
            path: '/splash',
            name: 'splash',
            builder: (context, state) => const SplashScreen(),
          ),

          // Authentication Routes
          GoRoute(
            path: '/auth',
            name: 'auth',
            builder: (context, state) => const AuthScreen(),
            routes: [
              GoRoute(
                path: '/login',
                name: 'login',
                builder: (context, state) => const LoginScreen(),
              ),
              GoRoute(
                path: '/signup',
                name: 'signup',
                builder: (context, state) => const SignupScreen(),
              ),
            ],
          ),

          // Student Routes
          GoRoute(
            path: '/student',
            name: 'student_dashboard',
            builder: (context, state) => const StudentDashboardScreen(),
          ),

          // Admin Routes
          GoRoute(
            path: '/admin',
            name: 'admin_dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),

          // Owner Routes
          GoRoute(
            path: '/owner',
            name: 'owner_dashboard',
            builder: (context, state) => const OwnerDashboardScreen(),
          ),
        ],
        errorBuilder: (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Page not found: ${state.location}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      );
}