import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
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

Middleware corsMiddleware() {
  return createMiddleware(
    requestHandler: (Request request) {
      if (request.method == 'OPTIONS') {
        return Response.ok(
          '',
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
          },
        );
      }
      return null;
    },
    responseHandler: (Response response) {
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
      });
    },
  );
}

void main() async {
  // Initialize Database
  final dbHelper = DatabaseHelper();
  dbHelper.initialize();

  // Initialize Repositories
  final authRepository = AuthRepository(dbHelper);
  final taskRepository = TaskRepository(dbHelper);

  // Initialize Services
  final authService = AuthService(authRepository);
  final taskService = TaskService(taskRepository);
  final dashboardService = DashboardService(taskRepository);
  final calendarService = CalendarService(taskRepository);
  final profileService = ProfileService(authRepository);

  // Initialize Controllers
  final authController = AuthController(authService, authRepository);
  final taskController = TaskController(taskService);
  final dashboardController = DashboardController(dashboardService);
  final calendarController = CalendarController(calendarService);
  final profileController = ProfileController(profileService);

  // Initialize Router
  final appRouter = AppRouter(
    authController,
    taskController,
    dashboardController,
    calendarController,
    profileController,
    authService,
  );

  final handler = Pipeline()
      .addMiddleware(corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(appRouter.handler);

  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await io.serve(handler, '0.0.0.0', port);
  print('Server listening on http://${server.address.host}:${server.port}');
}
