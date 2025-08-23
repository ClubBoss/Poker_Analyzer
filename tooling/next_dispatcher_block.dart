import 'dart:convert';
import 'dart:io';
import 'ids_source.dart';

String _ascii(String s) =>
    String.fromCharCodes(s.codeUnits.where((c) => c <= 0x7F));

Map<String, String> readShortScope(String path) {
  final file = File(path);
  if (!file.existsSync()) return {};
  final text = _ascii(file.readAsStringSync());
  final data = jsonDecode(text) as Map<String, dynamic>;
  return data.map((k, v) => MapEntry(k.toString(), _ascii(v.toString())));
}

List<String> _readAllow(String path) {
  final file = File(path);
  if (!file.existsSync()) return [];
  return file.readAsLinesSync().map(_ascii).toList();
}

void _printBlock(
  String id,
  String scope,
  List<String> spot,
  List<String> token,
) {
  stdout.writeln('module_id: $id');
  stdout.writeln('short_scope: $scope');
  stdout.writeln('spotkind_allowlist:');
  if (spot.isEmpty) {
    stdout.writeln('none');
  } else {
    for (final line in spot) {
      stdout.writeln(line);
    }
  }
  stdout.writeln('target_tokens_allowlist:');
  if (token.isEmpty) {
    stdout.writeln('none');
  } else {
    for (final line in token) {
      stdout.writeln(line);
    }
  }
}

void main(List<String> args) {
  String? onlyId;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--id') {
      if (i + 1 >= args.length) {
        stderr.writeln('missing id');
        exitCode = 2;
        return;
      }
      onlyId = args[++i];
    } else {
      stderr.writeln('unknown arg: $a');
      exitCode = 2;
      return;
    }
  }

  List<String> ids;
  Map<String, String> shortScope;
  try {
    ids = readCurriculumIds();
    shortScope = readShortScope('tooling/short_scope.json');
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exitCode = 2;
    return;
  } on FileSystemException catch (e) {
    stderr.writeln(e.message);
    exitCode = 2;
    return;
  }

  stdout.writeln(_ascii('ID SOURCE: $idSource'));

  if (onlyId != null) {
    final id = onlyId;
    final scope = _ascii(shortScope[id] ?? '');
    final hasScope = scope.trim().isNotEmpty;
    final spotPath = 'tooling/allowlists/spotkind_allowlist_${id}.txt';
    final tokenPath = 'tooling/allowlists/target_tokens_allowlist_${id}.txt';
    final hasSpot = File(spotPath).existsSync();
    final hasToken = File(tokenPath).existsSync();
    final hasContent = Directory('content/$id/v1').existsSync();
    final reasons = <String>[];
    if (!hasScope) reasons.add('scope');
    if (!hasSpot) reasons.add('spot');
    if (!hasToken) reasons.add('token');
    if (hasContent) reasons.add('content');
    if (reasons.isNotEmpty) {
      stderr.writeln(reasons.join(' '));
      exitCode = 2;
      return;
    }
    final spot = _readAllow(spotPath);
    final token = _readAllow(tokenPath);
    _printBlock(id, scope, spot, token);
    return;
  }

  for (final id in ids) {
    final scope = _ascii(shortScope[id] ?? '');
    final hasScope = scope.trim().isNotEmpty;
    final spotPath = 'tooling/allowlists/spotkind_allowlist_${id}.txt';
    final tokenPath = 'tooling/allowlists/target_tokens_allowlist_${id}.txt';
    final hasSpot = File(spotPath).existsSync();
    final hasToken = File(tokenPath).existsSync();
    final hasContent = Directory('content/$id/v1').existsSync();
    if (hasScope && hasSpot && hasToken && !hasContent) {
      final spot = _readAllow(spotPath);
      final token = _readAllow(tokenPath);
      _printBlock(id, scope, spot, token);
      return;
    }
  }

  stdout.writeln('none');
}
