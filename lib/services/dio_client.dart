import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'session_service.dart';

/// Single source of truth for the HTTP Dio Client.
/// Automatically attaches Authorization Bearer token headers, ngrok bypass headers,
/// handles 401 Unauthorized session revocation, and intercepts No-Internet/Timeout errors.
class DioClient {
  DioClient._();

  static final DioClient instance = DioClient._();
  static final Dio dio = _buildDio();

  static Dio _buildDio() {
    final client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = SessionService.instance.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Remove Content-Type header if sending FormData so Dio generates multipart boundary
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Auto-clear invalid/expired session on 401 Unauthorized
          if (error.response?.statusCode == 401) {
            SessionService.instance.clearSession();
          }

          if (kDebugMode) {
            debugPrint('[DioClient Error] ${error.requestOptions.uri}: ${error.message}');
          }

          return handler.next(error);
        },
      ),
    );

    return client;
  }

  Map<String, String> get headers {
    final defaultHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = SessionService.instance.token;
    if (token != null && token.isNotEmpty) {
      defaultHeaders['Authorization'] = 'Bearer $token';
    }
    return defaultHeaders;
  }

  Future<Response> get(String url, {Map<String, dynamic>? queryParams, Options? options}) async {
    return dio.get(url, queryParameters: queryParams, options: options);
  }

  Future<Response> post(String url, {dynamic data, Options? options}) async {
    return dio.post(url, data: data, options: options);
  }

  Future<Response> put(String url, {dynamic data, Options? options}) async {
    return dio.put(url, data: data, options: options);
  }

  Future<Response> delete(String url, {dynamic data, Options? options}) async {
    return dio.delete(url, data: data, options: options);
  }
}
