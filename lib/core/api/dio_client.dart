import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_storage.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.read(appStorageProvider));
});

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class DioClient {
  final AppStorage _storage;
  late final Dio _dio;
  late final Dio _refreshDio;

  DioClient(this._storage) {
    final base = _resolveBaseUrl();

    _dio = Dio(BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 40),
      headers: {'Accept': 'application/json'},
    ));

    _refreshDio = Dio(BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(_AuthInterceptor(_storage, _dio, _refreshDio));
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (o) => debugPrint(o.toString()),
      ));
    }
  }

  static String _resolveBaseUrl() {
    const env = String.fromEnvironment('MBONGO_API_BASE_URL');
    if (env.isNotEmpty) return env;
    return 'https://mbongo-backend.vercel.app';
  }

  // ── Public helpers ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final r = await _dio.get<dynamic>(path);
      return _wrap(r.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final r = await _dio.post<dynamic>(path, data: body);
      return _wrap(r.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final r = await _dio.patch<dynamic>(path, data: body);
      return _wrap(r.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  // ── Private ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _wrap(dynamic data) {
    if (data == null) return {};
    if (data is List) return {'data': data};
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }

  ApiException _toApiException(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const ApiException(
        'API Mbongo inaccessible. Verifiez que le backend tourne.',
      );
    }
    final data = e.response?.data;
    String msg = 'Erreur API';
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) msg = m;
      if (m is List && m.isNotEmpty) msg = m.join(', ');
    }
    return ApiException(msg, statusCode: e.response?.statusCode);
  }
}

// ── JWT Interceptor ────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final AppStorage _storage;
  final Dio _dio;
  final Dio _refreshDio;

  bool _refreshing = false;
  final List<({RequestOptions opts, ErrorInterceptorHandler handler})> _queue =
      [];

  _AuthInterceptor(this._storage, this._dio, this._refreshDio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    if (_refreshing) {
      _queue.add((opts: err.requestOptions, handler: handler));
      return;
    }

    _refreshing = true;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _storage.clearSession();
        handler.next(err);
        return;
      }

      final resp = await _refreshDio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final newToken = (resp.data as Map)['accessToken'] as String;
      await _storage.saveAccessToken(newToken);

      handler.resolve(await _retry(err.requestOptions, newToken));
      for (final p in _queue) {
        try {
          p.handler.resolve(await _retry(p.opts, newToken));
        } catch (_) {
          p.handler.next(err);
        }
      }
    } catch (_) {
      await _storage.clearSession();
      handler.next(err);
      for (final p in _queue) {
        p.handler.next(err);
      }
    } finally {
      _refreshing = false;
      _queue.clear();
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions opts, String token) {
    opts.headers['Authorization'] = 'Bearer $token';
    return _dio.fetch<dynamic>(opts);
  }
}
