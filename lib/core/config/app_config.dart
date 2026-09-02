/// Runtime configuration, supplied at build time.
///
/// Values come from `--dart-define`, never from a committed file, so the API
/// key does not sit in source control. Run the app with:
///
/// ```
/// flutter run --dart-define-from-file=env.json
/// ```
///
/// See `env.example.json` for the expected shape. `env.json` is gitignored.
///
/// Note on secrets: an API key shipped inside an APK is not truly secret —
/// anyone can unpack the binary and read it. Keeping it out of git protects
/// the repository, not the release build. The real defence is that this key
/// is scoped to `/api/app/*` only, and that every patient-specific call also
/// requires a per-user bearer token.
abstract final class AppConfig {
  /// Base URL of the Laravel API, without a trailing slash.
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://172.20.0.39/appointment_test/public',
  );

  /// Shared secret sent as `X-Api-Key` on every request.
  static const apiKey = String.fromEnvironment('MOBILE_API_KEY');

  /// Agora App ID from Agora Console (Project: Video Call Doctor).
  static const agoraAppId = String.fromEnvironment('AGORA_APP_ID');

  /// Default Agora Channel Name for local testing.
  static const agoraChannelName = String.fromEnvironment(
    'AGORA_CHANNEL_NAME',
    defaultValue: 'cihos_test',
  );

  /// Temporary Agora RTC Token for local testing.
  static const agoraTempToken = String.fromEnvironment('AGORA_TEMP_TOKEN');

  /// Whether the app was built with the configuration it needs.
  static bool get isConfigured => apiKey.isNotEmpty;

  /// Whether Agora is configured with an App ID.
  static bool get isAgoraConfigured => agoraAppId.isNotEmpty;

  /// How long to wait before giving up on a request.
  static const connectTimeout = Duration(seconds: 12);
  static const receiveTimeout = Duration(seconds: 15);
}
