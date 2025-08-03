import 'package:test/test.dart';
import 'package:poker_analyzer/services/hand_group_tag_library_service.dart';

void main() {
  test('expandTags maps tags to groups', () {
    final groups = HandGroupTagLibraryService.expandTags([
      'broadway',
      'pockets',
    ]);
    expect(groups, contains('broadways'));
    expect(groups, contains('pockets'));
  });

  test('unsupported tags return empty list', () {
    final groups = HandGroupTagLibraryService.expandTags(['unknown']);
    expect(groups, isEmpty);
  });
}
