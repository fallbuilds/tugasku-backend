import 'dart:convert';
import 'package:shelf/shelf.dart';

Response jsonResponse(int statusCode, Map<String, dynamic> body) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: {'Content-Type': 'application/json'},
  );
}

Response successResponse(dynamic data, {String message = 'Success', int statusCode = 200}) {
  return jsonResponse(statusCode, {
    'success': true,
    'message': message,
    'data': data,
  });
}

Response errorResponse(String message, {int statusCode = 400}) {
  return jsonResponse(statusCode, {
    'success': false,
    'message': message,
  });
}
