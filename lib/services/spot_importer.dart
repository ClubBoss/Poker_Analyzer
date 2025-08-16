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
    final seen = <String>{};
    var dupReported = false;

    void addError(String msg) {
      skipped++;
      if (errors.length < 5) errors.add(msg);
    }

    void addDup(String key) {
      skipped++;
      if (!dupReported && errors.length < 5) {
        errors.add('Duplicate spot: $key');
        dupReported = true;
      }
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
            if (spot != null) {
              final key =
                  '${spot.kind.name}|${spot.hand.trim()}|${spot.pos.trim()}|${spot.stack.trim()}|${spot.action.trim()}';
              if (seen.contains(key)) {
                addDup(key);
              } else {
                seen.add(key);
                spots.add(spot);
              }
            }
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
              final key =
                  '${spot.kind.name}|${spot.hand.trim()}|${spot.pos.trim()}|${spot.stack.trim()}|${spot.action.trim()}';
              if (seen.contains(key)) {
                addDup(key);
              } else {
                seen.add(key);
                spots.add(spot);
              }
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
    String? get(String key) {
      if (m[key] is String) {
        final t = (m[key] as String).trim();
        return t.isEmpty ? null : t;
      }
      return null;
    }

    final k = get('kind');
    final hand = get('hand');
    final pos = get('pos');
    final stack = get('stack');
    final action = get('action');
    if (k == null || hand == null || pos == null || stack == null || action == null) {
      addError('Row $row: missing field');
      return null;
    }
    SpotKind? kind;
    for (final sk in SpotKind.values) {
      if (k.toLowerCase() == sk.name.toLowerCase()) {
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
      vsPos: get('vsPos'),
      limpers: get('limpers'),
      explain: get('explain'),
    );
  }
}
