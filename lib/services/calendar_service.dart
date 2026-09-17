import 'package:tugasku_backend/repositories/task_repository.dart';

class CalendarService {
  final TaskRepository _taskRepository;

  CalendarService(this._taskRepository);

  List<Map<String, dynamic>> getCalendarTasks(int userId, int month, int year) {
    return _taskRepository.getTasksByMonth(userId, month, year);
  }
}
