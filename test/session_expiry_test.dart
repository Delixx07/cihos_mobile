import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cihos_mobile/core/network/api_client.dart';
import 'package:cihos_mobile/core/network/api_exception.dart';
import 'package:cihos_mobile/core/network/token_store.dart';

/// Answers every request with one canned response.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, __) async =>
      ResponseBody.fromString(
        '{"ok":false,"error":"${body['error']}","message":"${body['message']}"}',
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

class _FakeTokenStore extends TokenStore {
  _FakeTokenStore(this._token);

  final String? _token;

  @override
  Future<String?> read() async => _token;
}

ApiClient _client({
  required int statusCode,
  required Map<String, dynamic> body,
  required String? token,
  required void Function() onExpired,
}) {
  final dio = Dio(BaseOptions(validateStatus: (_) => true))
    ..httpClientAdapter = _StubAdapter(statusCode, body);

  return ApiClient(
    tokenStore: _FakeTokenStore(token),
    dio: dio,
    onUnauthenticated: () async => onExpired(),
  );
}

void main() {
  group('ApiClient session expiry', () {
    test('a 401 on an authenticated call reports the session as over', () async {
      var expired = 0;
      final client = _client(
        statusCode: 401,
        body: {'error': 'unauthenticated', 'message': 'Token tidak valid.'},
        token: 'stale-token',
        onExpired: () => expired++,
      );

      await expectLater(
        client.get('/app/me', authenticated: true),
        throwsA(isA<ApiException>()),
      );
      // The callback is fired without awaiting, so let it run.
      await Future<void>.delayed(Duration.zero);

      expect(expired, 1);
    });

    test('a 401 on sign-in does NOT end a session', () async {
      // Wrong password also answers 401, but no token was ever sent — signing
      // the patient out here would be wrong.
      var expired = 0;
      final client = _client(
        statusCode: 401,
        body: {
          'error': 'invalid_credentials',
          'message': 'Email atau password salah.',
        },
        token: null,
        onExpired: () => expired++,
      );

      await expectLater(
        client.post('/app/login', body: const {}),
        throwsA(isA<ApiException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(expired, 0);
    });

    test('an ordinary failure leaves the session alone', () async {
      var expired = 0;
      final client = _client(
        statusCode: 409,
        body: {'error': 'slot_taken', 'message': 'Antrean sudah diambil.'},
        token: 'good-token',
        onExpired: () => expired++,
      );

      await expectLater(
        client.post('/app/appointments', authenticated: true),
        throwsA(isA<ApiException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(expired, 0);
    });
  });
}
