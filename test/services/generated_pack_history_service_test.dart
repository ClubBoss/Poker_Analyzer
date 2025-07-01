import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_ai_analyzer/services/generated_pack_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('log + reload keeps max 50 entries', () async {
    SharedPreferences.setMockInitialValues({});
    for (var i = 0; i < 60; i++) {
      await GeneratedPackHistoryService.logPack(
        id: 'id$i',
        name: 'n$i',
        type: 't',
        ts: DateTime.now(),
      );
    }
    final list = await GeneratedPackHistoryService.load();
    expect(list.length, 50);
    expect(list.first.id, 'id59');
    expect(list.last.id, 'id10');
  });
}
