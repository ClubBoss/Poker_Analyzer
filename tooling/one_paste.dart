import 'dart:io';
import 'dart:convert';

const _researchPath = 'prompts/research/_ALL.prompts.txt';
const _dispatcherPath = 'prompts/dispatcher/_ALL.txt';

String _ascii(String s) {
  final b = StringBuffer();
  for (final c in s.codeUnits) {
    if (c == 0x0D) continue;
    b.writeCharCode(c <= 0x7F ? c : 0x3F);
  }
  return b.toString();
}

Map<String, String> _splitResearch(String raw) {
  final r = RegExp(r'^GO MODULE:\s+([a-z0-9_]+)\s*$', multiLine: true);
  final m = r.allMatches(raw).toList();
  if (m.isEmpty || m.first.start != 0) {
    throw const FormatException('parse research');
  }
  final out = <String, String>{};
  for (var i = 0; i < m.length; i++) {
    final id = m[i].group(1)!;
    final start = m[i].start;
    final end = (i + 1 < m.length) ? m[i + 1].start : raw.length;
    out[id] = raw.substring(start, end);
  }
  return out;
}

Map<String, String> _splitDispatcher(String raw) {
  final r = RegExp(r'^module_id:\s*([a-z0-9_]+)\s*$', multiLine: true);
  final m = r.allMatches(raw).toList();
  if (m.isEmpty || m.first.start != 0) {
    throw const FormatException('parse dispatcher');
  }
  final out = <String, String>{};
  for (var i = 0; i < m.length; i++) {
    final id = m[i].group(1)!;
    final start = m[i].start;
    final end = (i + 1 < m.length) ? m[i + 1].start : raw.length;
    out[id] = raw.substring(start, end);
  }
  return out;
}

String _coreContract(String id) {
  return _ascii('''
COVERAGE CONTRACT (must pass before output)
- Word count in theory.md: 450-550 words.
- Must include phrases/topics (case-insensitive):
  - Hand rankings
  - royal_flush
  - straight_flush
  - four_of_a_kind
  - full_house
  - flush
  - straight
  - three_of_a_kind
  - two_pair
  - one_pair
  - high_card
  - no suit priority
  - new_total - current_bet
  - last_raise_size
  - bettor_shows_first
  - first_active_left_of_btn_shows
- The mini example must use positions: UTG, MP, CO, BTN, SB, BB.
- demos.jsonl: 2-3 items. drills.jsonl: 12-16 items.
- INTERNAL QA LOOP: If any check fails, silently revise and re-run. Do NOT emit any output until all checks pass. When all pass, output ONLY the three files in exact paths for "$id".
''');
}

String _contractFor(String id) {
  final perId = File('tooling/coverage/${id}.must');
  if (perId.existsSync()) {
    return _ascii(perId.readAsStringSync());
  }
  if (id.startsWith('core_')) return _coreContract(id);
  // fallback minimal
  return _ascii('''
COVERAGE CONTRACT (must pass before output)
- theory.md: 450-550 words; demos.jsonl: 2-3 items; drills.jsonl: 12-16 items.
- INTERNAL QA LOOP: fix all failed checks before emitting any output.
''');
}

void main(List<String> args) {
  String? id;
  bool withIntro = false;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--id' && i + 1 < args.length) {
      id = args[++i];
    } else if (a == '--with-intro') {
      withIntro = true;
    } else {
      stderr.writeln(
        'usage: dart run tooling/one_paste.dart --id <module_id> [--with-intro]',
      );
      exit(2);
    }
  }
  if (id == null) {
    stderr.writeln('missing --id');
    exit(2);
  }

  try {
    final researchRaw = _ascii(File(_researchPath).readAsStringSync());
    final dispRaw = _ascii(File(_dispatcherPath).readAsStringSync());
    final research = _splitResearch(researchRaw);
    final disp = _splitDispatcher(dispRaw);
    final r = research[id!];
    final d = disp[id!];
    if (r == null) {
      stderr.writeln('no research for $id');
      exit(2);
    }
    if (d == null) {
      stderr.writeln('no dispatcher for $id');
      exit(2);
    }
    final contract = _contractFor(id!);

    final intro = _ascii('''
CONTENT GENERATOR RUN
- ASCII-only. Output ONLY the three files after all checks pass. No extra text.
- If any coverage/QA check fails, silently fix and re-run internally until pass.
''');

    final buf = StringBuffer();
    if (withIntro) {
      buf.writeln(intro.trim());
      buf.writeln();
    }
    // Order: dispatcher -> contract -> research
    buf.writeln(d.trim());
    buf.writeln(contract.trim());
    buf.writeln(r.trim());
    stdout.write(buf.toString());
  } on FileSystemException {
    stderr.writeln('io error');
    exit(4);
  } on FormatException {
    stderr.writeln('parse error');
    exit(2);
  }
}
