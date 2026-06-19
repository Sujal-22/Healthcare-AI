import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/message.dart';

class ChatService {
  final http.Client _client = http.Client();

  /// Send message to RAG backend, get AI answer
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String sessionId,
    int topK = 3,
  }) async {
    final response = await _client
        .post(
      Uri.parse(AppConfig.chatEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'session_id': sessionId,
        'top_k': topK,
      }),
    )
        .timeout(
      const Duration(seconds: AppConfig.requestTimeoutSeconds),
      onTimeout: () => throw Exception('Request timed out. Ollama may be slow — try again.'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final sources = (data['sources'] as List<dynamic>? ?? [])
          .map((s) => SourceDocument.fromJson(s as Map<String, dynamic>))
          .toList();
      return {
        'answer': data['answer'] as String,
        'sources': sources,
      };
    } else if (response.statusCode == 503) {
      throw Exception('Health data not loaded. Please ingest data first.');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Unknown server error');
    }
  }

  /// Check backend + Ollama health
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse(AppConfig.healthEndpoint))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'status': 'error', 'ollama_connected': false, 'vector_db_ready': false};
    } catch (_) {
      return {'status': 'unreachable', 'ollama_connected': false, 'vector_db_ready': false};
    }
  }

  /// Trigger data ingestion
  Future<Map<String, dynamic>> ingestData({bool forceReload = false}) async {
    final response = await _client
        .post(
      Uri.parse(AppConfig.ingestEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'force_reload': forceReload}),
    )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Ingest failed');
    }
  }

  void dispose() => _client.close();
}
