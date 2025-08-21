import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_list_screen.dart';

class _FakeFilePicker extends FilePicker {
  _FakeFilePicker(this.result);
  final FilePickerResult result;
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return result;
  }

  @override
  Future<List<String>?> pickFileAndDirectoryPaths({
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async =>
      null;

  @override
  Future<bool?> clearTemporaryFiles() async => true;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async =>
      null;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async =>
      null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('import csv adds template', (tester) async {
    const csv =
        'Title,HeroPosition,HeroHand,StackBB,StacksBB,HeroIndex,CallsMask,EV_BB,ICM_EV,Tags\nA,SB,AA,10,,0,,0.1,,\n';
    final file = PlatformFile(
      name: 'test.csv',
      size: csv.length,
      bytes: Uint8List.fromList(csv.codeUnits),
    );
    FilePicker.platform = _FakeFilePicker(FilePickerResult([file]));
    await tester.pumpWidget(
      const MaterialApp(home: TrainingPackTemplateListScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.upload_file));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('test'), findsOneWidget);
  });
}
