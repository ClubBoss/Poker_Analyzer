import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class MatrixAxis {
  final String name;
  final List<String> values;
  const MatrixAxis(this.name, this.values);

  Map<String, dynamic> toJson() => {'name': name, 'values': values};
  factory MatrixAxis.fromJson(Map<String, dynamic> j) => MatrixAxis(
    j['name'] as String? ?? '',
    [for (final v in (j['values'] as List? ?? [])) v.toString()],
  );
}

class MatrixTagConfigService {
  const MatrixTagConfigService();

  Future<List<MatrixAxis>> load() async {
    final file = await _getFile();
    String str = '';
    if (file.existsSync()) {
      str = await file.readAsString();
    } else {
      try {
        str = await rootBundle.loadString('assets/tag_matrix.json');
      } catch (_) {}
    }
    if (str.isNotEmpty) {
      try {
        final data = jsonDecode(str);
        if (data is List) {
          return [
            for (final e in data)
              if (e is Map) MatrixAxis.fromJson(Map<String, dynamic>.from(e)),
          ];
        }
      } catch (_) {}
    }
    return _defaultAxes;
  }

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/tag_matrix.json');
  }

  static const _defaultAxes = [
    MatrixAxis('position', ['UTG', 'MP', 'CO', 'BTN', 'SB', 'BB']),
    MatrixAxis('stack', ['<5', '5-7', '8-12', '13-20', '21+']),
  ];
}
