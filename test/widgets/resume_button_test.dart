import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/screens/packs_library_screen.dart';
import 'package:poker_analyzer/screens/v2/training_session_screen.dart';

class _FakeBundle extends CachingAssetBundle {
  final Map<String, String> data;
  _FakeBundle(this.data);
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      data[key]!;
}

void main() {
  testWidgets('resume button opens session', (tester) async {
    final tpl = TrainingPackTemplate(
      id: 'p1',
      name: 'Pack',
      spots: [TrainingPackSpot(id: 's1', hand: HandData())],
      createdAt: DateTime.now(),
    );
    final bundle = _FakeBundle({
      'AssetManifest.json': jsonEncode({
        'assets/packs/test.json': ['assets/packs/test.json'],
      }),
      'assets/packs/test.json': jsonEncode(tpl.toJson()),
    });
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle,
        child: const MaterialApp(home: PacksLibraryScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingSessionScreen), findsOneWidget);
  });
}
