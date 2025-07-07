import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/range_library_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('load existing range', () async {
    final range = await RangeLibraryService.instance.getRange('test');
    expect(range, ['A2o', 'KTs']);
  });

  test('cache result', () async {
    final first = await RangeLibraryService.instance.getRange('test');
    final second = await RangeLibraryService.instance.getRange('test');
    expect(identical(first, second), isTrue);
  });

  test('missing range returns empty', () async {
    final range = await RangeLibraryService.instance.getRange('missing');
    expect(range, isEmpty);
  });
}
