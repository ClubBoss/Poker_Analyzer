import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('interleave_sr_enabled persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('interleave_sr_enabled'), isNull);
    await prefs.setBool('interleave_sr_enabled', false);
    final prefs2 = await SharedPreferences.getInstance();
    expect(prefs2.getBool('interleave_sr_enabled'), false);
  });
}
