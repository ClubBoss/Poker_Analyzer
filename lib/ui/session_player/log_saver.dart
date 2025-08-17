import 'dart:convert';
import 'dart:io';

import 'answer_log.dart';
import 'models.dart';

String fnv32Hex(String s) {
  const int fnvOffset = 0x811c9dc5;
  const int fnvPrime = 0x01000193;
  var hash = fnvOffset;
  for (final codeUnit in s.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * fnvPrime) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

Future<String> saveAnswerLogJson({
  required List<UiSpot> spots,
  required List<UiAnswer> answers,
  String outDir = 'out/session_logs',
  String format = 'pretty',
}) async {
  final log = buildAnswerLog(spots, answers);
  final buffer = StringBuffer();
  for (var i = 0; i < answers.length; i++) {
    final spot = spots[i];
    final ans = answers[i];
    buffer.writeln(
        '${spot.kind.name}|${spot.hand}|${spot.pos}|${spot.stack}|${ans.expected}|${ans.chosen}|${ans.elapsed.inMilliseconds}');
  }
  final hash = fnv32Hex(buffer.toString());
  final dir = Directory(outDir);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final file = File('${dir.path}/answers_v1_${hash}.json');
  final encoder = format == 'pretty'
      ? const JsonEncoder.withIndent('  ')
      : const JsonEncoder();
  final json = encoder.convert(log.toJson());
  await file.writeAsString(json);
  return file.absolute.path;
}
