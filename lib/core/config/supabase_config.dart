import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      authOptions: const AuthOptions(
        persistSession: true,
        autoRefreshAuthSession: true,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static Auth get auth => client.auth;
  static RealtimeChannel get realtime => client.channel('app_realtime');
}