import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:tugasku_backend/services/profile_service.dart';
import 'package:tugasku_backend/utils/json_response.dart';

class ProfileController {
  final ProfileService _profileService;

  ProfileController(this._profileService);

  Future<Response> handleGetProfile(Request request) async {
    try {
      final userId = request.context['userId'] as int;
      final profile = _profileService.getProfile(userId);
      // Remove password hash from response
      profile.remove('password_hash');
      return successResponse(profile, message: 'Profile retrieved successfully');
    } catch (e) {
      return errorResponse(e.toString(), statusCode: 404);
    }
  }

  Future<Response> handleUpdateProfile(Request request) async {
    try {
      final userId = request.context['userId'] as int;
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      if (!data.containsKey('name')) {
        return errorResponse('name is required');
      }
      
      final profile = _profileService.updateProfile(userId, data['name'], data['email']);
      profile.remove('password_hash');
      return successResponse(profile, message: 'Profile updated successfully');
    } catch (e) {
      return errorResponse(e.toString());
    }
  }

  Future<Response> handleChangePassword(Request request) async {
    try {
      final userId = request.context['userId'] as int;
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      if (!data.containsKey('old_password') || !data.containsKey('new_password')) {
        return errorResponse('old_password and new_password are required');
      }
      
      _profileService.changePassword(userId, data['old_password'], data['new_password']);
      return successResponse(null, message: 'Password changed successfully');
    } catch (e) {
      return errorResponse(e.toString());
    }
  }
}
