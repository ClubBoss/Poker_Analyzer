import 'dart:convert';
import 'dart:io';

import 'ids_source.dart';

String _ascii(String s) =>
    String.fromCharCodes(s.codeUnits.where((c) => c <= 0x7F));

Map<String, String> readShortScope(String path) {
  final file = File(path);
  if (!file.existsSync()) return {};
  try {
    final text = _ascii(file.readAsStringSync());
    final data = jsonDecode(text) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k.toString(), v.toString()));
  } on FormatException {
    throw FileSystemException('invalid json', path);
  } on IOException {
    throw FileSystemException('read error', path);
  }
}

Map<String, bool> computeFlags(String id, Map<String, String> shortScope) {
  final hasShort = shortScope[id]?.trim().isNotEmpty ?? false;
  final hasSpot = File(
    'tooling/allowlists/spotkind_allowlist_${id}.txt',
  ).existsSync();
  final hasToken = File(
    'tooling/allowlists/target_tokens_allowlist_${id}.txt',
  ).existsSync();
  final ready = hasShort && hasSpot && hasToken;
  final hasContent = Directory('content/$id/v1').existsSync();
  return {
    'short': hasShort,
    'spot': hasSpot,
    'token': hasToken,
    'ready': ready,
    'content': hasContent,
  };
}

void printTable(List<Map<String, dynamic>> modules) {
  stdout.writeln('id | short | spot | token | ready | content');
  for (final m in modules) {
    final id = m['id'];
    final flagShort = m['short'] ? 'Y' : 'N';
    final flagSpot = m['spot'] ? 'Y' : 'N';
    final flagToken = m['token'] ? 'Y' : 'N';
    final flagReady = m['ready'] ? 'Y' : 'N';
    final flagContent = m['content'] ? 'Y' : 'N';
    stdout.writeln(
      '$id |  $flagShort |  $flagSpot |   $flagToken |   $flagReady |   $flagContent',
    );
  }
}

void printJson(List<Map<String, dynamic>> modules, String? next) {
  final list = modules
      .map(
        (m) => {
          'id': m['id'],
          'short': m['short'],
          'spot': m['spot'],
          'token': m['token'],
          'ready': m['ready'],
          'content': m['content'],
        },
      )
      .toList();
  stdout.writeln(jsonEncode(list));
  stdout.writeln(jsonEncode({'next': next ?? 'none'}));
}

void main(List<String> args) {
  String? onlyId;
  var jsonMode = false;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--only') {
      if (i + 1 >= args.length) {
        stderr.writeln('missing id for --only');
        exitCode = 2;
        return;
      }
      onlyId = args[++i];
    } else if (a == '--json') {
      jsonMode = true;
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
    exitCode = 4;
    return;
  }

  stdout.writeln('ID SOURCE: $idSource');

  final modules = ids
      .map((id) => {'id': id, ...computeFlags(id, shortScope)})
      .toList();

  if (onlyId != null) {
    modules.retainWhere((m) => m['id'] == onlyId);
    if (modules.isEmpty) {
      stderr.writeln('id not found: $onlyId');
      exitCode = 2;
      return;
    }
  }

  final total = modules.length;
  final readyCount = modules.where((m) => m['ready'] as bool).length;
  final contentCount = modules.where((m) => m['content'] as bool).length;
  String? nextId;
  for (final m in ids) {
    final flags = computeFlags(m, shortScope);
    if (flags['ready']! && !flags['content']!) {
      nextId = m;
      break;
    }
  }

  if (jsonMode) {
    printJson(modules, nextId);
  } else {
    printTable(modules);
    stdout.writeln('TOTAL: $total');
    stdout.writeln('READY: $readyCount  CONTENT: $contentCount');
    stdout.writeln('NEXT: ${nextId ?? 'none'}');
  }
}
