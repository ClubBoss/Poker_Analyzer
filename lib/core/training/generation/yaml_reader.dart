import 'dart:convert';
import 'package:yaml/yaml.dart';

class YamlReader {
  const YamlReader();

  Map<String, dynamic> read(String source) {
    final doc = loadYaml(source);
    return jsonDecode(jsonEncode(doc)) as Map<String, dynamic>;
  }
}
