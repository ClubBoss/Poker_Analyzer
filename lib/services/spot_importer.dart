import 'dart:convert';

import '../ui/session_player/models.dart';

class SpotImportReport {
  final List<UiSpot> spots;
  final int added;
  final int skipped;
  final List<String> errors;
  SpotImportReport({
    required this.spots,
    required this.added,
    required this.skipped,
    required this.errors,
  });
}

class SpotImporter {
  static SpotImportReport parse(String content, {required String kind}) {
    final spots = <UiSpot>[];
    final errors = <String>[];
    var skipped = 0;

    void addError(String msg) {
      skipped++;
      if (errors.length < 5) errors.add(msg);
    }

    final k = kind.toLowerCase();
    if (k == 'json') {
      dynamic data;
      try {
        data = jsonDecode(content);
      } catch (_) {
        addError('Invalid JSON');
        return SpotImportReport(
            spots: spots, added: 0, skipped: skipped, errors: errors);
      }
      if (data is List) {
        var idx = 0;
        for (final e in data) {
          idx++;
          if (e is Map<String, dynamic>) {
            final spot = _spotFromMap(e, idx, addError);
            if (spot != null) spots.add(spot);
          } else {
            addError('Row $idx: not an object');
          }
        }
      } else {
        addError('JSON root is not an array');
      }
    } else if (k == 'csv') {
      final lines = const LineSplitter().convert(content);
      if (lines.isNotEmpty) {
        final headers = lines.first.split(',').map((e) => e.trim()).toList();
        final requiredHeaders = ['kind', 'hand', 'pos', 'stack', 'action'];
        var headerOk = true;
        for (final h in requiredHeaders) {
          if (!headers.contains(h)) {
            addError('Missing header $h');
            headerOk = false;
          }
        }
        if (headerOk) {
          for (var i = 1; i < lines.length; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;
            final parts = line.split(',');
            final values = <String, String?>{};
            for (var j = 0; j < headers.length && j < parts.length; j++) {
              values[headers[j]] = parts[j].trim();
            }
            final spot = _spotFromMap(values, i + 1, addError);
            if (spot != null) {
              spots.add(spot);
            }
          }
        }
      }
    } else {
      addError('Unsupported kind $kind');
    }
    return SpotImportReport(
        spots: spots, added: spots.length, skipped: skipped, errors: errors);
  }

  static UiSpot? _spotFromMap(
      Map<String, dynamic> m, int row, void Function(String) addError) {
    final k = m['kind'];
    final hand = m['hand'];
    final pos = m['pos'];
    final stack = m['stack'];
    final action = m['action'];
    if (k is! String ||
        hand is! String ||
        pos is! String ||
        stack is! String ||
        action is! String) {
      addError('Row $row: missing field');
      return null;
    }
    SpotKind? kind;
    for (final sk in SpotKind.values) {
      if (sk.name == k) {
        kind = sk;
        break;
      }
    }
    if (kind == null) {
      addError('Row $row: unknown kind $k');
      return null;
    }
    return UiSpot(
      kind: kind,
      hand: hand,
      pos: pos,
      stack: stack,
      action: action,
      vsPos: m['vsPos'] is String ? m['vsPos'] as String : null,
      limpers: m['limpers'] is String ? m['limpers'] as String : null,
      explain: m['explain'] is String ? m['explain'] as String : null,
    );
  }
}
