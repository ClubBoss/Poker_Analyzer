import 'dart:convert';
import 'package:http/http.dart' as http;

import 'yaml_reader.dart';

class GptPackTemplateGenerator {
  final String apiKey;
  final http.Client client;
  final YamlReader reader;
  static const _url = 'https://api.openai.com/v1/chat/completions';

  const GptPackTemplateGenerator({
    required this.apiKey,
    http.Client? client,
    YamlReader? yamlReader,
  })  : client = client ?? const http.Client(),
        reader = yamlReader ?? const YamlReader();

  Future<String> generateYamlTemplate(String prompt) async {
    final res = await client.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );
    if (res.statusCode != 200) return '';
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    var text =
        (map['choices'] as List).first['message']['content']?.toString() ?? '';
    text = _cleanup(text);
    try {
      reader.read(text);
      return text;
    } catch (_) {
      return '';
    }
  }

  String _cleanup(String text) {
    var out = text.trim();
    if (out.startsWith('```')) {
      final end = out.lastIndexOf('```');
      if (end > 0) {
        out = out.substring(3, end);
      } else {
        out = out.substring(3);
      }
    }
    if (out.startsWith('yaml')) {
      out = out.substring(4);
    }
    return out.trim();
  }
}
