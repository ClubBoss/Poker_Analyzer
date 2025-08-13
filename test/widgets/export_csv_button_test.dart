import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_editor_screen.dart';
import 'package:poker_analyzer/services/pack_generator_service.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

class _FakeSharePlatform extends SharePlatform {
  bool shared = false;
  @override
  Future<void> shareXFiles(List<XFile> files,
      {String? text,
      String? subject,
      ShareOptions? sharePositionOrigin}) async {
    shared = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Export CSV triggers share', (tester) async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    final share = _FakeSharePlatform();
    SharePlatform.instance = share;
    final tpl = PackGeneratorService.generatePushFoldPackSync(
      id: 't',
      name: 'Test',
      heroBbStack: 10,
      playerStacksBb: [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: ['AA'],
    );
    await tester.pumpWidget(MaterialApp(
      home: TrainingPackTemplateEditorScreen(template: tpl, templates: [tpl]),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export CSV'));
    await tester.pumpAndSettle();
    expect(share.shared, true);
    await dir.delete(recursive: true);
  });
}
