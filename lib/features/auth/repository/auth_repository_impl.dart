import 'auth_repository.dart';
import '../models/user.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<User?> getCurrentUser() {
    // TODO: Implement with Supabase auth
    throw UnimplementedError();
  }

  @override
  Future<User> signIn(String email, String password) {
    // TODO: Implement with Supabase auth
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    // TODO: Implement with Supabase auth
    throw UnimplementedError();
  }

  @override
  Future<User> signUp(String email, String password, String? name) {
    // TODO: Implement with Supabase auth
    throw UnimplementedError();
  }
}
