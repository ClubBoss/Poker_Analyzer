import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AssetManifest {
  AssetManifest._();
  static late final Future<Map<String, dynamic>> instance =
      rootBundle
          .loadString('AssetManifest.json')
          .then<Map<String, dynamic>>(jsonDecode)
          .catchError((_) => <String, dynamic>{});
}
