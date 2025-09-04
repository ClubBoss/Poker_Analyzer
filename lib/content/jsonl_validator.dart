import 'dart:convert';

class JsonlIssue {
  final int line;
  final String message;
  const JsonlIssue(this.line, this.message);
}

class JsonlReport {
  final int count;
  final List<JsonlIssue> issues;
  final Set<String> ids;
  const JsonlReport(this.count, this.issues, this.ids);
  bool get ok => issues.isEmpty;
}

JsonlReport validateJsonl(
  String source, {
  String idField = 'id',
  bool asciiOnly = true,
}) {
  final issues = <JsonlIssue>[];
  final ids = <String>{};
  final lines = const LineSplitter().convert(source);
  var count = 0;

  bool isAscii(String s) => s.codeUnits.every((c) => c <= 0x7F);

  for (var i = 0; i < lines.length; i++) {
    final ln = i + 1;
    final line = lines[i];
    final trimmed = line.trim();

    if (trimmed.isEmpty) {
      // ignore empty lines
      continue;
    }
    if (trimmed.startsWith('#')) {
      // ignore comments starting with '#'
      continue;
    }

    if (asciiOnly && !isAscii(line)) {
      issues.add(JsonlIssue(ln, 'non-ASCII content in line'));
      // still attempt to parse/validate to surface more issues per spec
    }

    Map<String, dynamic> obj;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map) {
        issues.add(JsonlIssue(ln, 'not a JSON object'));
        // skip id checks for non-object
        count++;
        continue;
      }
      // Enforce Map<String, dynamic>
      obj = decoded.map<String, dynamic>((k, v) => MapEntry(k.toString(), v));
    } catch (_) {
      issues.add(JsonlIssue(ln, 'invalid JSON'));
      count++;
      continue;
    }

    // idField must exist, be non-empty string, ASCII
    if (!obj.containsKey(idField)) {
      issues.add(JsonlIssue(ln, "missing required field '$idField'"));
    } else {
      final idVal = obj[idField];
      if (idVal is! String || idVal.isEmpty) {
        issues.add(
          JsonlIssue(ln, "field '$idField' must be a non-empty string"),
        );
      } else {
        if (!isAscii(idVal)) {
          issues.add(JsonlIssue(ln, "field '$idField' must be ASCII-only"));
        }
        // enforce canonical id format: lowercase ascii letters, digits, underscore
        final idPattern = RegExp(r'^[a-z0-9_]+$');
        if (!idPattern.hasMatch(idVal)) {
          issues.add(JsonlIssue(ln, 'invalid id: must match ^[a-z0-9_]+\$'));
        }
        // uniqueness (only check if it's a string value)
        if (!ids.add(idVal)) {
          issues.add(JsonlIssue(ln, "duplicate id '$idVal'"));
        }
      }
    }

    count++;
  }

  return JsonlReport(count, issues, ids);
}
