import 'package:shelf/shelf.dart';
import 'package:tugasku_backend/services/dashboard_service.dart';
import 'package:tugasku_backend/utils/json_response.dart';

class DashboardController {
  final DashboardService _dashboardService;

  DashboardController(this._dashboardService);

  Future<Response> handleGetDashboard(Request request) async {
    try {
      final userId = request.context['userId'] as int;
      final stats = _dashboardService.getDashboard(userId);
      return successResponse(stats, message: 'Dashboard stats retrieved successfully');
    } catch (e) {
      return errorResponse(e.toString(), statusCode: 500);
    }
  }
}
