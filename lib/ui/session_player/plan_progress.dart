import 'dart:convert';
import 'dart:io';

class PlanProgress {
  final Map<String, bool> done; // id -> true
  const PlanProgress(this.done);
  Map<String, dynamic> toJson() => {'version':'v1','done':done};
  static PlanProgress fromJson(Map<String,dynamic> m) {
    final d = <String,bool>{};
    final raw = m['done'];
    if (raw is Map) {
      for (final e in raw.entries) {
        if (e.value is bool) d['${e.key}'] = e.value as bool;
      }
    }
    return PlanProgress(d);
  }
}

Future<PlanProgress> loadPlanProgress({String path='out/plan/plan_progress_v1.json'}) async {
  final f = File(path);
  if (!await f.exists()) return const PlanProgress({});
  try {
    final root = jsonDecode(await f.readAsString());
    if (root is Map<String,dynamic>) return PlanProgress.fromJson(root);
  } catch (_) {}
  return const PlanProgress({});
}

Future<void> savePlanProgress(PlanProgress p, {String path='out/plan/plan_progress_v1.json'}) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  final json = const JsonEncoder.withIndent('  ').convert(p.toJson());
  await file.writeAsString(json);
}

PlanProgress markDone(PlanProgress p, String id, {bool done=true}) {
  final m = Map<String,bool>.from(p.done);
  m[id] = done;
  return PlanProgress(m);
}
