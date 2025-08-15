// Prints a summary of a training_v1 bundle.
// Usage: --feed=FILE [--root DIR]

import 'dart:io';

import '../../lib/cross/runtime_loader.dart';

void main(List<String> args) {
  try {
    final opts = _parseArgs(args);
    final feed = File(opts.feed);
    final rootPath = opts.root ?? feed.parent.path;
    final bundle = loadTrainingBundle(
      feedJson: feed,
      root: Directory(rootPath),
    );
    final sessions = bundle.sessions;
    final l2 = sessions.where((s) => s.kind == FeedKind.l2_session).length;
    final l3 = sessions.where((s) => s.kind == FeedKind.l3_session).length;
    final total = totalItems(bundle);
    stdout.writeln(
      'bundle ${bundle.version} ok: sessions=${sessions.length} total=$total l2=$l2 l3=$l3',
    );
    for (var i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      stdout.writeln(
        '  [$i] kind=${s.kind.name} count=${s.count} file=${s.path}',
      );
    }
    exit(0);
  } catch (_) {
    _usage();
  }
}

class _Opts {
  final String feed;
  final String? root;
  _Opts(this.feed, this.root);
}

_Opts _parseArgs(List<String> args) {
  String? feed;
  String? root;
  for (final a in args) {
    if (a.startsWith('--feed=')) {
      feed = a.substring(7);
    } else if (a.startsWith('--root=')) {
      root = a.substring(7);
    } else {
      throw const FormatException('bad arg');
    }
  }
  if (feed == null || feed.isEmpty) {
    throw const FormatException('missing feed');
  }
  return _Opts(feed, root);
}

Never _usage() {
  stdout.writeln('usage: --feed=FILE [--root DIR]');
  exit(2);
}
