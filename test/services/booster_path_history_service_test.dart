import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/booster_path_history_service.dart';
import 'package:poker_analyzer/models/booster_tag_history.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('records interactions per tag', () async {
    final service = BoosterPathHistoryService.instance;

    await service.markShown('cbet');
    await service.markStarted('cbet');
    await service.markCompleted('cbet');
    await service.markShown('3bet');

    final hist = await service.getHistory();
    expect(hist.length, 2);
    final cbet = hist['cbet']!;
    expect(cbet.shownCount, 1);
    expect(cbet.startedCount, 1);
    expect(cbet.completedCount, 1);
    final tbet = hist['3bet']!;
    expect(tbet.shownCount, 1);
    expect(tbet.startedCount, 0);
    expect(tbet.completedCount, 0);
  });
}
