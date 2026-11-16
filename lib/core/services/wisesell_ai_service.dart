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

    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/v1/agent'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'agent': agent,
          'prompt': prompt,
          'language': language,
          'businessContext': businessContext,
        }),
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
        throw const WiseSellAiException('The AI endpoint is not available on the configured Worker.');
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
