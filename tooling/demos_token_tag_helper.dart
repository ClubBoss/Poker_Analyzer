// Infer and add demo "tokens" tags to help token-sanity.
// Usage:
//   dart run tooling/demos_token_tag_helper.dart [--module <id>] [--demo <id>] [--force-token <tok>] [--force-tokens <t1,t2>] [--list-failing] [--fix-dry-run] [--fix] [--quiet]
//
// Scans content/<module>/v1/demos.jsonl. For each demo missing "tokens" and failing
// token-sanity (no known tokens in any string field), infer 1–2 tokens from the
// module's drills (targets frequency) and add as `"tokens": [ ... ]` when unambiguous.
// Deterministic, ASCII-only, idempotent.

import 'dart:convert';
import 'dart:io';

const Set<String> _KNOWN = {
  'small_cbet_33',
  'half_pot_50',
  'big_bet_75',
  'probe_turns',
  'delay_turn',
  'double_barrel_good',
  'triple_barrel_scare',
  'call',
  'fold',
  'overfold_exploit',
};

void main(List<String> args) {
  String? onlyModule;
  String? onlyDemoId;
  var fix = false;
  var dry = false;
  var quiet = false;
  final forced = <String>[];
  var listFailing = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--module' && i + 1 < args.length) {
      onlyModule = args[++i];
    } else if (a == '--demo' && i + 1 < args.length) {
      onlyDemoId = args[++i];
    } else if (a == '--force-token' && i + 1 < args.length) {
      final t = args[++i];
      if (_KNOWN.contains(t)) forced.add(t);
    } else if (a == '--force-tokens' && i + 1 < args.length) {
      final list = args[++i]
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      for (final t in list) {
        if (_KNOWN.contains(t)) forced.add(t);
      }
    } else if (a == '--list-failing') {
      listFailing = true;
    } else if (a == '--fix') {
      fix = true;
    } else if (a == '--fix-dry-run') {
      dry = true;
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final modules = _discoverModules(onlyModule);
  var modulesTouched = 0;
  var edited = 0;
  var skipped = 0;
  var unsure = 0;
  var ioError = false;

  final failingMap = <String, List<String>>{}; // module -> demo ids

  for (final m in modules) {
    final base = 'content/$m/v1';
    final demosPath = '$base/demos.jsonl';
    final drillsPath = '$base/drills.jsonl';
    final demosFile = File(demosPath);
    if (!demosFile.existsSync()) continue;
    modulesTouched++;

    // Build frequency from drills targets
    final freq = <String, int>{};
    final drillsFile = File(drillsPath);
    if (drillsFile.existsSync()) {
      for (final line in drillsFile.readAsLinesSync()) {
        final s = line.trim();
        if (s.isEmpty) continue;
        try {
          final obj = jsonDecode(s);
          if (obj is Map<String, dynamic>) {
            final t = obj['target'];
            final ts = obj['targets'];
            void addTok(String x) {
              if (_KNOWN.contains(x)) {
                freq[x] = (freq[x] ?? 0) + 1;
              }
            }

            if (t is String) addTok(t);
            if (t is List) {
              for (final v in t) if (v is String) addTok(v);
            }
            if (ts is List) {
              for (final v in ts) if (v is String) addTok(v);
            }
          }
        } catch (_) {}
      }
    }

    // Sort tokens by frequency desc then name asc
    final ranked = freq.keys.toList()
      ..sort((a, b) {
        final d = (freq[b] ?? 0).compareTo(freq[a] ?? 0);
        if (d != 0) return d;
        return a.compareTo(b);
      });

    final lines = demosFile.readAsLinesSync();
    final newLines = <String>[];
    var fileEdited = false;

    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final s = raw.trim();
      if (s.isEmpty) {
        newLines.add(raw);
        continue;
      }
      Map<String, dynamic>? obj;
      try {
        obj = jsonDecode(s) as Map<String, dynamic>;
      } catch (_) {
        // keep as-is
        newLines.add(raw);
        continue;
      }

      final id = (obj['id'] is String) ? (obj['id'] as String) : '';
      final hasTokens = obj.containsKey('tokens');
      final passesSanity = hasTokens
          ? _tokensListHasKnown(obj['tokens'])
          : _objectHasKnown(obj);

      if (!passesSanity) {
        // Track failing for listing
        if (id.isNotEmpty) {
          (failingMap[m] ??= <String>[]).add(id);
        }
      }

      if (passesSanity) {
        skipped++;
        newLines.add(raw);
        continue;
      }

      // Fails sanity; try force first if requested
      List<String> toApply = const [];
      if (forced.isNotEmpty && (onlyDemoId == null || id == onlyDemoId)) {
        // Prepare tokens: keep input order, dedupe, known only
        final seen = <String>{};
        final ft = <String>[];
        for (final t in forced) {
          if (_KNOWN.contains(t) && seen.add(t)) ft.add(t);
        }
        toApply = ft;
      } else {
        // Need to infer
        toApply = _inferTokens(ranked, freq);
      }

      if (toApply.isEmpty) {
        unsure++;
        newLines.add(raw);
        continue;
      }

      // Merge into existing or create tokens
      final current = <String>[];
      final tv = obj['tokens'];
      if (tv is List) {
        for (final e in tv) {
          if (e is String) current.add(e);
        }
      }
      var changed = false;
      for (final t in toApply) {
        if (!current.contains(t)) {
          current.add(t);
          changed = true;
        }
      }

      if (!changed) {
        // Nothing to do
        newLines.add(raw);
        skipped++;
        continue;
      }

      if (dry && !quiet) {
        // silent per spec
      }
      obj['tokens'] = current;
      final enc = jsonEncode(obj);
      newLines.add(enc);
      fileEdited = true;
      edited++;
    }

    if (fix && fileEdited) {
      try {
        demosFile.writeAsStringSync(newLines.join('\n'));
      } catch (e) {
        if (!quiet) stderr.writeln('write error: $demosPath: $e');
        ioError = true;
      }
    }
  }

  if (listFailing && !quiet) {
    final keys = failingMap.keys.toList()..sort();
    for (final k in keys) {
      final ids = failingMap[k]!..sort();
      stdout.writeln('FAIL ${k}: ' + ids.join(','));
    }
  }

  stdout.writeln(
    'DEMO-TOKENS modules=$modulesTouched edited=$edited skipped=$skipped unsure=$unsure',
  );
  if (ioError) exitCode = 1;
}

