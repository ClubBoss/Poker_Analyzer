import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/theory_pack_library_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadAll loads sample theory pack', () async {
    final service = TheoryPackLibraryService.instance;
    await service.reload();
    expect(service.all.isNotEmpty, true);
    final pack = service.getById('sample_theory');
    expect(pack, isNotNull);
    expect(pack!.sections.length, 2);
  });
}
