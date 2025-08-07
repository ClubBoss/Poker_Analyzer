import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

import 'package:poker_analyzer/services/theory_auto_injector.dart';
import 'package:poker_analyzer/services/autogen_status_dashboard_service.dart';

void main() {
  group('TheoryAutoInjector', () {
    test('injects links and handles errors', () async {
      SharedPreferences.setMockInitialValues({});
      final dir = await Directory.systemTemp.createTemp('inject_test');
      final packsDir = dir.path;
      final theoryDir = Directory(p.join(packsDir, 'theory'));
      await theoryDir.create(recursive: true);

      final pack1 = File(p.join(packsDir, 'pack1.yaml'));
      await pack1.writeAsString('id: pack1\nmeta:\n  theoryLinks:\n    - t1\n');
      final pack2 = File(p.join(packsDir, 'pack2.yaml'));
      await pack2.writeAsString('id: pack2\n');
      await File(p.join(theoryDir.path, 't1.yaml')).writeAsString('id: t1');
      await File(p.join(theoryDir.path, 't2.yaml')).writeAsString('id: t2');

      final plan = {
        'topic1': ['pack1'],
        'topic2': ['pack2'],
      };
      final index = {
        'topic1': ['t1', 't2'],
        'topic2': ['missing'],
      };

      final injector = TheoryAutoInjector(
        dashboard: AutogenStatusDashboardService.instance,
      );
      final report = await injector.inject(
        plan: plan,
        theoryIndex: index,
        libraryDir: packsDir,
        minLinksPerPack: 2,
      );

      expect(report.packsUpdated, 1);
      expect(report.linksAdded, 1);
      expect(report.errors.containsKey('pack2'), isTrue);
      final content = await pack1.readAsString();
      expect(content.contains('t1'), isTrue);
      expect(content.contains('t2'), isTrue);

      final report2 = await injector.inject(
        plan: plan,
        theoryIndex: index,
        libraryDir: packsDir,
        minLinksPerPack: 2,
      );
      expect(report2.linksAdded, 0);
      expect(report2.packsUpdated, 0);
    });
  });
}
