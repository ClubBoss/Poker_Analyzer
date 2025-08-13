import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/screens/room_hand_history_import_screen.dart';
import 'package:poker_analyzer/models/training_pack.dart';
import 'package:poker_analyzer/services/training_pack_storage_service.dart';

class _TestPathProvider extends PathProviderPlatform {
  _TestPathProvider(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
  @override
  Future<String?> getLibraryPath() async => path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getApplicationCachePath() async => path;
  @override
  Future<String?> getExternalStoragePath() async => path;
  @override
  Future<List<String>?> getExternalCachePaths() async => [path];
  @override
  Future<List<String>?> getExternalStoragePaths(
          {StorageDirectory? type}) async =>
      [path];
  @override
  Future<String?> getDownloadsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late TrainingPackStorageService service;
  late TrainingPack pack;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _TestPathProvider(dir.path);
    service = TrainingPackStorageService();
    pack = TrainingPack(name: 'Pack', description: '', hands: []);
    await service.addPack(pack);
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  testWidgets('add selected hands and undo', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<TrainingPackStorageService>.value(
        value: service,
        child: MaterialApp(home: RoomHandHistoryImportScreen(pack: pack)),
      ),
    );
    await tester.pumpAndSettle();

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
      '',
      "PokerStars Hand #2: Hold'em No Limit (\$0.01/\$0.02 USD) - 2023/01/01 00:01:00 ET",
      "Table 'Beta' 6-max Seat #1 is the button",
      'Seat 1: Hero (\$1 in chips)',
      'Seat 2: Villain (\$1 in chips)',
      '*** HOLE CARDS ***',
      'Dealt to Hero [Qs Qd]',
      'Hero: raises 4 to 4',
      'Villain: folds',
      '*** SUMMARY ***',
    ].join('\n');

    await tester.enterText(find.byType(TextField).first, text);
    await tester.tap(find.text('Parse'));
    await tester.pumpAndSettle();

    final boxes = find.byType(Checkbox);
    await tester.tap(boxes.at(0));
    await tester.tap(boxes.at(1));
    await tester.pump();

    expect(service.packs.first.hands.length, 0);

    await tester.tap(find.text('Add Selected'));
    await tester.pumpAndSettle();
    expect(service.packs.first.hands.length, 2);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(service.packs.first.hands.length, 0);
  });
}
