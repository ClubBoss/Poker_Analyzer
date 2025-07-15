import 'dart:io';
import 'package:yaml/yaml.dart';

class YamlWriter {
  const YamlWriter();

  Future<void> write(Object data, String path) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(const YamlEncoder().convert(data));
  }
}
