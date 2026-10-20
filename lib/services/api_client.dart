import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_urls.dart';

/// Single source of truth HTTP Client for the Next User app.
/// Attaches Firebase Auth ID Token (Bearer) on every request,
/// automatically refreshes the token on 401 Unauthorized (one retry),
/// and manages request timeouts.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppUrls.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    ),
  )..interceptors.add(_AuthInterceptor());

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions o, RequestInterceptorHandler h) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token != null && token.isNotEmpty) {
      o.headers['Authorization'] = 'Bearer $token';
    }
    // Remove Content-Type header if sending FormData so Dio generates multipart boundary
    if (o.data is FormData) {
      o.headers.remove('Content-Type');
    }
    h.next(o);
  }

  @override
  Future<void> onError(DioException e, ErrorInterceptorHandler h) async {
    final o = e.requestOptions;
    final user = FirebaseAuth.instance.currentUser;
    if (e.response?.statusCode == 401 && user != null && o.extra['retried'] != true) {
      try {
        final fresh = await user.getIdToken(true);
        o.extra['retried'] = true;
        o.headers['Authorization'] = 'Bearer $fresh';
        return h.resolve(await ApiClient.instance.dio.fetch(o));
      } catch (_) {}
    }
    h.next(e);
  }
}
