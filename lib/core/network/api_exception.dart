/// A failure that the UI can show to the user.
///
/// The backend answers failures as
/// `{"ok": false, "error": "...", "message": "...", "errors": {...}}`, with a
/// message already written in Indonesian. That message is what reaches the
/// user; [code] lets calling code branch without matching on prose.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.fieldErrors = const {},
  });

  /// Human-readable, already localised by the server.
  final String message;

  /// Machine-readable identifier, e.g. `invalid_credentials`.
  final String? code;

  final int? statusCode;

  /// Per-field validation messages, keyed by the request field name.
  final Map<String, List<String>> fieldErrors;

  /// The credentials were rejected.
  bool get isInvalidCredentials => code == 'invalid_credentials';

  /// The stored token is missing, expired, or revoked — sign the user out.
  bool get isUnauthenticated => code == 'unauthenticated' || statusCode == 401;

  /// The request was well-formed but the data was not acceptable.
  bool get isValidation => statusCode == 422;

  /// Too many attempts; the user should wait before retrying.
  bool get isRateLimited => statusCode == 429;

  /// The device could not reach the server at all.
  bool get isNetwork => statusCode == null && code == 'network';

  /// The first message for [field], if the server rejected it.
  String? errorFor(String field) => fieldErrors[field]?.firstOrNull;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
