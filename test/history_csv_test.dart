import 'package:test/test.dart';
import 'package:poker_analyzer/utils/history_csv.dart';

void main() {
  test('buildHistoryCsv formats rows correctly', () {
    final rows = [
      {'ts': 't1', 'args': '--flag', 'out': '/tmp/out1', 'log': '/tmp/log1'},
      {
        'ts': 't2',
        'args': '"quoted" arg',
        'out': '/tmp/out2',
        'log': '/tmp/log2',
      },
    ];
    final csv = buildHistoryCsv(rows);
    final lines = csv.trim().split('\n');
    expect(lines.first, 'timestamp,args,outPath,logPath');
    expect(lines[1], '"t1","--flag","/tmp/out1","/tmp/log1"');
    expect(lines[2], '"t2","""quoted"" arg","/tmp/out2","/tmp/log2"');
    expect(lines.length, 3);
  });
}
