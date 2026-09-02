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
  static const cmsBaseUrl = String.fromEnvironment('CMS_BASE_URL', defaultValue: 'http://172.20.21.10/mobile_admin');

  /// API key for CMS Content (promotions, articles).
  static const cmsApiKey = String.fromEnvironment('CMS_API_KEY', defaultValue: 'cihos_content_key_9f3b2a8c1e7d4056a82d1c9b3e7a0f41');

  /// Resolves an image URL from the CMS.
  /// Handles relative paths, XAMPP public/storage mappings, and URI encoding for spaces.
  static String? resolveCmsImageUrl(dynamic rawUrl) {
    if (rawUrl == null) return null;
    var str = rawUrl.toString().trim();
    if (str.isEmpty) return null;

    // 1. If localhost or 127.0.0.1, replace with cmsBaseUrl's host
    final cmsUri = Uri.tryParse(cmsBaseUrl);
    if (cmsUri != null && cmsUri.host.isNotEmpty) {
      if (str.contains('localhost')) {
        str = str.replaceAll('localhost', cmsUri.host);
      } else if (str.contains('127.0.0.1')) {
        str = str.replaceAll('127.0.0.1', cmsUri.host);
      }
    }

    // 2. If relative path, prepend cmsBaseUrl
    if (!str.startsWith('http://') && !str.startsWith('https://')) {
      final base = cmsBaseUrl.endsWith('/')
          ? cmsBaseUrl.substring(0, cmsBaseUrl.length - 1)
          : cmsBaseUrl;
      final path = str.startsWith('/') ? str : '/$str';
      str = '$base$path';
    }

    // 3. In XAMPP Apache setups where storage junction is under public/storage,
    // ensure /mobile_admin/storage/ maps to /mobile_admin/public/storage/
    if (str.contains('/mobile_admin/storage/') &&
        !str.contains('/mobile_admin/public/storage/')) {
      str = str.replaceAll('/mobile_admin/storage/', '/mobile_admin/public/storage/');
    }

    // 4. Encode spaces (e.g. "hair skin.png" -> "hair%20skin.png")
    try {
      str = Uri.encodeFull(str);
    } catch (_) {}

    return str;
  }

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://172.20.0.39/appointment_test/public',
  );

  /// Shared secret sent as `X-Api-Key` on every request.
  static const apiKey = String.fromEnvironment('MOBILE_API_KEY', defaultValue: 'b18562cd3f6b4ea82284c9da417c1f19');

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
