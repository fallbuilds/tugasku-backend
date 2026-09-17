import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:test/test.dart';
import 'package:tugasku_backend/database/database.dart';
import 'package:tugasku_backend/repositories/auth_repository.dart';
import 'package:tugasku_backend/repositories/task_repository.dart';
import 'package:tugasku_backend/services/auth_service.dart';
import 'package:tugasku_backend/services/task_service.dart';
import 'package:tugasku_backend/services/dashboard_service.dart';
import 'package:tugasku_backend/services/calendar_service.dart';
import 'package:tugasku_backend/services/profile_service.dart';
import 'package:tugasku_backend/controllers/auth_controller.dart';
import 'package:tugasku_backend/controllers/task_controller.dart';
import 'package:tugasku_backend/controllers/dashboard_controller.dart';
import 'package:tugasku_backend/controllers/calendar_controller.dart';
import 'package:tugasku_backend/controllers/profile_controller.dart';
import 'package:tugasku_backend/routes/router.dart';

void main() {
  late HttpServer server;
  late String baseUrl;

  setUpAll(() async {
    // Delete previous test db if exists
    final testDb = File('tugasku.db');
    if (await testDb.exists()) {
      try {
        await testDb.delete();
      } catch (_) {}
    }

    final dbHelper = DatabaseHelper();
    dbHelper.initialize();

    final authRepository = AuthRepository(dbHelper);
    final taskRepository = TaskRepository(dbHelper);

    final authService = AuthService(authRepository);
    final taskService = TaskService(taskRepository);
    final dashboardService = DashboardService(taskRepository);
    final calendarService = CalendarService(taskRepository);
    final profileService = ProfileService(authRepository);

    final authController = AuthController(authService, authRepository);
    final taskController = TaskController(taskService);
    final dashboardController = DashboardController(dashboardService);
    final calendarController = CalendarController(calendarService);
    final profileController = ProfileController(profileService);

    final appRouter = AppRouter(
      authController,
      taskController,
      dashboardController,
      calendarController,
      profileController,
      authService,
    );

    final handler = Pipeline().addHandler(appRouter.handler);
    server = await io.serve(handler, '127.0.0.1', 0);
    baseUrl = 'http://127.0.0.1:${server.port}/api';
  });

  tearDownAll(() async {
    await server.close(force: true);
  });

  group('TugasKu Backend API Tests', () {
    String tokenUserA = '';
    String tokenUserB = '';
    int taskAId = 0;

    test('Register User A should succeed', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'Siswa A',
          'email': 'siswa_a@example.com',
          'password': 'password123',
        }),
      );

      expect(res.statusCode, 201);
      final data = jsonDecode(res.body);
      expect(data['success'], true);
    });

    test('Register duplicate email should fail', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'Siswa A Duplikat',
          'email': 'siswa_a@example.com',
          'password': 'password123',
        }),
      );

      expect(res.statusCode, 400);
      final data = jsonDecode(res.body);
      expect(data['success'], false);
    });

    test('Login User A should return JWT token', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'siswa_a@example.com',
          'password': 'password123',
        }),
      );

      expect(res.statusCode, 200);
      final data = jsonDecode(res.body);
      expect(data['success'], true);
      tokenUserA = data['data']['token'];
      expect(tokenUserA.isNotEmpty, true);
    });

    test('Register and Login User B', () async {
      await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'Siswa B',
          'email': 'siswa_b@example.com',
          'password': 'password123',
        }),
      );

      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'siswa_b@example.com',
          'password': 'password123',
        }),
      );

      expect(res.statusCode, 200);
      final data = jsonDecode(res.body);
      tokenUserB = data['data']['token'];
      expect(tokenUserB.isNotEmpty, true);
    });

    test('Get current user /me with valid token', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $tokenUserA'},
      );

      expect(res.statusCode, 200);
      final data = jsonDecode(res.body);
      expect(data['data']['user']['email'], 'siswa_a@example.com');
    });

    test('Get /me with invalid token should return 401', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer invalid_token_123'},
      );

      expect(res.statusCode, 401);
    });

    test('User A creates a task', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $tokenUserA',
        },
        body: jsonEncode({
          'title': 'Laporan Praktikum Kimia',
          'subject': 'Kimia',
          'class_name': 'XI IPA 1',
          'deadline': '2026-09-20T23:59:00.000',
          'priority': 'high',
          'description': 'Laporan reaksi redoks',
        }),
      );

      expect(res.statusCode, 201);
      final data = jsonDecode(res.body);
      expect(data['success'], true);
      taskAId = data['data']['id'];
      expect(taskAId > 0, true);
    });

    test('User A gets task list (contains User A task)', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Authorization': 'Bearer $tokenUserA'},
      );

      expect(res.statusCode, 200);
      final data = jsonDecode(res.body);
      final tasks = data['data'] as List;
      expect(tasks.any((t) => t['id'] == taskAId), true);
    });

    test('User B gets task list (does NOT contain User A task)', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Authorization': 'Bearer $tokenUserB'},
      );

      expect(res.statusCode, 200);
      final data = jsonDecode(res.body);
      final tasks = data['data'] as List;
      expect(tasks.any((t) => t['id'] == taskAId), false);
    });

    test('User B CANNOT view User A task detail (Authorization protection)', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/tasks/$taskAId'),
        headers: {'Authorization': 'Bearer $tokenUserB'},
      );

      // Should be 404 or access denied
      expect(res.statusCode, anyOf(404, 403, 400));
    });

    test('User A updates their task status to completed', () async {
      final res = await http.patch(
        Uri.parse('$baseUrl/tasks/$taskAId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $tokenUserA',
        },
        body: jsonEncode({'status': 'completed'}),
      );

      expect(res.statusCode, 200);
      final data = jsonDecode(res.body);
      expect(data['data']['status'], 'completed');
      expect(data['data']['completed_at'], isNotNull);
    });

    test('User A gets dashboard data', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/dashboard'),
        headers: {'Authorization': 'Bearer $tokenUserA'},
      );

      expect(res.statusCode, 200);
      final data = jsonDecode(res.body);
      expect(data['success'], true);
      expect(data['data']['total_tasks'], greaterThanOrEqualTo(1));
    });

    test('User A deletes their task', () async {
      final res = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskAId'),
        headers: {'Authorization': 'Bearer $tokenUserA'},
      );

      expect(res.statusCode, 200);
    });

    test('User A logs out', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {'Authorization': 'Bearer $tokenUserA'},
      );

      expect(res.statusCode, 200);
    });

    test('Logged out token cannot be used again', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $tokenUserA'},
      );

      expect(res.statusCode, 401);
    });
  });
}
