import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Shared authenticated client for WiseSell's Cloudflare AI Worker.
class WiseSellAiService {
  WiseSellAiService._();

  static const _baseUrl = String.fromEnvironment(
    'WISESELL_API_BASE_URL',
    defaultValue: 'https://wise-sell-ai-app2.abdico-veiws22.workers.dev',
  );

  // Map the app's UI categories to the agent IDs actually exposed by the Worker.
  static const Map<String, String> _workerAgentIds = {
    'business': 'business-assistant',
    'marketing': 'digital-marketing',
    'content': 'seo-content',
    'seo': 'seo-content',
    'social': 'social-media',
    'video': 'video-audio',
    // Inventory advice is handled by the business assistant until a dedicated
    // inventory agent is added to the Worker.
    'inventory': 'business-assistant',
  };

  static Future<String> generate({
    required String agent,
    required String prompt,
    String language = 'English',
    String businessContext = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const WiseSellAiException('Please sign in to use WiseSell AI.');
    }

    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw const WiseSellAiException('Your sign-in session expired. Please sign in again.');
    }

    final workerAgentId = _workerAgentIds[agent];
    if (workerAgentId == null) {
      throw const WiseSellAiException('This WiseSell AI agent is not configured yet.');
    }

    final enrichedMessage = [
      'Please respond in $language.',
      if (businessContext.trim().isNotEmpty) 'Business context: ${businessContext.trim()}',
      if (agent == 'inventory') 'Focus on inventory levels, stock movement, reorder priorities and stockout risks.',
      'User request: ${prompt.trim()}',
    ].join('\n\n');

    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/api/agents/$workerAgentId'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': enrichedMessage}),
      ).timeout(const Duration(seconds: 55));
    } on Exception {
      throw const WiseSellAiException(
        'Could not connect to WiseSell AI. Check your internet connection and try again.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const WiseSellAiException(
        'The AI service returned an invalid response. The server configuration needs checking.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const WiseSellAiException('The AI service returned an unexpected response format.');
    }

    if (response.statusCode != 200) {
      final message = decoded['error'] is String
          ? decoded['error'] as String
          : 'WiseSell AI could not complete your request.';
      if (response.statusCode == 401) {
        throw const WiseSellAiException('Please sign in again to continue.');
      }
      if (response.statusCode == 404) {
        throw const WiseSellAiException('The requested AI agent route was not found on the Worker.');
      }
      if (response.statusCode == 503) {
        throw const WiseSellAiException('AI capacity is temporarily unavailable. Please try again later.');
      }
      throw WiseSellAiException(message);
    }

    final answer = decoded['answer'];
    if (answer is! String || answer.trim().isEmpty) {
      throw const WiseSellAiException('The AI service did not return any answer text.');
    }
    return answer.trim();
  }
}

class WiseSellAiException implements Exception {
  const WiseSellAiException(this.message);
  final String message;

  @override
  String toString() => message;
}
