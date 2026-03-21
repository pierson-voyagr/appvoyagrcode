import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://jaazuuohrdnaggovntit.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImphYXp1dW9ocmRuYWdnb3ZudGl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1NDAyODEsImV4cCI6MjA3ODExNjI4MX0.J4FA1HES3gxUOVuXw0cRSL6d73SoX7SYRztm8gtUunI';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}
