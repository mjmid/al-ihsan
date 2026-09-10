import 'package:supabase/supabase.dart';
import '../constants/app_constants.dart';

/// Central Supabase client for Maktaba Ihsan.
/// Uses the pure Dart supabase SDK to ensure 0 native Android dependencies
/// and ultra-lightweight APK builds.
final SupabaseClient supabaseClient = SupabaseClient(
  kSupabaseUrl,
  kSupabaseAnonKey,
);
