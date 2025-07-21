import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:share_plus/share_plus.dart';

class FileSaverService {
  const FileSaverService._();
  static const FileSaverService instance = FileSaverService._();

  Future<void> saveJson(String name, Map<String, dynamic> data) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
    await FileSaver.instance.saveAs(
      name: name,
      bytes: bytes,
      ext: 'json',
      mimeType: MimeType.other,
    );
  }

  Future<void> saveCsv(String name, String data) async {
    final bytes = Uint8List.fromList(utf8.encode(data));
    await FileSaver.instance.saveAs(
      name: name,
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  Future<void> saveZip(String name, [Uint8List? data]) async {
    Uint8List bytes;
    String fileName;
    if (data == null) {
      final file = File(name);
      bytes = await file.readAsBytes();
      fileName = file.path.split(Platform.pathSeparator).last.split('.').first;
    } else {
      bytes = data;
      fileName = name;
    }
    await FileSaver.instance.saveAs(
      name: fileName,
      bytes: bytes,
      ext: 'zip',
      mimeType: MimeType.other,
    );
  }

  Future<void> savePng(String name, Uint8List data) async {
    await FileSaver.instance.saveAs(
      name: name,
      bytes: data,
      ext: 'png',
      mimeType: MimeType.other,
    );
  }

  Future<void> saveMd(String name, String data) async {
    final bytes = Uint8List.fromList(utf8.encode(data));
    await FileSaver.instance.saveAs(
      name: name,
      bytes: bytes,
      ext: 'md',
      mimeType: MimeType.other,
    );
  }

  Future<void> savePdf(String name, Uint8List data) async {
    await FileSaver.instance.saveAs(
      name: name,
      bytes: data,
      ext: 'pdf',
      mimeType: MimeType.other,
    );
  }

  Future<void> sharePdf(String path) async {
    await Share.shareXFiles([XFile(path)]);
  }
}
