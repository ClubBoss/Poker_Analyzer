import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

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
}
