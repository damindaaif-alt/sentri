abstract class AppConstants {
  static const String appName = 'Sentri';
  static const String appVersion = '1.0.0';
  static const String baseUrl = 'https://api.sentri.app/v1';

  // Risk score thresholds
  static const int riskScoreLow = 30;
  static const int riskScoreMedium = 60;
  static const int riskScoreHigh = 80;

  // Cache TTL in minutes
  static const int callerCacheTtlMinutes = 60;
  static const int threatFeedCacheTtlMinutes = 30;

  // Local DB
  static const String dbName = 'sentri.db';
  static const int dbVersion = 1;

  // Secure storage keys
  static const String keyAuthToken = 'auth_token';
  static const String keyDeviceId = 'device_id';
  static const String keyOnboardingComplete = 'onboarding_complete';
}

abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String callLog = '/call-log';
  static const String blocklist = '/blocklist';
  static const String numberLookup = '/lookup';
  static const String settings = '/settings';
  static const String callerDetail = '/caller/:number';
  static const String threatFeed = '/threats';
}
