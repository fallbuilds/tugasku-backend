import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:tugasku_backend/controllers/auth_controller.dart';
import 'package:tugasku_backend/controllers/task_controller.dart';
import 'package:tugasku_backend/controllers/dashboard_controller.dart';
import 'package:tugasku_backend/controllers/calendar_controller.dart';
import 'package:tugasku_backend/controllers/profile_controller.dart';
import 'package:tugasku_backend/services/auth_service.dart';
import 'package:tugasku_backend/middleware/auth_middleware.dart';

class AppRouter {
  final AuthController authController;
  final TaskController taskController;
  final DashboardController dashboardController;
  final CalendarController calendarController;
  final ProfileController profileController;
  final AuthService authService;

  AppRouter(
    this.authController,
    this.taskController,
    this.dashboardController,
    this.calendarController,
    this.profileController,
    this.authService,
  );

  Handler get handler {
    final publicRouter = Router();
    publicRouter.post('/api/auth/register', authController.handleRegister);
    publicRouter.post('/api/auth/login', authController.handleLogin);

    final protectedRouter = Router();
    protectedRouter.get('/api/auth/me', authController.handleMe);
    protectedRouter.post('/api/auth/logout', authController.handleLogout);

    // Dashboard
    protectedRouter.get('/api/dashboard', dashboardController.handleGetDashboard);

    // Tasks
    protectedRouter.get('/api/tasks', taskController.handleGetTasks);
    protectedRouter.post('/api/tasks', taskController.handleCreateTask);
    protectedRouter.get('/api/tasks/<id>', taskController.handleGetTask);
    protectedRouter.put('/api/tasks/<id>', taskController.handleUpdateTask);
    protectedRouter.delete('/api/tasks/<id>', taskController.handleDeleteTask);
    protectedRouter.patch('/api/tasks/<id>/status', taskController.handleUpdateStatus);

    // Calendar
    protectedRouter.get('/api/calendar', calendarController.handleGetCalendar);

    // Profile
    protectedRouter.get('/api/profile', profileController.handleGetProfile);
    protectedRouter.put('/api/profile', profileController.handleUpdateProfile);
    protectedRouter.put('/api/profile/password', profileController.handleChangePassword);

    final protectedHandler = Pipeline()
        .addMiddleware(authMiddleware(authService))
        .addHandler(protectedRouter.call);

    return Cascade()
        .add(publicRouter.call)
        .add(protectedHandler)
        .handler;
  }
}
