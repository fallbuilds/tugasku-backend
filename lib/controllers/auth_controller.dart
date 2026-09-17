import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:tugasku_backend/services/auth_service.dart';
import 'package:tugasku_backend/repositories/auth_repository.dart';
import 'package:tugasku_backend/utils/json_response.dart';

class AuthController {
  final AuthService _authService;
  final AuthRepository _authRepository;

  AuthController(this._authService, this._authRepository);

  Future<Response> handleRegister(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final name = data['name'] as String? ?? '';
      final email = data['email'] as String? ?? '';
      final password = data['password'] as String? ?? '';
      
      final result = _authService.register(name, email, password);
      return successResponse(result, statusCode: 201);
    } catch (e) {
      return errorResponse(e.toString());
    }
  }

  Future<Response> handleLogin(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final email = data['email'] as String? ?? '';
      final password = data['password'] as String? ?? '';
      
      final result = _authService.login(email, password);
      return successResponse(result);
    } catch (e) {
      return errorResponse(e.toString());
    }
  }

  Future<Response> handleMe(Request request) async {
    try {
      final userId = request.context['userId'] as int;
      final user = _authRepository.findById(userId);
      if (user == null) {
        return errorResponse('User not found', statusCode: 404);
      }
      return successResponse({'user': user.toJson()});
    } catch (e) {
      return errorResponse(e.toString());
    }
  }

  Future<Response> handleLogout(Request request) async {
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7);
        _authService.logout(token);
      }
      return successResponse(null, message: 'Logged out successfully');
    } catch (e) {
      return errorResponse(e.toString());
    }
  }
}
