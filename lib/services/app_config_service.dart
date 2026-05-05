import 'package:shared_preferences/shared_preferences.dart';

class AppConfigService {
  static const String _backendBaseUrlKey = 'backendBaseUrl';
  static const String _translationPathKey = 'geminiTranslationPath';
  static const String _geminiModelKey = 'geminiModel';
  static const String _defaultSourceLangKey = 'defaultSourceLanguage';
  static const String _defaultTargetLangKey = 'defaultTargetLanguage';

  static const String defaultBackendBaseUrl = 'http://localhost:5000';
  static const String defaultTranslationPath = '/api/translation/gemini';
  static const String defaultGeminiModel = 'gemini-1.5-flash';
  static const String defaultSourceLanguage = 'auto';
  static const String defaultTargetLanguage = 'en';

  static Future<AppConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppConfig(
      backendBaseUrl:
          prefs.getString(_backendBaseUrlKey) ?? defaultBackendBaseUrl,
      geminiTranslationPath:
          prefs.getString(_translationPathKey) ?? defaultTranslationPath,
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
