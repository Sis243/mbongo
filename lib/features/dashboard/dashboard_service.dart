import '../../core/network/api_client.dart';

class DashboardService {
  static Future<Map<String, dynamic>> getDashboard() async {
    return await ApiClient.get('/backoffice/dashboard');
  }
}