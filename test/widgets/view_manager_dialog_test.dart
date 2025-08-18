import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/view_preset.dart';
import 'package:poker_analyzer/widgets/view_manager_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reorders views and shows icons', (tester) async {
    final views = [
      ViewPreset(name: 'One', sort: 0, mistakeFilter: 0, search: ''),
      ViewPreset(name: 'Two', sort: 0, mistakeFilter: 0, search: ''),
      ViewPreset(name: 'Three', sort: 0, mistakeFilter: 0, search: ''),
    ];
    List<ViewPreset>? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: ViewManagerDialog(views: views, onChanged: (v) => changed = v),
      ),
    );

    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorder(0, views.length);
    await tester.pump();

    expect(changed!.map((e) => e.name), ['Two', 'Three', 'One']);
    expect(find.byIcon(Icons.edit), findsNWidgets(views.length));
    expect(find.byIcon(Icons.delete), findsNWidgets(views.length));
  });
}
