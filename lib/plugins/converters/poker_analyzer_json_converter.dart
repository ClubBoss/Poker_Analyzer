import 'dart:convert';

import '../converter_format_capabilities.dart';
import '../converter_plugin.dart';
import 'package:poker_analyzer/models/saved_hand.dart';

/// Converter for Poker Analyzer's native JSON hand format.
class PokerAnalyzerJsonConverter extends ConverterPlugin {
  PokerAnalyzerJsonConverter()
    : super(
        formatId: 'poker_analyzer_json',
        description: 'Poker Analyzer JSON format',
        capabilities: const ConverterFormatCapabilities(
          supportsImport: true,
          supportsExport: true,
          requiresBoard: false,
          supportsMultiStreet: true,
        ),
      );

  @override
  SavedHand? convertFrom(String externalData) {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(externalData);
      return SavedHand.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  @override
  String? convertTo(SavedHand hand) {
    try {
      final Map<String, dynamic> jsonMap = hand.toJson();
      return jsonEncode(jsonMap);
    } catch (_) {
      return null;
    }
  }
}
