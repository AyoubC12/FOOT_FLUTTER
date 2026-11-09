import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import 'api_exception.dart';
import 'api_paths.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({Dio? dio, TokenStore? tokenStore})
    : _tokens = tokenStore ?? TokenStore(),
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConstants.apiBaseUrl,
              connectTimeout: AppConstants.connectTimeout,
              receiveTimeout: AppConstants.receiveTimeout,
              headers: const {'Content-Type': 'application/json'},
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokens.readAccess();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401 ||
              error.requestOptions.extra['retried'] == true) {
            handler.next(error);
            return;
          }
          final refreshed = await _refresh();
          if (!refreshed) {
            handler.next(error);
            return;
          }
          final token = await _tokens.readAccess();
          final request = error.requestOptions;
          request.extra['retried'] = true;
          request.headers['Authorization'] = 'Bearer $token';
          try {
            handler.resolve(await _dio.fetch(request));
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStore _tokens;
  bool _refreshing = false;

  Dio get dio => _dio;

  TokenStore get tokens => _tokens;

  bool get hasBaseUrl => AppConstants.apiBaseUrl.isNotEmpty;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _guard(
      () => _dio.get<T>(path, queryParameters: queryParameters),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Duration? receiveTimeout,
  }) {
    return _guard(
      () => _dio.post<T>(
        path,
        data: data,
        options: receiveTimeout == null
            ? null
            : Options(receiveTimeout: receiveTimeout),
      ),
    );
  }

  Future<Response<T>> patch<T>(String path, {Object? data}) {
    return _guard(() => _dio.patch<T>(path, data: data));
  }

  Future<Response<T>> delete<T>(String path) {
    return _guard(() => _dio.delete<T>(path));
  }

  Future<bool> _refresh() async {
    if (_refreshing) return false;
    final refresh = await _tokens.readRefresh();
    if (refresh == null || refresh.isEmpty || !hasBaseUrl) return false;
    _refreshing = true;
    try {
      final response = await Dio(
        BaseOptions(baseUrl: AppConstants.apiBaseUrl),
      ).post<Map<String, dynamic>>(
        ApiPaths.tokenRefresh,
        data: {'refresh': refresh},
      );
      final access = response.data?['access'] as String?;
      if (access == null || access.isEmpty) return false;
      await _tokens.save(access: access, refresh: refresh);
      return true;
    } catch (_) {
      await _tokens.clear();
      return false;
    } finally {
      _refreshing = false;
    }
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    if (!hasBaseUrl) {
      throw const ApiException('API is not configured.');
    }
    try {
      return await request();
    } on DioException catch (error) {
      throw ApiException(
        _extractMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  String _extractMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      final nonField = data['non_field_errors'];
      if (nonField is List && nonField.isNotEmpty) {
        return nonField.first.toString();
      }
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The assistant took too long to respond.';
    }
    if (error.type == DioExceptionType.connectionError) {
      final base = AppConstants.apiBaseUrl;
      return 'Could not reach Django at $base. Start the backend with '
          '.venv (python manage.py runserver) and keep this URL.';
    }
    return error.message ?? 'Network request failed';
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStore: ref.watch(tokenStoreProvider));
});
