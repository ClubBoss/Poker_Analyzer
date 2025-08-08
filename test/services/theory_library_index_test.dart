import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/theory_library_index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads theory index and validates entries', () async {
    final index = TheoryLibraryIndex();
    final items = await index.all();
    expect(items.length, 3);
    expect(items.any((e) => e.id == 'th_push'), isTrue);
  });
}
