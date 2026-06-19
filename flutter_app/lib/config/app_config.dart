class AppConfig {
  // Change this to your deployed backend URL in production
  // For local dev on Android emulator use: http://10.0.2.2:8000
  // For local dev on iOS simulator use: http://localhost:8000
  // For physical device on same WiFi: http://YOUR_PC_IP:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // Android emulator default
  );

  static const String apiVersion = '/api/v1';
  static String get apiBase => '$baseUrl$apiVersion';

  // Endpoints
  static String get chatEndpoint => '$apiBase/chat';
  static String get ingestEndpoint => '$apiBase/ingest';
  static String get healthEndpoint => '$apiBase/health';

  // App settings
  static const String appName = 'HealthAI Assistant';
  static const int requestTimeoutSeconds = 60; // LLM can be slow
}
