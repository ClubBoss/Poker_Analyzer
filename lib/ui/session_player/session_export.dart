import 'dart:convert';
import 'dart:io';
import 'models.dart';

/// Build a deterministic JSON summary for the last session.
String buildSessionJson({
  required List<UiSpot> spots,
  required List<UiAnswer> answers,
}) {
  final items = <Map<String, dynamic>>[];
  final n = answers.length.clamp(0, spots.length);
  for (var i = 0; i < n; i++) {
    final s = spots[i];
    final a = answers[i];
    items.add({
      'i': i + 1,
      'hand': s.hand,
      'pos': s.pos,
      'vsPos': s.vsPos,
      'stack': s.stack,
      'action_expected': a.expected,
      'action_chosen': a.chosen,
      'correct': a.correct,
      'elapsed_ms': a.elapsed.inMilliseconds,
      'explain': s.explain,
    });
  }
  final root = {
    'version': 'v1',
    'count': items.length,
    'correct': items.where((e) => e['correct'] == true).length,
    'data': items,
  };
  return const JsonEncoder.withIndent('  ').convert(root);
}

/// Save to a fixed, deterministic path; returns the file path.
Future<String> saveSessionJson(String json,
    {String path = 'out/last_session_summary.json'}) async {
  final f = File(path);
  await f.parent.create(recursive: true);
  await f.writeAsString(json);
  return f.path;
}
