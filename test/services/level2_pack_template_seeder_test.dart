import 'package:test/test.dart';
import 'package:poker_analyzer/services/level2_pack_template_seeder.dart';
import 'package:poker_analyzer/services/training_pack_template_library_service.dart';

void main() {
  test('seedAll generates and stores Level II templates', () async {
    final library = TrainingPackTemplateLibraryService.instance;
    library.clear();

    final seeder = LevelIIPackTemplateSeeder(library: library);
    await seeder.seedAll();

    expect(library.templates.length, 3);
    final open = library.getById('l2_open_fold');
    expect(open, isNotNull);
    expect(open!.tags, containsAll(['open', 'fold']));
    expect(open.meta['skillLevel'], 'intermediate');
  });
}
