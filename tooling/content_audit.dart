import 'dart:convert';
import 'dart:io';

class CheckResult {
  final String status;
  final List<String> reasons;
  CheckResult(this.status, [List<String>? reasons])
      : reasons = reasons ?? const [];
}

class LineValidation {
  final bool isValid;
  final bool badIdPattern;
  LineValidation(this.isValid, {this.badIdPattern = false});
}

List<String> readModules() {
  final file = File('curriculum_status.json');
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final mods = data['modules_done'] as List<dynamic>?;
  return mods?.map((e) => e.toString()).toList() ?? [];
}

CheckResult checkTheory(String moduleId) {
  final path = 'content/' + moduleId + '/v1/theory.md';
  final file = File(path);
  if (!file.existsSync()) {
    return CheckResult('MISSING');
  }
  final text = file.readAsStringSync().trim();
  if (text.isEmpty) {
    return CheckResult('INVALID', ['empty_file']);
  }
  return CheckResult('OK');
}

bool idMatches(String id, String moduleId, String kind) {
  final prefix = '$moduleId:$kind:';
  if (!id.startsWith(prefix)) return false;
  final suffix = id.substring(prefix.length);
  return suffix.length == 2 && int.tryParse(suffix) != null;
}

CheckResult checkJsonlFile(
  String moduleId,
  String name,
  LineValidation Function(Map<String, dynamic>, String) validator,
  {required int minLines, required int maxLines},
) {
  final path = 'content/' + moduleId + '/v1/' + name;
  final file = File(path);
  if (!file.existsSync()) {
    return CheckResult('MISSING');
  }
  final lines = file.readAsLinesSync();
  if (lines.isEmpty) {
    return CheckResult('INVALID', ['empty_file']);
  }
  int invalid = 0;
  int badId = 0;
  bool nonAscii = false;
  for (final line in lines) {
    if (!isAscii(line)) {
      nonAscii = true;
      continue;
    }
    dynamic data;
    try {
      data = jsonDecode(line);
    } catch (_) {
      invalid++;
      continue;
    }
    if (data is! Map<String, dynamic>) {
      invalid++;
      continue;
    }
    final res = validator(data, moduleId);
    if (!res.isValid) {
      invalid++;
    }
    if (res.badIdPattern) {
      badId++;
    }
  }
  final reasons = <String>[];
  if (invalid > 0) {
    reasons.add('jsonl_invalid:$invalid');
  }
  if (badId > 0) {
    reasons.add('bad_id_pattern:$badId');
  }
  if (lines.length < minLines || lines.length > maxLines) {
    reasons.add('wrong_count');
  }
  if (nonAscii) {
    reasons.add('non_ascii');
  }
  if (reasons.isEmpty) {
    return CheckResult('OK');
  }
  return CheckResult('INVALID', reasons);
}

LineValidation validateDemoLine(Map<String, dynamic> data, String moduleId) {
  final id = data['id'];
  final title = data['title'];
  final steps = data['steps'];
  final hints = data['hints'];
  bool badId = false;
  if (id is! String || !idMatches(id, moduleId, 'demo')) {
    badId = true;
  }
  if (id is! String || title is! String || steps is! List) {
    return LineValidation(false, badIdPattern: badId);
  }
  if (steps.isEmpty || steps.any((e) => e is! String || e.trim().isEmpty)) {
    return LineValidation(false, badIdPattern: badId);
  }
  if (hints != null) {
    if (hints is! List || hints.any((e) => e is! String)) {
      return LineValidation(false, badIdPattern: badId);
    }
  }
  return LineValidation(!badId, badIdPattern: badId);
}

LineValidation validateDrillLine(Map<String, dynamic> data, String moduleId) {
  final id = data['id'];
  final spotKind = data['spotKind'];
  final params = data['params'];
  final target = data['target'];
  final rationale = data['rationale'];
  bool badId = false;
  if (id is! String || !idMatches(id, moduleId, 'drill')) {
    badId = true;
  }
  if (id is! String ||
      spotKind is! String ||
      spotKind.trim().isEmpty ||
      params is! Map ||
      target is! List ||
      target.isEmpty ||
      target.any((e) => e is! String || e.trim().isEmpty) ||
      rationale is! String ||
      rationale.contains('\n')) {
    return LineValidation(false, badIdPattern: badId);
  }
  return LineValidation(!badId, badIdPattern: badId);
}

bool isAscii(String line) {
  return line.codeUnits.every((c) => c <= 0x7f);
}

String formatResult(CheckResult r) {
  if (r.status != 'INVALID') return r.status;
  return 'INVALID(' + r.reasons.join(',') + ')';
}

void main() {
  final modules = readModules();
  final issueModules = <String>[];
  for (final m in modules) {
    final theory = checkTheory(m);
    final demos = checkJsonlFile(
      m,
      'demos.jsonl',
      validateDemoLine,
      minLines: 2,
      maxLines: 3,
    );
    final drills = checkJsonlFile(
      m,
      'drills.jsonl',
      validateDrillLine,
      minLines: 10,
      maxLines: 20,
    );
    if (theory.status != 'OK' ||
        demos.status != 'OK' ||
        drills.status != 'OK') {
      issueModules.add(m);
    }
    final idPadded = m.padRight(40);
    print(
        '${idPadded} theory:${formatResult(theory)} demos:${formatResult(demos)} drills:${formatResult(drills)}');
  }
  print('Totals: ${modules.length} modules, ${issueModules.length} with issues');
  for (var i = 0; i < issueModules.length; i += 12) {
    final end = i + 12 > issueModules.length ? issueModules.length : i + 12;
    final batch = issueModules.sublist(i, end);
    print('');
    print('GO MODULES: ' + batch.join(','));
    print('STYLE OVERRIDE: (per PROMPT_RULES.md)');
  }
  if (issueModules.isEmpty) {
    print('AUDIT:OK');
  } else {
    print('AUDIT:FAILED');
  }
}

