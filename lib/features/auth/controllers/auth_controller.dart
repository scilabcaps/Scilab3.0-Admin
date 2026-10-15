import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/supabase_client.dart';
import '../../../core/api/supabase_config.dart';
import '../../audit/services/audit_service.dart';

class AuthController {
  bool _isLoading = false;
  String? _errorMessage;
  final AuditService _auditService;

  AuthController({AuditService? auditService})
    : _auditService = auditService ?? AuditService();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;

    try {
      final response = await SupabaseService.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        _isLoading = false;
        return false;
      }

      // Check if user is banned
      final List<Map<String, dynamic>> userDataList = await SupabaseService
          .database
          .from(SupabaseConfig.tableUserInfo)
          .select('is_banned')
          .eq('id', response.user!.id);

      if (userDataList.isEmpty) {
        // If no user info is found, assume not banned and proceed
        await _recordLogin(response.user!, fallbackEmail: email);
        _isLoading = false;
        return true;
      }

      final userData = userDataList.first;

      if (userData['is_banned'] == true) {
        await SupabaseService.auth.signOut();
        _isLoading = false;
        _errorMessage =
            'Your account has been banned. Please contact an administrator.';
        return false;
      }

      await _recordLogin(response.user!, fallbackEmail: email);
      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = LoginErrorMessages.from(e);
      return false;
    }
  }

  Future<bool> signup(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;

    try {
      final response = await SupabaseService.auth.signUp(
        email: email.trim(),
        password: password,
      );

      _isLoading = false;
      return response.user != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<void> logout() async {
    final currentUser = SupabaseService.auth.currentUser;
    if (currentUser != null) {
      await _auditService.logAction(
        actionType: 'LOGOUT',
        entityType: 'user',
        entityId: currentUser.id,
        description: AuthAuditMessages.logout(currentUser.email),
      );
    }
    await SupabaseService.auth.signOut();
  }

  Future<void> _recordLogin(User user, {required String fallbackEmail}) {
    return _auditService.logAction(
      actionType: 'LOGIN',
      entityType: 'user',
      entityId: user.id,
      description: AuthAuditMessages.login(user.email ?? fallbackEmail.trim()),
    );
  }

  void clearError() {
    _errorMessage = null;
  }
}

class AuthAuditMessages {
  static String login(String email) => 'User $email logged in successfully';

  static String logout(String? email) =>
      'User ${email ?? 'unknown email'} logged out';
}

class LoginErrorMessages {
  static const invalidCredentials =
      'Check your email and password, then try again.';

  static const generic =
      'We couldn’t sign you in right now. Please try again in a moment.';

  static String from(Object error) {
    final details = error.toString().toLowerCase();

    if (details.contains('invalid_credentials') ||
        details.contains('invalid login credentials')) {
      return invalidCredentials;
    }

    return generic;
  }
}
