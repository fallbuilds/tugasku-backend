import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:tugasku_backend/services/task_service.dart';
import 'package:tugasku_backend/utils/json_response.dart';

class TaskController {
  final TaskService _taskService;

  TaskController(this._taskService);

  Future<Response> handleGetTasks(Request request) async {
    try {
      final userId = request.context['userId'] as int;
      final tasks = _taskService.getTasks(userId);
      return successResponse(tasks, message: 'Tasks retrieved successfully');
    } catch (e) {
      return errorResponse(e.toString(), statusCode: 500);
    }
  }

  Future<Response> handleGetTask(Request request, String id) async {
    try {
      final userId = request.context['userId'] as int;
      final taskId = int.parse(id);
      final task = _taskService.getTask(taskId, userId);
      return successResponse(task, message: 'Task retrieved successfully');
    } catch (e) {
      return errorResponse(e.toString(), statusCode: 404);
    }
  }

  Future<Response> handleCreateTask(Request request) async {
    try {
      final userId = request.context['userId'] as int;
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final task = _taskService.createTask(userId, data);
      return successResponse(task, message: 'Task created successfully', statusCode: 201);
    } catch (e) {
      return errorResponse(e.toString());
    }
  }

  Future<Response> handleUpdateTask(Request request, String id) async {
    try {
      final userId = request.context['userId'] as int;
      final taskId = int.parse(id);
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final task = _taskService.updateTask(taskId, userId, data);
      return successResponse(task, message: 'Task updated successfully');
    } catch (e) {
      return errorResponse(e.toString());
    }
  }

  Future<Response> handleDeleteTask(Request request, String id) async {
    try {
      final userId = request.context['userId'] as int;
      final taskId = int.parse(id);
      _taskService.deleteTask(taskId, userId);
      return successResponse(null, message: 'Task deleted successfully');
    } catch (e) {
      return errorResponse(e.toString());
    }
  }

  Future<Response> handleUpdateStatus(Request request, String id) async {
    try {
      final userId = request.context['userId'] as int;
      final taskId = int.parse(id);
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      if (!data.containsKey('status')) {
        return errorResponse('status is required');
      }
      
      final task = _taskService.updateStatus(taskId, userId, data['status']);
      return successResponse(task, message: 'Task status updated successfully');
    } catch (e) {
      return errorResponse(e.toString());
    }
  }
}
