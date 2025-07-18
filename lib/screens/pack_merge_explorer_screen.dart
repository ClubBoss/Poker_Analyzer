import 'dart:io';
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
  State<PackMergeExplorerScreen> createState() => _PackMergeExplorerScreenState();
}

class _PackMergeExplorerScreenState extends State<PackMergeExplorerScreen> {
  bool _loading = true;
  final List<_Candidate> _items = [];

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
                ElevatedButton(onPressed: _load, child: const Text('🔄 Обновить')),
                const SizedBox(height: 16),
                for (final c in _items)
                  ExpansionTile(
                    tileColor: c.overlap > 0.5
                        ? Colors.green.withOpacity(.2)
                        : null,
                    title: Text('${c.a.name} ↔ ${c.b.name}'),
                    subtitle: Text(
                        'score ${c.score.toStringAsFixed(2)}, overlap ${(c.overlap * 100).toStringAsFixed(0)}%'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${c.a.type.name}'),
                            if (c.sameTitle) const Text('Same title'),
                            if (c.commonTags.isNotEmpty)
                              Text('Tags: ${c.commonTags.join(', ')}'),
                            if (c.sameBlind && c.blind != null)
                              Text('Blind: ${c.blind}'),
                            TextButton(
                              onPressed: () => _openDiff(c),
                              child: const Text('Diff'),
                            ),
                          ],
                        ),
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

Future<List<_Candidate>> _exploreTask(String _) async {
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
      packs.add(TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map)));
    } catch (_) {}
  }
  final out = <_Candidate>[];
  for (var i = 0; i < packs.length; i++) {
    final a = packs[i];
    for (var j = i + 1; j < packs.length; j++) {
      final b = packs[j];
      final res = _compare(a, b);
      if (res['score'] >= 2 || res['overlap'] > 0.5) {
        out.add(_Candidate(
          a: a,
          b: b,
          score: res['score'],
          overlap: res['overlap'],
          sameTitle: res['sameTitle'],
          sameBlind: res['sameBlind'],
          blind: res['blind'],
          commonTags: List<String>.from(res['commonTags']),
        ));
      }
    }
  }
  out.sort((a, b) => b.score.compareTo(a.score));
  return out;
}

Map<String, dynamic> _compare(TrainingPackTemplateV2 a, TrainingPackTemplateV2 b) {
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
