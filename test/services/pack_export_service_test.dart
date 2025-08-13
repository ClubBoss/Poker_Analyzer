import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/services/pack_export_service.dart';
import 'package:poker_analyzer/services/pack_generator_service.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

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

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exportToCsv returns file with rows and columns', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    final share = _FakeSharePlatform();
    SharePlatform.instance = share;
    final tpl = PackGeneratorService.generatePushFoldPackSync(
      id: 't',
      name: 'Test Pack',
      heroBbStack: 10,
      playerStacksBb: [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: ['AA', 'KK', 'QQ'],
    );
    final file = await PackExportService.exportToCsv(tpl);
    final lines = await file.readAsLines();
    expect(lines.length, 4);
    expect(lines.first.split(',').length, 10);
    await dir.delete(recursive: true);
    expect(share.shared, true);
  });
}
