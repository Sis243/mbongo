import '../../core/network/api_client.dart';

class AuthService {
  static Future<void> login(String phone) async {
    final res = await ApiClient.post('/admin-auth/login', {
      'phone': phone,
    });

    ApiClient.accessToken = res['access_token'];
  }
}