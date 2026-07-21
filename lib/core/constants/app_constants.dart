import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // App Info
  static const String appName = 'Scalib Admin';
  static const String appVersion = '1.0.0';

  // API & Supabase - Load from environment variables
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';

  // Routes
  static const String routeHome = '/';
  static const String routeLogin = '/login';
  static const String routeDashboard = '/dashboard';

  // Pagination
  static const int defaultPageSize = 20;
}

class AppStrings {
  static const String loading = 'Loading...';
  static const String error = 'An error occurred';
  static const String retry = 'Retry';
  static const String noData = 'No data available';
  static const String logout = 'Logout';
  static const String login = 'Login';
  static const String email = 'Email';
  static const String password = 'Password';
}
