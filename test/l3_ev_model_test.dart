import 'dart:convert';
import 'dart:io';

import 'package:poker_analyzer/l3/ev/jam_fold_model.dart';
import 'package:poker_analyzer/l3/jam_fold_evaluator.dart';
import 'package:test/test.dart';

void main() {
  test('JamFoldModel deterministic for fixed inputs', () {
    final model = JamFoldModel();
    final board = FlopBoard.fromString('AsKdTh');
    final spr = 1.5;
    final res1 = model.evaluate(board: board, spr: spr);
    final res2 = model.evaluate(board: board, spr: spr);
    expect(res1['decision'], res2['decision']);
    expect(res1['jamEV'], res2['jamEV']);
    expect(res1['foldEV'], res2['foldEV']);
  });

  test('packrun_ev CLI smoke', () async {
    final tmpDir = await Directory.systemTemp.createTemp('l3_ev');
    final inFile = File('${tmpDir.path}/in.json');
    final input = {
      'spots': [
        {'id': '1', 'board': 'AsKdTh'},
        {'id': '2', 'board': '2c3d4h'},
      ]
    };
    inFile.writeAsStringSync(jsonEncode(input));

    final out1 = '${tmpDir.path}/out1.json';
    final res1 = await Process.run('dart', [
      'run',
      'tool/l3/packrun_ev.dart',
      '--in',
      inFile.path,
      '--out',
      out1,
      '--weightsPreset',
      'default',
    ]);
    expect(res1.exitCode, 0, reason: res1.stderr);
    final report1 = jsonDecode(File(out1).readAsStringSync()) as Map<String, dynamic>;
    final jamRate1 = report1['summary']['jamRate'] as num;
    expect(jamRate1 >= 0 && jamRate1 <= 1, isTrue);

    final out2 = '${tmpDir.path}/out2.json';
    final weightsJson = jsonEncode({'monotone': 0.0});
    final res2 = await Process.run('dart', [
      'run',
      'tool/l3/packrun_ev.dart',
      '--in',
      inFile.path,
      '--out',
      out2,
      '--weights',
      weightsJson,
    ]);
    expect(res2.exitCode, 0, reason: res2.stderr);
    final report2 = jsonDecode(File(out2).readAsStringSync()) as Map<String, dynamic>;
    final jamRate2 = report2['summary']['jamRate'] as num;
    expect(jamRate2 >= 0 && jamRate2 <= 1, isTrue);
  });
}
