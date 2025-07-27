import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/theory_content_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await TheoryContentService.instance.reload();
  });

  test('loads default block when no locale override', () async {
    final block = TheoryContentService.instance.get('welcome', locale: 'en');
    expect(block, isNotNull);
    expect(block!.title, 'Welcome');
  });

  test('loads localized block when available', () async {
    final block = TheoryContentService.instance.get('welcome', locale: 'ru');
    expect(block, isNotNull);
    expect(block!.title, 'Добро пожаловать');
  });
}
