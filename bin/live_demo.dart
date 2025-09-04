// ASCII-only; pure Dart (no Flutter deps)

import 'dart:io';

import 'package:poker_analyzer/live/live_runtime.dart';
import 'package:poker_analyzer/live/live_defaults.dart';
import 'package:poker_analyzer/live/live_context_format.dart';
import 'package:poker_analyzer/live/live_integration.dart';

void main(List<String> args) {
  final parsed = _parseArgs(args);
  if (parsed is _ArgError) {
    stderr.writeln('Error: ' + parsed.message);
    _printUsage();
    exit(1);
  }

  final cfg = parsed as _Config;

  // Set global mode for LiveRuntime helpers.
  LiveRuntime.setMode(cfg.mode);

  if (cfg.moduleId == null || cfg.moduleId!.isEmpty) {
    // Iterate all known live module IDs.
    for (final id in kLiveDefaults.keys) {
      final badges = LiveRuntime.badgesForModule(id);
      final ctx = LiveRuntime.contextFor(id);
      final subtitle = liveContextSubtitle(ctx);
      stdout.writeln('module: ' + id);
      stdout.writeln(' mode: ' + (LiveRuntime.isLive ? 'live' : 'online'));
      stdout.writeln(' badges: ' + (badges.isEmpty ? '-' : badges.join(', ')));
      stdout.writeln(' subtitle: ' + (subtitle.isEmpty ? '-' : subtitle));
      stdout.writeln(' isOff: ' + (ctx.isOff ? 'true' : 'false'));
      stdout.writeln('');
    }
    exit(0);
  }

  final id = cfg.moduleId!;

  // Print current module info and evaluate live warnings.
  final badges = LiveRuntime.badgesForModule(id);
  final ctx = LiveRuntime.contextFor(id);
  final subtitle = liveContextSubtitle(ctx);
  stdout.writeln('module: ' + id);
  stdout.writeln(' mode: ' + (LiveRuntime.isLive ? 'live' : 'online'));
  stdout.writeln(' badges: ' + (badges.isEmpty ? '-' : badges.join(', ')));
  stdout.writeln(' subtitle: ' + (subtitle.isEmpty ? '-' : subtitle));
  stdout.writeln(' isOff: ' + (ctx.isOff ? 'true' : 'false'));

  final warning = liveWarningIfAny(
    moduleId: id,
    mode: cfg.mode,
    announced: cfg.announced,
    chipMotions: cfg.chipMotions,
    singleMotion: cfg.singleMotion,
    bettorWasAggressor: cfg.bettorWasAggressor,
    bettorShowedFirst: cfg.bettorShowedFirst,
    headsUp: cfg.headsUp,
    firstActiveLeftOfBtnShowed: cfg.firstActiveLeftOfBtnShowed,
  );
  stdout.writeln(' warning: ' + (warning.isEmpty ? 'OK' : warning));
  exit(0);
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart run bin/live_demo.dart [--mode=online|live] '
    '[--module=<id>] [--announced=true|false] [--chipMotions=<int>] '
    '[--singleMotion=true|false] [--agg=true|false] '
    '[--showed=true|false] [--headsUp=true|false] '
    '[--firstLeftShowed=true|false]',
  );
  stdout.writeln(
    'Defaults: mode=online, announced=false, chipMotions=1, '
    'singleMotion=true, agg=true, showed=true, headsUp=false, '
    'firstLeftShowed=true',
  );
}

class _Config {
  final TrainingMode mode;
  final String? moduleId;
  final bool announced;
  final int chipMotions;
  final bool singleMotion;
  final bool bettorWasAggressor; // agg
  final bool bettorShowedFirst; // showed
  final bool headsUp;
  final bool firstActiveLeftOfBtnShowed; // firstLeftShowed

  const _Config({
    required this.mode,
    required this.moduleId,
    required this.announced,
    required this.chipMotions,
    required this.singleMotion,
    required this.bettorWasAggressor,
    required this.bettorShowedFirst,
    required this.headsUp,
    required this.firstActiveLeftOfBtnShowed,
  });
}

class _ArgError {
  final String message;
  const _ArgError(this.message);
}

Object _parseArgs(List<String> args) {
  TrainingMode mode = TrainingMode.online;
  String? moduleId;
  bool announced = false;
  int chipMotions = 1;
  bool singleMotion = true;
  bool agg = true;
  bool showed = true;
  bool headsUp = false;
  bool firstLeftShowed = true;

  for (final raw in args) {
    if (!raw.startsWith('--') || !raw.contains('=')) {
      return const _ArgError('Arguments must be in --key=value form.');
    }
    final eq = raw.indexOf('=');
    final key = raw.substring(2, eq);
    final value = raw.substring(eq + 1);

    switch (key) {
      case 'mode':
        if (value == 'online') {
          mode = TrainingMode.online;
        } else if (value == 'live') {
          mode = TrainingMode.live;
        } else {
          return _ArgError('Invalid mode: ' + value);
        }
        break;
      case 'module':
        moduleId = value;
        break;
      case 'announced':
        final b = _parseBool(value);
        if (b == null)
          return _ArgError('Invalid boolean for announced: ' + value);
        announced = b;
        break;
      case 'chipMotions':
        final n = int.tryParse(value);
        if (n == null || n < 0) {
          return _ArgError('Invalid integer for chipMotions: ' + value);
        }
        chipMotions = n;
        break;
      case 'singleMotion':
        final b = _parseBool(value);
        if (b == null)
          return _ArgError('Invalid boolean for singleMotion: ' + value);
        singleMotion = b;
        break;
      case 'agg':
        final b = _parseBool(value);
        if (b == null) return _ArgError('Invalid boolean for agg: ' + value);
        agg = b;
        break;
      case 'showed':
        final b = _parseBool(value);
        if (b == null) return _ArgError('Invalid boolean for showed: ' + value);
        showed = b;
        break;
      case 'headsUp':
        final b = _parseBool(value);
        if (b == null)
          return _ArgError('Invalid boolean for headsUp: ' + value);
        headsUp = b;
        break;
      case 'firstLeftShowed':
        final b = _parseBool(value);
        if (b == null) {
          return _ArgError('Invalid boolean for firstLeftShowed: ' + value);
        }
        firstLeftShowed = b;
        break;
      default:
        return _ArgError('Unknown option: --' + key);
    }
  }

  return _Config(
    mode: mode,
    moduleId: moduleId,
    announced: announced,
    chipMotions: chipMotions,
    singleMotion: singleMotion,
    bettorWasAggressor: agg,
    bettorShowedFirst: showed,
    headsUp: headsUp,
    firstActiveLeftOfBtnShowed: firstLeftShowed,
  );
}

bool? _parseBool(String s) {
  if (s == 'true') return true;
  if (s == 'false') return false;
  return null;
}
