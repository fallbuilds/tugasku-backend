import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:tugasku_backend/repositories/auth_repository.dart';

class AuthService {
  final AuthRepository _authRepository;
  static const String _jwtSecret = 'tugasku_secret_key_2026';
  final Set<String> _blacklistedTokens = {};

  AuthService(this._authRepository);

  Map<String, dynamic> register(String name, String email, String password) {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      throw Exception('Name, email, and password are required');
    }
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters long');
    }

    final existingUser = _authRepository.findByEmail(email);
    if (existingUser != null) {
      throw Exception('Email already in use');
    }

    final passwordHash = _hashPassword(password);
    final user = _authRepository.createUser(name, email, passwordHash);

    return {'user': user.toJson()};
  }

  Map<String, dynamic> login(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }

    final user = _authRepository.findByEmail(email);
    if (user == null) {
      throw Exception('Invalid email or password');
    }

    if (!_verifyPassword(password, user.passwordHash)) {
      throw Exception('Invalid email or password');
    }

    final token = _generateToken(user.id!, user.email);
    return {'token': token, 'user': user.toJson()};
  }

  int verifyToken(String token) {
    if (_blacklistedTokens.contains(token)) {
      throw Exception('Token is invalid');
    }
    return _verifyJwt(token);
  }

  void logout(String token) {
    _blacklistedTokens.add(token);
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

  String _generateToken(int userId, String email) {
    final jwt = JWT({'user_id': userId, 'email': email});
    return jwt.sign(SecretKey(_jwtSecret), expiresIn: Duration(days: 7));
  }

  int _verifyJwt(String token) {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    return jwt.payload['user_id'] as int;
  }
}
