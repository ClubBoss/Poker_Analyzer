import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/widgets/range_matrix_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('selects A5s on tap', (WidgetTester tester) async {
    final selected = <String>{};
    await tester.pumpWidget(
      MaterialApp(
        home: RangeMatrixPicker(
          selected: selected,
          onChanged: (s) {
            selected
              ..clear()
              ..addAll(s);
          },
        ),
      ),
    );

    await tester.tap(find.text('A5s'));
    await tester.pump();

    expect(selected.contains('A5s'), isTrue);
  });
}
