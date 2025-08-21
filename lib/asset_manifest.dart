import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

class AssetManifest {
  AssetManifest._();
  static final Future<Map<String, dynamic>> instance = rootBundle
      .loadString('AssetManifest.json')
      .then((s) => jsonDecode(s) as Map<String, dynamic>)
      .catchError((e) {
    debugPrint('🛑 AssetManifest load failed: $e');
    return <String, dynamic>{};
  });
}
