import 'package:tugasku_backend/repositories/task_repository.dart';

class DashboardService {
  final TaskRepository _taskRepository;

  DashboardService(this._taskRepository);

  Map<String, dynamic> getDashboard(int userId) {
    return _taskRepository.getDashboardStats(userId);
  }
}
