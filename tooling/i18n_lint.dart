// Lint RU/EN i18n files for quality gates.
// Usage:
//   dart run tooling/i18n_lint.dart
// Inputs: build/i18n/en.json, build/i18n/ru.json
// Output: build/i18n_lint.json and one-liner: I18N-LINT keys=<K> errors=<E> warns=<W>
// Exit non-zero if errors > 0. ASCII-only. No deps.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final outPath = 'build/i18n_lint.json';
  Directory('build').createSync(recursive: true);

  final enFile = File('build/i18n/en.json');
  final ruFile = File('build/i18n/ru.json');
  if (!enFile.existsSync() || !ruFile.existsSync()) {
    final empty = {
      'rows': [],
      'summary': {'keys': 0, 'errors': 0, 'warns': 0}
    };
    File(outPath).writeAsStringSync(jsonEncode(empty));
    stdout.writeln('I18N-LINT keys=0 errors=0 warns=0');
    return;
  }

  Map<String, dynamic> en;
  Map<String, dynamic> ru;
  try {
    en = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
    ru = jsonDecode(ruFile.readAsStringSync()) as Map<String, dynamic>;
  } catch (_) {
    final empty = {
      'rows': [],
      'summary': {'keys': 0, 'errors': 1, 'warns': 0}
    };
    File(outPath).writeAsStringSync(jsonEncode(empty));
    stdout.writeln('I18N-LINT keys=0 errors=1 warns=0');
    exitCode = 1;
    return;
  }

  final keys = en.keys.toList()..sort();
  final rows = <Map<String, dynamic>>[];
  int errorCount = 0;
  int warnCount = 0;

  final glossary = <String>{
    'Fv50',
    'Fv75',
    'probe_turns',
    'small_cbet_33',
    'half_pot_50',
    'big_bet_75',
  };

  for (final k in keys) {
    final issues = <String>[];
    final ev = _val(en[k]);
    final rv = ru.containsKey(k) ? _val(ru[k]) : '';

    if (!ru.containsKey(k)) {
      issues.add('no_ru');
    }

    // no-English-in-RU: flag if RU contains any exact English words from EN
    if (rv.isNotEmpty) {
      final enWords = _englishWords(ev);
      final rvLower = rv.toLowerCase();
      for (final w in enWords) {
        if (rvLower.contains(w)) {
          issues.add('english_leftover');
          break;
        }
      }
    }

    // no-transliteration: RU ASCII-only
    if (rv.isNotEmpty && _isAsciiOnly(rv)) {
      issues.add('ascii_translit');
    }

    // placeholders safe
    final enPlace = _placeholders(ev);
    final ruPlace = _placeholders(rv);
    if (!_multisetEquals(enPlace, ruPlace)) {
      issues.add('placeholder_mismatch');
    }

    // glossary rules: tokens present in EN must be verbatim in RU
    for (final t in glossary) {
      if (ev.contains(t) && !rv.contains(t)) {
        issues.add('glossary_violation');
        break;
      }
    }

    // length hint: RU > 1.6x EN
    if (rv.isNotEmpty && ev.isNotEmpty && rv.length > (ev.length * 1.6)) {
      issues.add('length_warn');
      warnCount++;
    }

    // Count errors (non-warn issues)
    final errsHere = issues.where((i) => i != 'length_warn').length;
    errorCount += errsHere;

    rows.add({'key': k, 'issues': issues});
  }

  final payload = {
    'rows': rows,
    'summary': {'keys': keys.length, 'errors': errorCount, 'warns': warnCount}
  };
  File(outPath).writeAsStringSync(jsonEncode(payload));
  stdout.writeln(
      'I18N-LINT keys=${keys.length} errors=$errorCount warns=$warnCount');
  if (errorCount > 0) exitCode = 1;
}

String _val(dynamic v) => (v is String) ? v : '';

bool _isAsciiOnly(String s) {
  for (final cu in s.codeUnits) {
    if (cu > 0x7F) return false;
  }
  return true;
}

// Lowercased English words (letters only) from EN string
Set<String> _englishWords(String s) {
  final re = RegExp(r'[A-Za-z]{2,}');
  return re
      .allMatches(s)
      .map((m) => s.substring(m.start, m.end).toLowerCase())
      .toSet();
}

// Collect placeholders as multiset list for comparison
List<String> _placeholders(String s) {
  final out = <String>[];
  final reCurly = RegExp(r'\{[A-Za-z0-9_]+\}');
  final rePrintf = RegExp(r'%[sd]');
  out.addAll(reCurly.allMatches(s).map((m) => s.substring(m.start, m.end)));
  out.addAll(rePrintf.allMatches(s).map((m) => s.substring(m.start, m.end)));
  out.sort(); // deterministic
  return out;
}

bool _multisetEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

