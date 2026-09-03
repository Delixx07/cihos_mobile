import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// Talks to the Laravel API.
///
/// Every request carries the shared `X-Api-Key`; requests that need a signed-in
/// patient also carry their bearer token. Failures are normalised into
/// [ApiException] so screens never have to reason about Dio types or HTTP
/// status codes directly.
class ApiClient {
  ApiClient({required TokenStore tokenStore, Dio? dio})
    : _tokenStore = tokenStore,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: '${AppConfig.baseUrl}/api',
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              headers: {
                'Accept': 'application/json',
                'X-Api-Key': AppConfig.apiKey,
              },
              // Let every status through; _unwrap decides what is an error, so
              // a 401 body can be read rather than thrown away by Dio.
              validateStatus: (_) => true,
            ),
          )..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                _log(
                  '[API >] ${options.method} ${options.uri}'
                  '\n  Body: ${options.data}',
                );
                handler.next(options);
              },
              onResponse: (response, handler) {
                _log(
                  '[API <] ${response.statusCode} ${response.requestOptions.uri}',
                );
                handler.next(response);
              },
              onError: (error, handler) {
                _log(
                  '[API x] ${error.type} ${error.requestOptions.uri}'
                  '\n  Message: ${error.message}',
                );
                handler.next(error);
              },
            ),
          );

  /// Debug-only logging.
  ///
  /// Never logs headers: they carry the patient's bearer token and the shared
  /// API key, and logcat is readable by other tooling on the device. Response
  /// bodies are omitted too — they hold medical record numbers and appointment
  /// details.
  static void _log(String message) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print(message);
  }

  final Dio _dio;
  final TokenStore _tokenStore;

  Future<Response<dynamic>> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool authenticated = false,
  }) async {
    final headers = <String, String>{};
    if (authenticated) {
      final token = await _tokenStore.read();
      if (token == null) {
        throw const ApiException(
          message: 'Sesi Anda telah berakhir. Silakan masuk kembali.',
          code: 'unauthenticated',
          statusCode: 401,
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      return await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method, headers: headers),
      );
    } on DioException catch (e) {
      final msg = switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'Sambungan ke server terlalu lama. Periksa jaringan Anda.',
        _ =>
          'Tidak dapat terhubung ke server (${AppConfig.baseUrl}$path). Pastikan backend Anda aktif.',
      };
      throw ApiException(
        message: msg,
        code: 'network',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Turns a response into its payload, or throws [ApiException].
  Map<String, dynamic> _unwrap(Response<dynamic> response) {
    final data = response.data;
    if (data is! Map) {
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return {'ok': true, 'data': data};
      }
      throw ApiException(
        message: 'Respons server tidak dikenali (${response.statusCode}): ${response.data}',
        code: 'bad_response',
        statusCode: response.statusCode,
      );
    }

    final map = data.cast<String, dynamic>();
    final isSuccess = map['ok'] == true ||
        map['success'] == true ||
        map['status'] == true ||
        map['status'] == 'success' ||
        map['status'] == 200 ||
        map['status'] == 201 ||
        (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300 &&
            map['error'] == null &&
            map['errors'] == null);

    if (isSuccess) return map;

    final errorMessage = (map['message'] as String?) ??
        (map['error'] as String?) ??
        (map['msg'] as String?) ??
        'Terjadi kesalahan pada server (${response.statusCode}).';

    throw ApiException(
      message: errorMessage,
      code: map['error']?.toString(),
      statusCode: response.statusCode,
      fieldErrors: _fieldErrors(map['errors'] ?? map['error']),
    );
  }

  static Map<String, List<String>> _fieldErrors(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): switch (entry.value) {
          final List<dynamic> list => list.map((e) => e.toString()).toList(),
          final Object value => [value.toString()],
          null => const <String>[],
        },
    };
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = false,
  }) async => _unwrap(
    await _send('GET', path, query: query, authenticated: authenticated),
  );

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool authenticated = false,
  }) async => _unwrap(
    await _send('POST', path, body: body, authenticated: authenticated),
  );
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStore: ref.watch(tokenStoreProvider)),
);
