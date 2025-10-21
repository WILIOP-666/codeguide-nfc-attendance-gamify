import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nfc_attendance_gamify/app/router/app_router.dart';
import 'package:nfc_attendance_gamify/core/config/theme/app_theme.dart';
import 'package:nfc_attendance_gamify/core/config/supabase_config.dart';
import 'package:nfc_attendance_gamify/features/auth/providers/auth_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final appRouter = AppRouter(authState);

    return MaterialApp.router(
      title: dotenv.env['APP_NAME'] ?? 'NFC Attendance Gamify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter.config(),
    );
  }
}