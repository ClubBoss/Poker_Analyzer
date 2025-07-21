import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/mastery_persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and load roundtrip', () async {
    final service = MasteryPersistenceService();
    await service.save({'A': 0.8, 'B ': 1.2});
    final map = await service.load();
    expect(map['a'], closeTo(0.8, 0.0001));
    expect(map['b'], 1.0);
  });

  test('load handles malformed data', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tag_mastery', '{"x": "bad", "y": 0.5, "z": null}');
    final service = MasteryPersistenceService();
    final map = await service.load();
    expect(map, {'y': 0.5});
  });
}
