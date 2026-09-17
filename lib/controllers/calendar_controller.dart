import 'package:shelf/shelf.dart';
import 'package:tugasku_backend/services/calendar_service.dart';
import 'package:tugasku_backend/utils/json_response.dart';

class CalendarController {
  final CalendarService _calendarService;

  CalendarController(this._calendarService);

  Future<Response> handleGetCalendar(Request request) async {
    try {
      final userId = request.context['userId'] as int;
      final queryParams = request.url.queryParameters;
      
      if (!queryParams.containsKey('month') || !queryParams.containsKey('year')) {
        return errorResponse('month and year query parameters are required');
      }
      
      final month = int.parse(queryParams['month']!);
      final year = int.parse(queryParams['year']!);
      
      if (month < 1 || month > 12) {
        return errorResponse('month must be between 1 and 12');
      }
      
      final tasks = _calendarService.getCalendarTasks(userId, month, year);
      return successResponse(tasks, message: 'Calendar tasks retrieved successfully');
    } catch (e) {
      return errorResponse(e.toString());
    }
  }
}
