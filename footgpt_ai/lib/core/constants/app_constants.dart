abstract final class AppConstants {
  static const appName = 'FootGPT AI';
  static const appTagline = 'Premium football intelligence';

  /// Injected at build time with `--dart-define=API_BASE_URL=...`.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);
}
