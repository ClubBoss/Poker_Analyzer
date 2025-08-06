import 'package:test/test.dart';
import 'package:poker_analyzer/services/postflop_template_seeder.dart';
import 'package:poker_analyzer/services/training_pack_template_library_service.dart';

void main() {
  test('seedAll generates postflop templates', () async {
    final library = TrainingPackTemplateLibraryService.instance;
    library.clear();

    final seeder = PostflopTemplateSeeder(library: library);
    await seeder.seedAll();

    expect(library.templates.length, 3);
    final flop = library.getById('pf_flop_cbet');
    expect(flop, isNotNull);
    expect(flop!.tags, contains('flop'));
    expect(flop.meta['skillLevel'], 'advanced');
  });
}
