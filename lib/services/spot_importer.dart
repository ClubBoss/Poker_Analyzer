import 'dart:convert';

import 'package:poker_analyzer/ui/session_player/l3_jsonl_decode.dart';

import '../ui/session_player/models.dart';

class SpotImportReport {
  final List<UiSpot> spots;
  final int added;
  final int skipped;
  final int skippedDuplicates;
  final List<String> errors;
  SpotImportReport({
    required this.spots,
    required this.added,
    required this.skipped,
    required this.skippedDuplicates,
    required this.errors,
  });
}

class SpotImporter {
  /// Parses [content] and returns an import report.
  ///
  /// Supported formats: `jsonl` (preferred), `json`, `csv`.
  /// Auto-detects by content or extension and falls back to tolerant JSON via
  /// [decodeJsonl] where applicable.
  /// If both are provided, [format] takes precedence and [kind] is ignored;
  /// defaults to `json`.
  /// CSV notes: quoted fields are de-quoted (and "" unescaped), but fields
  /// must not contain the active separator. Prefer ';' when values contain
  /// commas.
  static SpotImportReport parse(
    String content, {
    String? format,
    String? kind,
  }) {
    final fmt = (format ?? kind ?? 'json').toLowerCase();
    final spots = <UiSpot>[];
    final errors = <String>[];
    var skipped = 0;
    var skippedDuplicates = 0;
    final seen = <String>{};
    var dupReported = false;

    void addError(String msg) {
      skipped++;
      if (errors.length < 5) errors.add(msg);
    }

    void addDup(String key) {
      skipped++;
      skippedDuplicates++;
      if (!dupReported && errors.length < 5) {
        errors.add('Duplicate spot: $key');
        dupReported = true;
      }
    }

    void process(Iterable<dynamic> data) {
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
    }

    if (fmt == 'jsonl') {
      try {
        process(decodeJsonl(content));
      } on FormatException {
        addError('Invalid JSONL');
        return SpotImportReport(
          spots: spots,
          added: 0,
          skipped: skipped,
          skippedDuplicates: skippedDuplicates,
          errors: errors,
        );
      }
    } else if (fmt == 'json') {
      Iterable<dynamic>? data;
      try {
        final decoded = json.decode(content);
        if (decoded is List) {
          data = decoded;
        } else {
          data = decodeJsonl(content);
        }
      } on FormatException {
        try {
          data = decodeJsonl(content);
        } on FormatException {
          addError('Invalid JSON');
          return SpotImportReport(
            spots: spots,
            added: 0,
            skipped: skipped,
            skippedDuplicates: skippedDuplicates,
            errors: errors,
          );
        }
      }
      try {
        process(data);
      } on FormatException {
        addError('Invalid JSON');
      }
    } else if (fmt == 'csv') {
      String dequote(String s) {
        if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
          return s.substring(1, s.length - 1).replaceAll('""', '"');
        }
        return s;
      }

      final rawLines = const LineSplitter().convert(content);
      if (rawLines.isNotEmpty) {
        final headerLine = rawLines.first.replaceFirst('\uFEFF', '');
        final sep = headerLine.contains(';') ? ';' : ',';
        final headers = headerLine
            .split(sep)
            .map((h) => h.trim().toLowerCase())
            .toList();
        final requiredHeaders = ['kind', 'hand', 'pos', 'stack', 'action'];
        var headerOk = true;
        for (final h in requiredHeaders) {
          if (!headers.contains(h)) {
            addError('Missing header $h');
            headerOk = false;
          }
        }
        if (headerOk) {
          for (var i = 1; i < rawLines.length; i++) {
            final line = rawLines[i].trim();
            if (line.isEmpty) continue;
            final parts = line.split(sep);
            final values = <String, String?>{};
            for (var j = 0; j < headers.length && j < parts.length; j++) {
              values[headers[j]] = dequote(parts[j].trim());
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
      addError('Unsupported format ${format ?? kind}');
    }
    return SpotImportReport(
      spots: spots,
      added: spots.length,
      skipped: skipped,
      skippedDuplicates: skippedDuplicates,
      errors: errors,
    );
  }

  static int? parseStack(String s) {
    final m = RegExp(r'(\d+)\s*bb', caseSensitive: false).firstMatch(s);
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  static UiSpot? _spotFromMap(
    Map<String, dynamic> m,
    int row,
    void Function(String) addError,
  ) {
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
    if (k == null ||
        hand == null ||
        pos == null ||
        stack == null ||
        action == null) {
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
