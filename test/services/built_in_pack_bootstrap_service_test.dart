import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/built_in_pack_bootstrap_service.dart';
import 'package:poker_analyzer/generated/pack_library.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    packLibrary.clear();
    SharedPreferences.setMockInitialValues({});
  });

  test('imports packs when library empty', () async {
    expect(packLibrary.isEmpty, true);
    await const BuiltInPackBootstrapService().importIfNeeded();
    expect(packLibrary.isNotEmpty, true);
  });

  test('import is idempotent', () async {
    await const BuiltInPackBootstrapService().importIfNeeded();
    final count = packLibrary.length;
    await const BuiltInPackBootstrapService().importIfNeeded();
    expect(packLibrary.length, count);
  });
}
