import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/recent_packs_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TrainingPackTemplate tpl(String id) => TrainingPackTemplate(
    id: id,
    name: 'Pack $id',
    spots: [],
    tags: [],
    isBuiltIn: false,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RecentPacksService.instance.reset();
  });

  test('dedupe ordering and cap', () async {
    final service = RecentPacksService.instance;
    for (var i = 0; i < 6; i++) {
      await service.record(tpl('$i'), when: DateTime(2020, 1, i + 1));
    }
    expect(service.listenable.value.length, 5);
    expect(service.listenable.value.first.id, '5');
    await service.record(tpl('3'), when: DateTime(2020, 2, 1));
    expect(service.listenable.value.first.id, '3');
    expect(service.listenable.value.length, 5);
  });
}
