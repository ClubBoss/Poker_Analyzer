// Tiny job-summary reporter (content CI).
// Usage: dart run tooling/ci_summary.dart
// Pure Dart. ASCII-only. No external deps.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  stdout.writeln('# Content CI summary');
  stdout.writeln('## Pre-release\n');

  final pre = _readFile('build/pre_release_check.txt') ?? 'pre_release_check.txt not found';
  stdout.writeln('```');
  stdout.writeln(pre);
  stdout.writeln('```\n');

  const cols = [
    'missing_sections',
    'wordcount_out_of_range',
    'images_missing',
    'demo_count_bad',
    'drill_count_bad',
    'term_errors',
    'links_missing',
    'failing_demos',
  ];
  final vals = {for (final c in cols) c: '-'};

  _parseGaps(vals);
  _parseTerm(vals);
  _parseLinks(vals);
  _parseDemos(vals);

  stdout.writeln('| ' + cols.join(' | ') + ' |');
  stdout.writeln('| ' + List.filled(cols.length, '---').join(' | ') + ' |');
  stdout.writeln('| ' + cols.map((c) => vals[c]).join(' | ') + ' |');
}

String? _readFile(String path) {
  try {
    final body = File(path).readAsStringSync();
    return body.replaceAll(RegExp(r'[^\x00-\x7F]'), '?');
  } catch (_) {
    return null;
  }
}

void _parseGaps(Map<String, String> out) {
  try {
    final data = json.decode(File('build/gaps.json').readAsStringSync());
    final src = data['totals'] ?? data['summary'];
    if (src is Map) {
      for (final k in [
        'missing_sections',
        'wordcount_out_of_range',
        'images_missing',
        'demo_count_bad',
        'drill_count_bad',
      ]) {
        final v = src[k];
        if (v is num) out[k] = '$v';
      }
    }
  } catch (_) {}
}

void _parseTerm(Map<String, String> out) {
  try {
    final data = json.decode(File('build/term_lint.json').readAsStringSync());
    final summary = data['summary'];
    if (summary is Map) {
      var sum = 0;
      summary.values.whereType<num>().forEach((n) => sum += n.toInt());
      out['term_errors'] = '$sum';
    }
  } catch (_) {}
}

void _parseLinks(Map<String, String> out) {
  try {
    final data = json.decode(File('build/links_report.json').readAsStringSync());
    var src = data['summary'];
    if (src is Map) {
      final v = src['links_missing'] ?? src['missing'] ?? src['missing_links'];
      if (v is num) out['links_missing'] = '$v';
    }
  } catch (_) {}
}

void _parseDemos(Map<String, String> out) {
  try {
    final data = json.decode(File('build/demos_steps.json').readAsStringSync());
    var src = data['summary'] ?? data['totals'];
    if (src is Map) {
      final v = src['failing_demos'] ?? src['failing'] ?? src['failures'];
      if (v is num) out['failing_demos'] = '$v';
    }
  } catch (_) {}
}
