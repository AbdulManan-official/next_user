import 'session_service.dart';

/// Centralized API HTTP client wrapper with token injection and error handling.
class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();

  final SessionService _session = SessionService.instance;

  Map<String, String> get headers {
    final defaultHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_session.token != null) {
      defaultHeaders['Authorization'] = 'Bearer ${_session.token}';
    }
    return defaultHeaders;
  }

  Future<Map<String, dynamic>> get(String url, {Map<String, dynamic>? queryParams}) async {
    // Implement standard GET request handling
    return {};
  }

  Future<Map<String, dynamic>> post(String url, {dynamic data}) async {
    // Implement standard POST request handling
    return {};
  }

  Future<Map<String, dynamic>> put(String url, {dynamic data}) async {
    // Implement standard PUT request handling
    return {};
  }

  Future<Map<String, dynamic>> delete(String url, {dynamic data}) async {
    // Implement standard DELETE request handling
    return {};
  }
}