bool _tokensListHasKnown(dynamic v) {
  if (v is! List) return false;
  for (final e in v) {
    if (e is String && _KNOWN.contains(e)) return true;
  }
  return false;
}

bool _objectHasKnown(Map<String, dynamic> obj) {
  bool scan(dynamic v) {
    if (v is String) {
      for (final t in _KNOWN) {
        if (v.contains(t)) return true;
      }
      return false;
    } else if (v is List) {
      for (final e in v) {
        if (scan(e)) return true;
      }
      return false;
    } else if (v is Map) {
      for (final e in v.values) {
        if (scan(e)) return true;
      }
      return false;
    }
    return false;
  }

  for (final e in obj.entries) {
    if (scan(e.value)) return true;
  }
  return false;
}

List<String> _inferTokens(List<String> ranked, Map<String, int> freq) {
  if (ranked.isEmpty) return const <String>[];
  final top = ranked[0];
  final topC = freq[top] ?? 0;
  if (ranked.length == 1) return <String>[top];
  final second = ranked[1];
  final secondC = freq[second] ?? 0;
  if (topC > secondC) return <String>[top];
  // two-way tie qualifies; if more than two share top count, unsure
  if (ranked.length >= 3) {
    final third = ranked[2];
    final thirdC = freq[third] ?? 0;
    if (thirdC == topC) return const <String>[]; // ambiguous 3+ way tie
  }
  return <String>[top, second];
}

List<String> _discoverModules(String? only) {
  final root = Directory('content');
  if (!root.existsSync()) return <String>[];
  final out = <String>[];
  for (final e in root.listSync()) {
    if (e is! Directory) continue;
    final id = _basename(e.path);
    if (id.isEmpty || id.startsWith('_')) continue;
    if (only != null && id != only) continue;
    final v1 = Directory('${e.path}/v1');
    if (v1.existsSync()) out.add(id);
  }
  out.sort();
  return out;
}

String _basename(String path) {
  final norm = path.replaceAll('\\', '/');
  var s = norm;
  if (s.endsWith('/')) s = s.substring(0, s.length - 1);
  final idx = s.lastIndexOf('/');
  return idx == -1 ? s : s.substring(idx + 1);
}
