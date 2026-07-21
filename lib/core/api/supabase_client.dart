import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  // Auth
  static GoTrueClient get auth => Supabase.instance.client.auth;

  // Database
  static SupabaseClient get database => Supabase.instance.client;

  // Storage
  static SupabaseStorageClient get storage => Supabase.instance.client.storage;

  // Realtime
  static RealtimeChannel get realtime => Supabase.instance.client.channel('app_channel');
}
