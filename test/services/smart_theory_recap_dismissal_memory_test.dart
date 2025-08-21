import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/smart_theory_recap_dismissal_memory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SmartTheoryRecapDismissalMemory.instance.resetForTest();
  });

  test('registerDismissal stores data and throttles', () async {
    final mem = SmartTheoryRecapDismissalMemory.instance;
    await mem.registerDismissal('lesson:l1');
    expect(await mem.shouldThrottle('lesson:l1'), isTrue);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('smart_theory_recap_dismissals_v2');
    expect(raw, isNotNull);
    final map = jsonDecode(raw!) as Map;
    expect(map.containsKey('lesson:l1'), isTrue);

    // Simulate old timestamp beyond decay
    final entry = Map<String, dynamic>.from(map['lesson:l1'] as Map);
    entry['ts'] =
        DateTime.now().subtract(const Duration(days: 4)).toIso8601String();
    map['lesson:l1'] = entry;
    await prefs.setString('smart_theory_recap_dismissals_v2', jsonEncode(map));
    mem.resetForTest();
    expect(await mem.shouldThrottle('lesson:l1'), isFalse);
  });
}
