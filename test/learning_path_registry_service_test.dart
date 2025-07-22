import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/learning_path_registry_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadAll parses templates from assets', () async {
    final service = LearningPathRegistryService.instance;
    final list = await service.loadAll();
    expect(list, isNotEmpty);
    final tpl = service.findById('sample');
    expect(tpl, isNotNull);
    expect(tpl!.title, 'Sample Learning Path');
    expect(tpl.sections.isNotEmpty, true);
  });
}
