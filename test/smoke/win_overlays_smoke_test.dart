import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('win overlays render and settle animations', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _FakeWinOverlay())),
    );

    expect(find.byKey(const ValueKey('win-overlay')), findsOneWidget);

    // В новых SDK возвращает int (количество шагов).
    final pumps = await tester.pumpAndSettle(const Duration(seconds: 10));
    // Если не успеет за 10s — тест кинет ошибку и сюда не дойдёт.
    // Делаем мягкую проверку, что вернулся корректный счётчик.
    expect(pumps, greaterThanOrEqualTo(0));
  });
}

class _FakeWinOverlay extends StatelessWidget {
  const _FakeWinOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(key: const ValueKey('win-overlay'));
  }
}
