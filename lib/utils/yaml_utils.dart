import 'package:yaml/yaml.dart';

/// Recursively converts [YamlMap] and [YamlList] into plain Dart [Map]s and [List]s.
///
/// Other values are returned as-is.
dynamic yamlToDart(dynamic node) {
  if (node is YamlMap) {
    return {
      for (final entry in node.entries)
        entry.key.toString(): yamlToDart(entry.value),
    };
  }
  if (node is YamlList) {
    return [for (final value in node) yamlToDart(value)];
  }
  return node;
}
