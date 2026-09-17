import 'package:shelf/shelf.dart';
import 'package:tugasku_backend/services/auth_service.dart';
import 'package:tugasku_backend/utils/json_response.dart';

Middleware authMiddleware(AuthService authService) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return errorResponse('Token tidak ditemukan', statusCode: 401);
      }
      final token = authHeader.substring(7);
      try {
        final userId = authService.verifyToken(token);
        final updatedRequest = request.change(context: {'userId': userId});
        return innerHandler(updatedRequest);
      } catch (e) {
        return errorResponse('Token tidak valid', statusCode: 401);
      }
    };
  };
}
