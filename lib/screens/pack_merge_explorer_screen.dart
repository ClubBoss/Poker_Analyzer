import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';
import 'pack_library_diff_screen.dart';

class PackMergeExplorerScreen extends StatefulWidget {
  const PackMergeExplorerScreen({super.key});
  @override
  State<PackMergeExplorerScreen> createState() =>
      _PackMergeExplorerScreenState();
}

class _PackMergeExplorerScreenState extends State<PackMergeExplorerScreen> {
  bool _loading = true;
  final List<_Group> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await compute(_exploreTask, '');
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(data);
      _loading = false;
    });
  }

  void _openDiff(_Candidate c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PackLibraryDiffScreen(packA: c.a, packB: c.b),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Pack Merge Explorer')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('🔄 Обновить'),
                ),
                const SizedBox(height: 16),
                for (final g in _items)
                  ExpansionTile(
                    title: Text(g.title),
                    children: [
                      for (final c in g.pairs)
                        ListTile(
                          tileColor: c.overlap > 0.5
                              ? Colors.green.withValues(alpha: .2)
                              : null,
                          title: Text('${c.a.name} ↔ ${c.b.name}'),
                          subtitle: Text(
                            'score ${c.score.toStringAsFixed(2)}, overlap ${(c.overlap * 100).toStringAsFixed(0)}%',
                          ),
                          onTap: () => _openDiff(c),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _Candidate {
  final TrainingPackTemplateV2 a;
  final TrainingPackTemplateV2 b;
  final double score;
  final double overlap;
  final bool sameTitle;
  final bool sameBlind;
  final String? blind;
  final List<String> commonTags;
  _Candidate({
    required this.a,
    required this.b,
    required this.score,
    required this.overlap,
    required this.sameTitle,
    required this.sameBlind,
    required this.blind,
    required this.commonTags,
  });
}

class _Group {
  final String title;
  final List<_Candidate> pairs;
  _Group({required this.title, required this.pairs});
  double get maxScore => pairs.fold<double>(0, (p, e) => math.max(p, e.score));
}

Future<List<_Group>> _exploreTask(String _) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/training_packs/library');
  if (!dir.existsSync()) return [];
  const reader = YamlReader();
  final packs = <TrainingPackTemplateV2>[];
  for (final f in dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
    try {
      final map = reader.read(await f.readAsString());
      packs.add(
        TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map)),
      );
    } catch (_) {}
  }
  final pairs = <_Candidate>[];
  for (var i = 0; i < packs.length; i++) {
    final a = packs[i];
    for (var j = i + 1; j < packs.length; j++) {
      final b = packs[j];
      final res = _compare(a, b);
      if (res['score'] >= 2 || res['overlap'] > 0.5) {
        pairs.add(
          _Candidate(
            a: a,
            b: b,
            score: res['score'],
            overlap: res['overlap'],
            sameTitle: res['sameTitle'],
            sameBlind: res['sameBlind'],
            blind: res['blind'],
            commonTags: List<String>.from(res['commonTags']),
          ),
        );
      }
    }
  }
  pairs.sort((a, b) => b.score.compareTo(a.score));
  final groups = <String, _Group>{};
  for (final c in pairs) {
    final key = _groupKey(c);
    final g = groups.putIfAbsent(key, () => _Group(title: key, pairs: []));
    g.pairs.add(c);
  }
  final list = groups.values.toList();
  list.sort((a, b) => b.maxScore.compareTo(a.maxScore));
  return list;
}

Map<String, dynamic> _compare(
  TrainingPackTemplateV2 a,
  TrainingPackTemplateV2 b,
) {
  final sameType = a.type == b.type;
  final sameTitle = a.name.trim().toLowerCase() == b.name.trim().toLowerCase();
  final tagsA = a.tags.toSet();
  final tagsB = b.tags.toSet();
  final commonTags = tagsA.intersection(tagsB).toList();
  final configA = (a.meta['config'] as Map?)?.cast<String, dynamic>();
  final configB = (b.meta['config'] as Map?)?.cast<String, dynamic>();
  final blindA = configA?['blindLevel'] ?? configA?['bb'];
  final blindB = configB?['blindLevel'] ?? configB?['bb'];
  final sameBlind = blindA != null && blindA == blindB;
  final overlap = _spotOverlap(a.spots, b.spots);
  var score = overlap;
  if (sameType) score += 1;
  if (sameTitle) score += 1;
  if (commonTags.isNotEmpty) {
    final maxTags = tagsA.length > tagsB.length ? tagsA.length : tagsB.length;
    score += commonTags.length / maxTags;
  }
  if (sameBlind) score += 1;
  return {
    'score': score,
    'overlap': overlap,
    'sameTitle': sameTitle,
    'sameBlind': sameBlind,
    'blind': sameBlind ? blindA?.toString() : null,
    'commonTags': commonTags,
  };
}

double _spotOverlap(List<dynamic> a, List<dynamic> b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final setA = {for (final s in a) _spotKey(s)};
  final setB = {for (final s in b) _spotKey(s)};
  final minLen = setA.length < setB.length ? setA.length : setB.length;
  var common = 0;
  for (final k in setA) {
    if (setB.contains(k)) common++;
  }
  if (minLen == 0) return 0;
  return common / minLen;
}

String _groupKey(_Candidate c) {
  final parts = <String>[c.a.type.name];
  if (c.sameTitle) parts.add(c.a.name);
  if (c.commonTags.isNotEmpty) parts.add(c.commonTags.join(', '));
  if (c.sameBlind && c.blind != null) parts.add('BB ${c.blind}');
  return parts.join(' | ');
}

String _spotKey(dynamic s) {
  if (s is Map) {
    final map = Map<String, dynamic>.from(s)
      ..remove('editedAt')
      ..remove('createdAt')
      ..remove('evalResult')
      ..remove('correctAction')
      ..remove('explanation');
    return map.toString();
  }
  return s.toString();
}
