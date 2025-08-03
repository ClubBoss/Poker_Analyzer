import 'package:test/test.dart';
import 'package:poker_analyzer/services/board_filtering_tag_library_service.dart';

void main() {
  test('resolve matches aliases and ids', () {
    final tag = BoardFilteringTagLibraryService.resolve('two-tone');
    expect(tag?.id, 'twoTone');
    expect(
      BoardFilteringTagLibraryService.resolve('aceHigh')?.description,
      contains('A-high'),
    );
  });

  test('supportedTagIds exposes all ids', () {
    final ids = BoardFilteringTagLibraryService.supportedTagIds();
    expect(ids, contains('aceHigh'));
    expect(ids, contains('rainbow'));
  });
}
