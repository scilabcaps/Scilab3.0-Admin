import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    setLoading(true);
    setError(null);
    
    try {
      // TODO: Implement login logic with use case
      // final user = await _loginUseCase(email, password);
      // setUser(user);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    setLoading(true);
    
    try {
      // TODO: Implement logout logic
      setUser(null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
}
