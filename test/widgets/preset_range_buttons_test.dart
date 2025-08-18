import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/widgets/preset_range_buttons.dart';
import 'package:poker_analyzer/services/pack_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tight and slider presets work', (tester) async {
    final selected = <String>{};
    double percent = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              PresetRangeButtons(
                selected: selected,
                onChanged: (v) => setState(() {
                  selected
                    ..clear()
                    ..addAll(v);
                  percent = selected.length / 169 * 100;
                }),
              ),
              Slider(
                value: percent,
                min: 0,
                max: 100,
                onChanged: (v) => setState(() {
                  percent = v;
                  selected
                    ..clear()
                    ..addAll(PackGeneratorService.topNHands(v.round()));
                }),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tight'));
    await tester.pump();
    expect(selected.length >= 16 && selected.length <= 18, isTrue);

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(50);
    await tester.pump();
    expect(selected.length >= 83 && selected.length <= 85, isTrue);
  });
}
