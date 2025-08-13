import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_editor_screen.dart';
import 'package:poker_analyzer/services/room_hand_history_importer.dart';

class _TestPathProvider extends PathProviderPlatform {
  _TestPathProvider(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

Future<TrainingPackSpot> _spotFromText(String text) async {
  final importer = await RoomHandHistoryImporter.create();
  final hand = importer.parse(text).first;
  final hero = hand.playerCards[hand.heroIndex]
      .map((c) => '${c.rank}${c.suit}')
      .join(' ');
  final acts = <ActionEntry>[
    for (final a in hand.actions)
      if (a.street == 0) a
  ];
  final stacks = <String, double>{
    for (int i = 0; i < hand.numberOfPlayers; i++)
      '$i': (hand.stackSizes[i] ?? 0).toDouble()
  };
  return TrainingPackSpot(
    id: 's${hand.name}',
    hand: HandData(
      heroCards: hero,
      position: parseHeroPosition(hand.heroPosition),
      heroIndex: hand.heroIndex,
      playerCount: hand.numberOfPlayers,
      stacks: stacks,
      actions: {0: acts},
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dup hint after import', (tester) async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _TestPathProvider(dir.path);
    final text = [
      "PokerStars Hand #1: Hold'em No Limit (\$0.01/\$0.02 USD) - 2023/01/01 00:00:00 ET",
      "Table 'Alpha' 6-max Seat #1 is the button",
      'Seat 1: Player1 (\$1 in chips)',
      'Seat 2: Player2 (\$1 in chips)',
      '*** HOLE CARDS ***',
      'Dealt to Player1 [Ah Kh]',
      'Player1: raises 2 to 2',
      'Player2: folds',
      '*** SUMMARY ***',
    ].join('\n');
    final spot = await _spotFromText(text);
    final tpl = TrainingPackTemplate(id: 't', name: 't', spots: [spot]);
    await Clipboard.setData(ClipboardData(text: text));
    await tester.pumpWidget(MaterialApp(
      home: TrainingPackTemplateEditorScreen(template: tpl, templates: [tpl]),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paste Hands'));
    await tester.pumpAndSettle();
    expect(find.text('Duplicates found'), findsOneWidget);
    await dir.delete(recursive: true);
  });
}
