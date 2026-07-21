import '../../../core/api/supabase_client.dart';
import '../../../core/api/supabase_config.dart';

class AuthController {
  bool _isLoading = false;
  String? _errorMessage;

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
      final List<Map<String, dynamic>> userDataList = await SupabaseService.database
          .from(SupabaseConfig.tableUserInfo)
          .select('is_banned')
          .eq('id', response.user!.id);

      if (userDataList.isEmpty) {
        // If no user info is found, assume not banned and proceed
        _isLoading = false;
        return true;
      }

      final userData = userDataList.first;

      if (userData['is_banned'] == true) {
        await SupabaseService.auth.signOut();
        _isLoading = false;
        _errorMessage = 'Your account has been banned. Please contact an administrator.';
        return false;
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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
    await SupabaseService.auth.signOut();
  }

  void clearError() {
    _errorMessage = null;
  }
}
