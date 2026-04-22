import '../../../models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> signUp(String name, String email, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  
  final List<UserModel> _users = [
    UserModel(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      profileImageUrl: 'https://i.pravatar.cc/150?img=33',
    )
  ];

  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    final user = _users.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('Usuario no encontrado o contraseña incorrecta'),
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<UserModel> signUp(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (_users.any((u) => u.email == email)) {
      throw Exception('El correo ya está en uso');
    }
    
    final newUser = UserModel(
      id: const Uuid().v4(),
      name: name,
      email: email,
      profileImageUrl: 'https://i.pravatar.cc/150?u=$email',
    );
    _users.add(newUser);
    _currentUser = newUser;
    return newUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentUser; // For demo, we start logged out unless we want to auto-login
  }
}
