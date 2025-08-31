import 'dart:io';
import 'dart:convert';

String _ascii(String s) {
  final b = StringBuffer();
  for (final c in s.codeUnits) {
    if (c == 0x0D) continue;
    b.writeCharCode(c <= 0x7F ? c : 0x3F);
  }
  return b.toString();
}

String _stripIdSource(String s) =>
    _ascii(s).split('\n').where((l) => !l.startsWith('ID SOURCE:')).join('\n');

String _coverageContract(String id) {
  final base = [
    'COVERAGE CONTRACT (must pass before output)',
    '- theory.md: 450-550 words; sections per template.',
    '- demos.jsonl: 2-3 items. drills.jsonl: 12-16 items.',
    '- Targets are snake_case tokens only [a-z0-9_].',
    '- SpotKind must be from the allowlist (no new kinds).',
    '- INTERNAL QA LOOP: If any check fails, silently fix and re-run; only emit the three files when all pass.',
  ];
  if (id == 'core_rules_and_setup') {
    base.addAll([
      '- Must explicitly include (case-insensitive):',
      '  - Hand rankings (highest to lowest): royal_flush, straight_flush, four_of_a_kind, full_house, flush, straight, three_of_a_kind, two_pair, one_pair, high_card',
      '  - Ties / comparisons: "no suit priority"; straight/straight-flush compare top card; flush compares highest card then kickers; full house compares trips then pair',
      '  - Action order: preflop order; postflop "first_active_left_of_btn"',
      '  - Min-raise math: "new_total - current_bet >= last_raise_size"',
      '  - Showdown lines: "bettor_shows_first" and "first_active_left_of_btn_shows"',
      '- Mini example must use positions: UTG, MP, CO, BTN, SB, BB.',
    ]);
  }
  return base.join('\n');
}

void _fail(String msg, int code) {
  stderr.writeln(msg);
  exit(code);
}

void main(List<String> args) {
  // Args: --id <module_id>
  String? id;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--id') {
      if (i + 1 >= args.length) _fail('missing id', 2);
      id = args[++i];
    } else {
      _fail('unknown arg: ${args[i]}', 2);
    }
  }
  if (id == null || !RegExp(r'^[a-z0-9_]+$').hasMatch(id!)) {
    _fail('invalid id', 2);
  }

  // 1) Dispatcher block
  final disp = Process.runSync('dart', [
    'run',
    'tooling/next_dispatcher_block.dart',
    '--id',
    id!,
  ]);
  if (disp.exitCode != 0) _fail('dispatcher error', 2);
  final dispatcher = _stripIdSource(disp.stdout.toString()).trim();
  if (!dispatcher.startsWith('module_id: $id')) {
    _fail('dispatcher mismatch', 2);
  }

  // 2) Coverage contract
  final cover = _coverageContract(id!);

  // 3) Research template slice
  final slice = Process.runSync('dart', [
    'run',
    'tooling/slice_research_prompt.dart',
    '--id',
    id!,
  ]);
  if (slice.exitCode != 0) _fail('slicer error', 2);
  final research = _ascii(slice.stdout.toString()).trim();
  if (!research.startsWith('GO MODULE: $id')) {
    _fail('slicer mismatch', 2);
  }

  // Compose final prompt
  final header = [
    'CONTENT GENERATOR RUN',
    '- ASCII-only. Output ONLY the three files after all checks pass. No extra text.',
    '- If any coverage/QA check fails, silently fix and re-run internally until pass.',
    '',
  ].join('\n');

  final out = StringBuffer()
    ..writeln(header)
    ..writeln(dispatcher)
    ..writeln(cover)
    ..writeln()
    ..writeln(research);

  stdout.write(out.toString());
}
