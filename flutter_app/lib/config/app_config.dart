import 'package:flutter/foundation.dart';

class AppConfig {
  // ── Deployed backend URL ──
  // After deploying backend to Render, paste the URL here.
  // Example: https://healthcare-ai-backend.onrender.com
  static const String _deployedUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '', // leave empty until deployed; falls back to local URLs below
  );

  static String get baseUrl {
    // If a deployed URL is provided (production build), always use it
    if (_deployedUrl.isNotEmpty) return _deployedUrl;

    // Otherwise auto-detect for local development
    if (kIsWeb) return 'http://localhost:8000';

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000'; // Android emulator
      // For physical device on same WiFi, replace with:
      // return 'http://192.168.x.x:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost:8000'; // iOS simulator
    }

    return 'http://localhost:8000';
  }

  static const String apiVersion = '/api/v1';
  static String get apiBase => '$baseUrl$apiVersion';

  static String get chatEndpoint    => '$apiBase/chat';
  static String get ingestEndpoint  => '$apiBase/ingest';
  static String get healthEndpoint  => '$apiBase/health';

  static const String appName               = 'HealthAI Assistant';
  static const int    requestTimeoutSeconds  = 60;
}
