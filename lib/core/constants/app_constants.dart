class AppConstants {
  // App Info
  static const String appName = 'Scalib Admin';
  static const String appVersion = '1.0.0';

  // API & Supabase
  static const String supabaseUrl = 'https://mfemixkenhgpsterrqzo.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mZW1peGtlbmhncHN0ZXJycXpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4OTI5OTksImV4cCI6MjA5MzQ2ODk5OX0.nLwM4aKBjoMcNjhdn6-wC7gT4W4qnNduRq6qpBejzAs';

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
