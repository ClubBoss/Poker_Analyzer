import 'dart:io';
import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

Set<String> _collectTags(String root) {
  final dir = Directory(root);
  if (!dir.existsSync()) return {};
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.yaml'));
  final tags = <String>{};
  for (final f in files) {
    dynamic doc;
    try {
      doc = loadYaml(f.readAsStringSync());
    } catch (_) {
      continue;
    }
    final list = (doc['tags'] as YamlList?)?.cast() ?? const [];
    for (final t in list) {
      if (t is String && t != 'l2') {
        tags.add(t);
      }
    }
  }
  return tags;
}

Map<String, dynamic> _loadSnippets(String path) {
  final file = File(path);
  if (!file.existsSync()) return {};
  final data = loadYaml(file.readAsStringSync());
  if (data is YamlMap) {
    return Map<String, dynamic>.from(data);
  }
  return {};
}

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('packs', defaultsTo: 'assets/packs/l2')
    ..addOption('snippets', defaultsTo: 'assets/theory/l2/snippets.yaml')
    ..addOption('min', defaultsTo: '0.90');
  final opts = parser.parse(args);
  final packs = opts['packs'] as String;
  final snippetsPath = opts['snippets'] as String;
  final min = double.tryParse(opts['min'] as String) ?? 0.90;

  final tags = _collectTags(packs);
  final snippets = _loadSnippets(snippetsPath).keys.cast<String>().toSet();
  final covered = tags.intersection(snippets).length;
  final coverage = tags.isEmpty ? 1.0 : covered / tags.length;
  final missing = tags.difference(snippets);
  for (final tag in missing) {
    stderr.writeln('::error file=$snippetsPath::missing snippet for tag $tag');
  }
  stdout.writeln(
      'coverage ${(coverage * 100).toStringAsFixed(1)}% ($covered/${tags.length})');
  if (coverage < min) {
    exit(1);
  }
}
