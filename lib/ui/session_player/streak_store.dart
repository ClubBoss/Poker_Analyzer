import 'dart:convert';
import 'dart:io';

class Streak {
  final int count;
  final String last;
  const Streak(this.count, this.last);
  Map<String, dynamic> toJson() => {
    'version': 'v1',
    'count': count,
    'last': last,
  };
  static Streak fromJson(Map m) {
    final c = m['count'] is int ? m['count'] as int : 0;
    final l = m['last'] is String ? m['last'] as String : '';
    return Streak(c, l);
  }
}

Future<Streak> loadStreak({String path = 'out/plan/streak_v1.json'}) async {
  final f = File(path);
  if (!await f.exists()) return const Streak(0, '');
  try {
    final root = jsonDecode(await f.readAsString());
    if (root is Map) return Streak.fromJson(root);
  } catch (_) {}
  return const Streak(0, '');
}

Future<void> saveStreak(
  Streak s, {
  String path = 'out/plan/streak_v1.json',
}) async {
  final f = File(path);
  await f.parent.create(recursive: true);
  final json = const JsonEncoder.withIndent('  ').convert(s.toJson());
  await f.writeAsString(json);
}

String today() {
  final now = DateTime.now();
  final d = DateTime(now.year, now.month, now.day);
  return d.toIso8601String().split('T').first;
}

bool isYesterday(String a, String b) {
  try {
    final da = DateTime.parse(a);
    final db = DateTime.parse(b);
    final y = DateTime(
      db.year,
      db.month,
      db.day,
    ).subtract(const Duration(days: 1));
    final na = DateTime(da.year, da.month, da.day);
    return na == y;
  } catch (_) {
    return false;
  }
}

Streak bumpIfNeeded(Streak s) {
  final t = today();
  if (s.last == t) return s;
  if (isYesterday(s.last, t)) return Streak(s.count + 1, t);
  return Streak(1, t);
}
