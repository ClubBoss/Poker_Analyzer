import 'dart:io';
import 'package:path/path.dart' as p;
import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';

/// Injects short theory spots into Level II training packs.
class TheoryPackSeederLevel2 {
  /// Mapping from tag to lesson title and explanation.
  final Map<String, Map<String, String>> templates;
  final YamlReader reader;
  final YamlWriter writer;

  const TheoryPackSeederLevel2({
    Map<String, Map<String, String>>? templates,
    this.reader = const YamlReader(),
    this.writer = const YamlWriter(),
  }) : templates = templates ?? _defaultTemplates;

  /// Scans [dir] for YAML packs and injects theory spots.
  /// Returns list of updated file paths.
  Future<List<String>> seed({String dir = 'assets/packs/v2'}) async {
    final directory = Directory(dir);
    if (!directory.existsSync()) return [];
    final files = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    final updated = <String>[];
    for (final file in files) {
      final map = reader.read(await file.readAsString());
      final tags = [for (final t in (map['tags'] as List? ?? [])) t.toString()];
      if (!tags.contains('level2')) continue;
      final lessons = <Map<String, String>>[];
      for (final t in tags) {
        if (t == 'level2') continue;
        final tpl = templates[t];
        if (tpl != null) {
          lessons.add({
            'tag': t,
            'title': tpl['title']!,
            'content': tpl['content']!,
          });
          if (lessons.length >= 2) break;
        }
      }
      if (lessons.isEmpty) continue;
      final spots = (map['spots'] as List? ?? []).cast<Map>();
      final packId =
          map['id']?.toString() ?? p.basenameWithoutExtension(file.path);
      final newSpots = <Map<String, dynamic>>[];
      for (var i = 0; i < lessons.length; i++) {
        final l = lessons[i];
        newSpots.add({
          'id': '${packId}_theory_${i + 1}',
          'type': 'theory',
          'title': l['title'],
          'explanation': l['content'],
          'tags': [l['tag']],
        });
      }
      map['spots'] = [...newSpots, ...spots];
      map['spotCount'] =
          (map['spotCount'] as int? ?? spots.length) + newSpots.length;
      final meta = Map<String, dynamic>.from(map['meta'] as Map? ?? {});
      meta['hasTheory'] = true;
      map['meta'] = meta;
      await writer.write(map, file.path);
      updated.add(file.path);
    }
    return updated;
  }
}

const Map<String, Map<String, String>> _defaultTemplates = {
  'openfold': {
    'title': 'Open/Fold Strategy Basics',
    'content': 'Tighten early positions and widen from late position.',
  },
  'open-fold': {
    'title': 'Open/Fold Strategy Basics',
    'content': 'Tighten early positions and widen from late position.',
  },
  '3bet-push': {
    'title': '3bet Push vs Open',
    'content': 'Shove strong hands over opens when short stacked.',
  },
  'callVsOpen': {
    'title': 'Call vs Open',
    'content': 'Defend with hands that play well postflop.',
  },
  'cbet': {
    'title': 'C-Bet Fundamentals',
    'content': 'Bet the flop frequently with range advantage.',
  },
  'check-raise': {
    'title': 'Check-Raise Tactics',
    'content': 'Use check-raises to apply pressure from out of position.',
  },
  'float': {
    'title': 'Turn Float Strategy',
    'content':
        'Call flop to take the pot on later streets when conditions are right.',
  },
  'donk': {
    'title': 'Donk Bet Insights',
    'content': 'Lead out from out of position on favourable boards.',
  },
};
