import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AppConfigService {
  static const String _backendBaseUrlKey = 'backendBaseUrl';
  static const String _translationPathKey = 'geminiTranslationPath';
  static const String _geminiModelKey = 'geminiModel';
  static const String _defaultSourceLangKey = 'defaultSourceLanguage';
  static const String _defaultTargetLangKey = 'defaultTargetLanguage';

  static const String defaultBackendBaseUrl = ApiConfig.baseUrl;
  static const String defaultTranslationPath = '/api/translation/gemini';

  /// Empty = let the backend pick its configured Gemini model.
  static const String defaultGeminiModel = '';
  static const String defaultSourceLanguage = 'auto';
  static const String defaultTargetLanguage = 'en';

  /// `ApiConfig.baseUrl + '/api/translation/gemini'` unless overridden.
  static String get defaultTranslationEndpoint =>
      '$defaultBackendBaseUrl$defaultTranslationPath';

  static Future<AppConfig> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Older builds defaulted to (and could persist) a localhost:5000 URL,
    // which never works on a device. Drop such stale overrides so the
    // compile-time ApiConfig.baseUrl wins.
    var backendBaseUrl = prefs.getString(_backendBaseUrlKey)?.trim();
    if (backendBaseUrl != null &&
        (backendBaseUrl.isEmpty || _isStaleLocalOverride(backendBaseUrl))) {
      await prefs.remove(_backendBaseUrlKey);
      backendBaseUrl = null;
    }

    final path = prefs.getString(_translationPathKey)?.trim();

    return AppConfig(
      backendBaseUrl: backendBaseUrl ?? defaultBackendBaseUrl,
      geminiTranslationPath:
          (path == null || path.isEmpty) ? defaultTranslationPath : path,
      geminiModel: prefs.getString(_geminiModelKey) ?? defaultGeminiModel,
      defaultSourceLanguage:
          prefs.getString(_defaultSourceLangKey) ?? defaultSourceLanguage,
      defaultTargetLanguage:
          prefs.getString(_defaultTargetLangKey) ?? defaultTargetLanguage,
    );
  }

  static Future<void> save(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendBaseUrlKey, config.backendBaseUrl);
    await prefs.setString(_translationPathKey, config.geminiTranslationPath);
    await prefs.setString(_geminiModelKey, config.geminiModel);
    await prefs.setString(_defaultSourceLangKey, config.defaultSourceLanguage);
    await prefs.setString(_defaultTargetLangKey, config.defaultTargetLanguage);
  }

  /// True for a loopback / emulator-host URL when the build itself is not
  /// pointed at one (i.e. a leftover from an older install, not a deliberate
  /// local-dev `--dart-define=API_BASE_URL=...`).
  static bool _isStaleLocalOverride(String url) {
    if (_isLocalHost(defaultBackendBaseUrl)) return false;
    return _isLocalHost(url);
  }

  static bool _isLocalHost(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2' ||
        host == '0.0.0.0';
  }
}

class AppConfig {
  final String backendBaseUrl;
  final String geminiTranslationPath;
  final String geminiModel;
  final String defaultSourceLanguage;
  final String defaultTargetLanguage;

  const AppConfig({
    required this.backendBaseUrl,
    required this.geminiTranslationPath,
    required this.geminiModel,
    required this.defaultSourceLanguage,
    required this.defaultTargetLanguage,
  });
}
