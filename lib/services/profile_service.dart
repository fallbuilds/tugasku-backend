import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:tugasku_backend/repositories/auth_repository.dart';

class ProfileService {
  final AuthRepository _authRepository;

  ProfileService(this._authRepository);

  Map<String, dynamic> getProfile(int userId) {
    final user = _authRepository.findById(userId);
    if (user == null) {
      throw Exception('User not found');
    }
    return user.toJson();
  }

  Map<String, dynamic> updateProfile(int userId, String name, String? email) {
    final user = _authRepository.findById(userId);
    if (user == null) {
      throw Exception('User not found');
    }
    
    if (name.trim().isEmpty) {
      throw Exception('name cannot be empty');
    }
    
    final newEmail = email ?? user.email;
    if (newEmail.trim().isEmpty) {
      throw Exception('email cannot be empty');
    }

    _authRepository.updateUser(userId, name, newEmail);
    
    final updatedUser = _authRepository.findById(userId)!;
    return updatedUser.toJson();
  }

  void changePassword(int userId, String oldPassword, String newPassword) {
    final user = _authRepository.findById(userId);
    if (user == null) {
      throw Exception('User not found');
    }

    if (!_verifyPassword(oldPassword, user.passwordHash)) {
      throw Exception('Invalid old password');
    }

    if (newPassword.trim().isEmpty) {
      throw Exception('New password cannot be empty');
    }
    if (newPassword.length < 8) {
      throw Exception('Password must be at least 8 characters long');
    }

    final newHash = _hashPassword(newPassword);
    _authRepository.updatePassword(userId, newHash);
  }

  String _hashPassword(String password) {
    final salt = _generateSalt();
    final hash = sha256.convert(utf8.encode('$salt$password')).toString();
    return '$salt:$hash';
  }

  bool _verifyPassword(String password, String storedHash) {
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final hash = parts[1];
    final computedHash = sha256.convert(utf8.encode('$salt$password')).toString();
    return hash == computedHash;
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List.generate(32, (_) => random.nextInt(256));
    return base64Encode(Uint8List.fromList(bytes));
  }
}
