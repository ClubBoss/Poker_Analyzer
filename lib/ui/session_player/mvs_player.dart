// Example:
// Navigator.of(context).push(MaterialPageRoute(
//   builder: (_) => Scaffold(body: MvsSessionPlayer(spots: demoSpots())),
// ));

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb & defaultTargetPlatform
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import '../../widgets/active_timebar.dart';
import 'hotkeys_sheet.dart';
import 'mini_toast.dart';
import 'models.dart';
import 'result_summary.dart';
import 'ui_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension _UiPrefsCopy on UiPrefs {
  UiPrefs copyWith({
    bool? autoNext,
    bool? timeEnabled,
    int? timeLimitMs,
    bool? sound,
    bool? haptics,
    bool? autoWhyOnWrong,
    int? autoNextDelayMs,
    double? fontScale,
  }) {
    return UiPrefs(
      autoNext: autoNext ?? this.autoNext,
      timeEnabled: timeEnabled ?? this.timeEnabled,
      timeLimitMs: timeLimitMs ?? this.timeLimitMs,
      sound: sound ?? this.sound,
      haptics: haptics ?? this.haptics,
      autoWhyOnWrong: autoWhyOnWrong ?? this.autoWhyOnWrong,
      autoNextDelayMs: autoNextDelayMs ?? this.autoNextDelayMs,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}

class MvsSessionPlayer extends StatefulWidget {
  final List<UiSpot> spots;
  final int? initialIndex;
  final List<UiAnswer>? initialAnswers;
  const MvsSessionPlayer(
      {super.key, required this.spots, this.initialIndex, this.initialAnswers});

  static Future<MvsSessionPlayer?> fromSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('resume_active') ?? false)) return null;
    final s = prefs.getString('resume_spots');
    final i = prefs.getInt('resume_index');
    final a = prefs.getString('resume_answers');
    if (s == null || i == null || a == null) return null;
    try {
      final spotsData = jsonDecode(s);
      final answersData = jsonDecode(a);
      if (spotsData is! List || answersData is! List) return null;
      final spots = <UiSpot>[];
      for (final e in spotsData) {
        if (e is Map<String, dynamic>) {
          final k = e['k'];
          final h = e['h'];
          final p = e['p'];
          final st = e['s'];
          final act = e['a'];
          if (k is int && h is String && p is String && st is String && act is String) {
            spots.add(UiSpot(
              kind: SpotKind.values[k],
              hand: h,
              pos: p,
              stack: st,
              action: act,
              vsPos: e['v'] as String?,
              limpers: e['l'] as String?,
              explain: e['e'] as String?,
            ));
          } else {
            return null;
          }
        } else {
          return null;
        }
      }
      final answers = <UiAnswer>[];
      for (final e in answersData) {
        if (e is Map<String, dynamic>) {
          final c = e['correct'];
          final ex = e['expected'];
          final ch = e['chosen'];
          final ms = e['elapsedMs'];
          if (c is bool && ex is String && ch is String && ms is int) {
            answers.add(UiAnswer(
              correct: c,
              expected: ex,
              chosen: ch,
              elapsed: Duration(milliseconds: ms),
            ));
          } else {
            return null;
          }
        } else {
          return null;
        }
      }
      if (i < 0 || i > spots.length) return null;
      return MvsSessionPlayer(
          spots: spots, initialIndex: i, initialAnswers: answers);
    } catch (_) {
      return null;
    }
  }

  @override
  State<MvsSessionPlayer> createState() => _MvsSessionPlayerState();
}

class _MvsSessionPlayerState extends State<MvsSessionPlayer>
    with TickerProviderStateMixin {
  late List<UiSpot> _spots;
  int _index = 0;
  final _answers = <UiAnswer>[];
  final _timer = Stopwatch();
  final _focusNode = FocusNode();
  Timer? _ticker;
  Timer? _autoNextTimer;
  List<UiSpot>? _lastLoadedSpots;
  String? _chosen;
  bool _showExplain = false;
  UiPrefs _prefs = const UiPrefs(
      autoNext: false,
      timeEnabled: true,
      timeLimitMs: 10000,
      sound: false,
      haptics: true,
      autoWhyOnWrong: false,
      autoNextDelayMs: 600,
      fontScale: 1.0);
  bool _autoNext = false;
  int _timeLimitMs = 10000; // 10s default
  bool _timeEnabled = true; // can toggle
  int _timeLeftMs = 10000;
  Timer? _timebarTicker; // separate from _ticker
  late final AnimationController _answerPulseCtrl;
  late final Animation<double> _answerPulse;
  AnimationController? _autoNextAnim;
  Color? _answerFlashColor;
  Timer? _answerFlashTimer;
  bool _paused = false;

  bool get _showHotkeys =>
      kIsWeb ||
      const {TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux}
          .contains(defaultTargetPlatform);

  @override
  void initState() {
    super.initState();
    _spots = widget.spots;
    _index = widget.initialIndex ?? 0;
    _answers.addAll(widget.initialAnswers ?? const []);
    _timer.start();
    _startTicker();
    _startTimebar();
    _answerPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _answerPulse = Tween(begin: 1.0, end: 1.05)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_answerPulseCtrl);
    loadUiPrefs().then((p) {
      if (!mounted) return;
      setState(() {
        _prefs = p;
        _autoNext = p.autoNext;
        _timeEnabled = p.timeEnabled;
        _timeLeftMs = _timeLimitMs = p.timeLimitMs;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _autoNextTimer?.cancel();
    _timebarTicker?.cancel();
    _answerFlashTimer?.cancel();
    _answerPulseCtrl.dispose();
    _autoNextAnim?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker =
        Timer.periodic(const Duration(milliseconds: 200), (_) => setState(() {}));
  }

  void _startTimebar() {
    _timebarTicker?.cancel();
    if (!_timeEnabled) {
      _timeLeftMs = _timeLimitMs;
      return;
    }
    _timeLeftMs = _timeLimitMs;
    _timebarTicker =
        Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _chosen != null) return;
      setState(() {
        _timeLeftMs -= 100;
        if (_timeLeftMs <= 0) {
          _timeLeftMs = 0;
          _timebarTicker?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Time up')),
          );
          if (_prefs.haptics) {
            try {
              HapticFeedback.vibrate();
            } catch (_) {}
          }
        }
      });
    });
  }

  void _cancelAutoNextAnim() {
    _autoNextAnim?.stop();
    _autoNextAnim?.dispose();
    _autoNextAnim = null;
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('resume_active', true);
    await prefs.setString(
        'resume_spots',
        jsonEncode(_spots
            .map((s) => {
                  'k': s.kind.index,
                  'h': s.hand,
                  'p': s.pos,
                  's': s.stack,
                  'a': s.action,
                  if (s.vsPos != null) 'v': s.vsPos,
                  if (s.limpers != null) 'l': s.limpers,
                  if (s.explain != null) 'e': s.explain,
                })
            .toList()));
    await prefs.setInt('resume_index', _index);
    await prefs.setString(
        'resume_answers',
        jsonEncode(_answers
            .map((a) => {
                  'correct': a.correct,
                  'expected': a.expected,
                  'chosen': a.chosen,
                  'elapsedMs': a.elapsed.inMilliseconds,
                })
            .toList()));
  }

  Future<void> _clearSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('resume_active', false);
    await prefs.remove('resume_spots');
    await prefs.remove('resume_index');
    await prefs.remove('resume_answers');
  }

  void _togglePause() {
    if (_paused) {
      setState(() => _paused = false);
      _timer.start();
      _startTicker();
      if (_chosen == null && _timeEnabled) _startTimebar();
      unawaited(showMiniToast(context, 'Resumed'));
      if (_prefs.haptics) {
        try {
          HapticFeedback.selectionClick();
        } catch (_) {}
      }
    } else {
      _ticker?.cancel();
      _timebarTicker?.cancel();
      _cancelAutoNextAnim();
      _timer.stop();
      setState(() => _paused = true);
      unawaited(showMiniToast(context, 'Paused'));
      if (_prefs.haptics) {
        try {
          HapticFeedback.selectionClick();
        } catch (_) {}
      }
    }
  }

  void _onAction(String action) {
    if (_chosen != null) return;
    _timer.stop();
    _ticker?.cancel();
    _timebarTicker?.cancel();
    final spot = _spots[_index];
    final autoWhy = _prefs.autoWhyOnWrong;
    final jam = spot.kind.name.contains('_jam_vs_');
    final correct = action == spot.action;
    // mobile haptics
    if (_prefs.haptics) {
      try {
        if (correct) {
          HapticFeedback.lightImpact();
        } else {
          HapticFeedback.mediumImpact();
        }
      } catch (_) {}
    }
    if (_prefs.sound) {
      SystemSound.play(
          correct ? SystemSoundType.click : SystemSoundType.alert);
    }
    setState(() {
      _chosen = action;
      _answers.add(UiAnswer(
        correct: correct,
        expected: spot.action,
        chosen: action,
        elapsed: _timer.elapsed,
      ));
      if (!correct && autoWhy && jam) {
        _showExplain = true;
      }
    });
    unawaited(_saveProgress());
    // micro-feedback: toast + pulse + flash tint
    unawaited(showMiniToast(context, correct ? 'Correct' : 'Wrong'));
    _answerPulseCtrl.forward(from: 0.0);
    setState(() {
      _answerFlashColor =
          (correct ? Colors.green : Colors.red).withOpacity(0.12);
    });
    _answerFlashTimer?.cancel();
    _answerFlashTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _answerFlashColor = null);
    });
    if (correct && _autoNext) {
      _autoNextTimer?.cancel();
      final delay = Duration(milliseconds: _prefs.autoNextDelayMs);
      _cancelAutoNextAnim();
      _autoNextAnim = AnimationController(vsync: this, duration: delay)
        ..addListener(() {
          if (mounted) setState(() {});
        })
        ..forward();
      _autoNextTimer = Timer(delay, () {
        if (!mounted) return;
        if (_chosen != null && _answers[_index].correct) _next();
      });
    } else {
      _cancelAutoNextAnim();
    }
  }

  void _undo() {
    if (_answers.isEmpty) return;
    _autoNextTimer?.cancel();
    _cancelAutoNextAnim();
    _timebarTicker?.cancel();
    setState(() {
      _index = (_index - 1).clamp(0, _spots.length - 1);
      _answers.removeLast();
      _chosen = null;
      _showExplain = false;
      _timer
        ..reset()
        ..start();
      _answerFlashColor = null;
    });
    _startTicker();
    _startTimebar();
    unawaited(_saveProgress());
    if (_prefs.haptics) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }
    unawaited(showMiniToast(context, 'Undo'));
  }

  void _skip() {
    if (_index >= _spots.length || _chosen != null) return;
    _autoNextTimer?.cancel();
    _cancelAutoNextAnim();
    _timebarTicker?.cancel();
    final spot = _spots[_index];
    setState(() {
      // считаем пропуск как неправильный ответ,
      // чтобы длины spots/answers оставались согласованы
      _answers.add(UiAnswer(
        correct: false,
        expected: spot.action,
        chosen: '(skip)',
        elapsed: _timer.elapsed,
      ));
      _index++;
      _chosen = null;
      _showExplain = false;
      _timer
        ..reset()
        ..start();
      _answerFlashColor = null;
    });
    if (_index < _spots.length) {
      _startTicker();
      _startTimebar();
      _focusNode.requestFocus();
    }
    unawaited(_saveProgress());
    if (_prefs.haptics) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }
    unawaited(showMiniToast(context, 'Skipped'));
  }

  int _streak() {
    var s = 0;
    for (int i = _answers.length - 1; i >= 0; i--) {
      if (_answers[i].correct) {
        s++;
      } else {
        break;
      }
    }
    return s;
  }

  void _next() {
    _autoNextTimer?.cancel();
    _cancelAutoNextAnim();
    _answerFlashTimer?.cancel();
    _answerFlashColor = null;
    if (_index + 1 >= _spots.length) {
      setState(() => _index++);
      _appendSessionHistory();
      return;
    }
    setState(() {
      _index++;
      _chosen = null;
      _showExplain = false;
      _timer
        ..reset()
        ..start();
    });
    unawaited(_saveProgress());
    _startTicker();
    _startTimebar();
    _focusNode.requestFocus();
  }

  void _appendSessionHistory() {
    unawaited(_clearSaved());
    if (kIsWeb) return;
    final total = _spots.length;
    final correct = _answers.where((a) => a.correct).length;
    final acc = total == 0 ? 0.0 : correct / total;
    final obj = {
      'ts': DateTime.now().toUtc().toIso8601String(),
      'acc': acc,
      'total': total,
      'correct': correct,
      'spots': [
        for (final s in _spots)
          {
            'k': s.kind.index,
            'h': s.hand,
            'p': s.pos,
            's': s.stack,
            'a': s.action,
            if (s.vsPos != null) 'v': s.vsPos,
            if (s.limpers != null) 'l': s.limpers,
            if (s.explain != null) 'e': s.explain,
          }
      ],
      'wrongIdx': [
        for (var i = 0; i < _answers.length; i++)
          if (!_answers[i].correct) i
      ],
    };
    try {
      final dir = Directory('out');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file = File('${dir.path}/sessions_history.jsonl');
      file.writeAsStringSync('${jsonEncode(obj)}\n',
          mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  void _restart(List<UiSpot> spots) {
    _autoNextTimer?.cancel();
    _cancelAutoNextAnim();
    _answerFlashTimer?.cancel();
    _answerFlashColor = null;
    setState(() {
      _spots = spots;
      _index = 0;
      _answers.clear();
      _chosen = null;
      _paused = false;
      _showExplain = false;
      _timer
        ..reset()
        ..start();
    });
    _startTicker();
    _startTimebar();
    _focusNode.requestFocus();
  }

  void _replayErrors() {
    final wrong = <UiSpot>[];
    // идём по имеющимся ответам; пропуски уже помечены как incorrect
    for (var i = 0; i < _answers.length; i++) {
      if (!_answers[i].correct) wrong.add(_spots[i]);
    }
    if (wrong.isEmpty) {
      _restart(widget.spots);
    } else {
      _restart(wrong);
    }
  }

  Future<void> _loadJsonlSpots() async {
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['jsonl']);
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      String? content;
      if (f.path != null) {
        content = await File(f.path!).readAsString();
      } else if (f.bytes != null) {
        content = utf8.decode(f.bytes!);
      }
      if (content == null) return;
      final lines = const LineSplitter().convert(content);
      final parsed = <UiSpot>[];
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final obj = jsonDecode(line);
          if (obj is! Map) continue;
          final k = obj['kind'];
          final hand = obj['hand'];
          final pos = obj['pos'];
          final vsPos = obj['vsPos'];
          final stack = obj['stack'];
          final action = obj['action'];
          if (k is! String ||
              hand is! String ||
              pos is! String ||
              stack is! String ||
              action is! String) {
            continue;
          }
          SpotKind? kind;
          for (final sk in SpotKind.values) {
            if (sk.name == k) {
              kind = sk;
              break;
            }
          }
          if (kind == null) continue;
          final acts = _actionsFor(kind);
          if (!listEquals(acts, const ['jam', 'fold']) ||
              !acts.contains(action)) {
            continue;
          }
          parsed.add(UiSpot(
            kind: kind,
            hand: hand,
            pos: pos,
            vsPos: vsPos is String ? vsPos : null,
            stack: stack,
            action: action,
          ));
        } catch (_) {}
      }
      if (parsed.isEmpty) return;
      _lastLoadedSpots = parsed;
      _restart(parsed);
      showMiniToast(context, 'Loaded ${parsed.length} spots');
    } catch (_) {}
  }

  Future<void> _loadClipboardJsonlSpots() async {
    try {
      final data = await Clipboard.getData('text/plain');
      final content = data?.text;
      if (content == null) return;
      final lines = const LineSplitter().convert(content);
      final parsed = <UiSpot>[];
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final obj = jsonDecode(line);
          if (obj is! Map) continue;
          final k = obj['kind'];
          final hand = obj['hand'];
          final pos = obj['pos'];
          final vsPos = obj['vsPos'];
          final stack = obj['stack'];
          final action = obj['action'];
          if (k is! String ||
              hand is! String ||
              pos is! String ||
              stack is! String ||
              action is! String) {
            continue;
          }
          SpotKind? kind;
          for (final sk in SpotKind.values) {
            if (sk.name == k) {
              kind = sk;
              break;
            }
          }
          if (kind == null) continue;
          final acts = _actionsFor(kind);
          if (!listEquals(acts, const ['jam', 'fold']) ||
              !acts.contains(action)) {
            continue;
          }
          parsed.add(UiSpot(
            kind: kind,
            hand: hand,
            pos: pos,
            vsPos: vsPos is String ? vsPos : null,
            stack: stack,
            action: action,
          ));
        } catch (_) {}
      }
      if (parsed.isEmpty) return;
      _lastLoadedSpots = parsed;
      _restart(parsed);
      showMiniToast(context, 'Loaded ${parsed.length} spots (clipboard)');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (_index >= _spots.length) {
      child = ResultSummaryView(
        key: const ValueKey('summary'),
        spots: _spots,
        answers: _answers,
        onReplayErrors: _replayErrors,
        onRestart: () => _restart(widget.spots),
        onReplayOne: (i) {
          if (i < 0 || i >= _spots.length) return;
          _restart([_spots[i]]);
        },
        onReplayMarked: (indices) {
          if (indices.isEmpty) return;
          final picks = <UiSpot>[];
          for (final i in indices) {
            if (i >= 0 && i < _spots.length) picks.add(_spots[i]);
          }
          if (picks.isEmpty) return;
          _restart(picks);
        },
      );
    } else {
      child = _buildSpotCard(_spots[_index]);
    }
    final mq = MediaQuery.of(context);
    final scaled = mq.copyWith(
      textScaler: TextScaler.linear((_prefs.fontScale).clamp(0.9, 1.3)),
    );
    final player = MediaQuery(data: scaled, child: child);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: _answers.isEmpty ? null : _undo,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            tooltip: 'Skip',
            onPressed:
                (_index >= _spots.length || _chosen != null) ? null : _skip,
          ),
          IconButton(
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
            tooltip: _paused ? 'Resume' : 'Pause',
            onPressed: _togglePause,
          ),
          if (_showHotkeys)
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.black87,
                  isScrollControlled: false,
                  builder: (_) => const HotkeysSheet(),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () async {
              final r = await showModalBottomSheet<Map<String, dynamic>>(
                context: context,
                isScrollControlled: true,
                builder: (ctx) {
                  bool autoNext = _autoNext;
                  bool timeEnabled = _timeEnabled;
                  int limit = _timeLimitMs;
                  int delayMs = _prefs.autoNextDelayMs.clamp(300, 800);
                  bool sound = _prefs.sound;
                  bool haptics = _prefs.haptics;
                  bool autoWhy = _prefs.autoWhyOnWrong;
                  double fontScale = _prefs.fontScale;
                  final ctrl =
                      TextEditingController(text: limit.toString());
                  return Padding(
                    padding:
                        MediaQuery.of(ctx).viewInsets + const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          const Text('Auto-next'),
                          const Spacer(),
                          Switch(
                              value: autoNext,
                              onChanged: (v) {
                                autoNext = v;
                                (ctx as Element).markNeedsBuild();
                              })
                        ]),
                        Row(children: [
                          const Text('Auto-next delay'),
                          Expanded(
                            child: Slider(
                              value: delayMs.toDouble(),
                              min: 300,
                              max: 800,
                              divisions: 10,
                              label: '${delayMs} ms',
                              onChanged: autoNext
                                  ? (v) {
                                      delayMs =
                                          v.round().clamp(300, 800);
                                      (ctx as Element).markNeedsBuild();
                                    }
                                  : null,
                            ),
                          ),
                          SizedBox(
                              width: 56,
                              child:
                                  Text('${delayMs} ms', textAlign: TextAlign.end)),
                        ]),
                        Row(children: [
                          const Text('Answer timer'),
                          const Spacer(),
                          Switch(
                              value: timeEnabled,
                              onChanged: (v) {
                                timeEnabled = v;
                                (ctx as Element).markNeedsBuild();
                              })
                        ]),
                        const SizedBox(height: 8),
                        TextField(
                          controller: ctrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(signed: false, decimal: false),
                          decoration:
                              const InputDecoration(labelText: 'Time limit ms'),
                          onChanged: (_) {
                            final t = int.tryParse(ctrl.text);
                            if (t != null) limit = t;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Text('Sound'),
                          const Spacer(),
                          Switch(
                              value: sound,
                              onChanged: (v) {
                                sound = v;
                                (ctx as Element).markNeedsBuild();
                              })
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Text('Haptics'),
                          const Spacer(),
                          Switch(
                              value: haptics,
                              onChanged: (v) {
                                haptics = v;
                                (ctx as Element).markNeedsBuild();
                              })
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Text('Font size'),
                          const Spacer(),
                          ChoiceChip(
                              label: const Text('L'),
                              selected: fontScale <= 1.0,
                              onSelected: (_) {
                                fontScale = 1.0;
                                (ctx as Element).markNeedsBuild();
                              }),
                          const SizedBox(width: 8),
                          ChoiceChip(
                              label: const Text('XL'),
                              selected: fontScale > 1.0,
                              onSelected: (_) {
                                fontScale = 1.15;
                                (ctx as Element).markNeedsBuild();
                              }),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Text('Auto Why on wrong'),
                          const Spacer(),
                          Switch(
                              value: autoWhy,
                              onChanged: (v) {
                                autoWhy = v;
                                (ctx as Element).markNeedsBuild();
                              })
                        ]),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel')),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx, {
                                  "autoNext": autoNext,
                                  "autoNextDelayMs": delayMs,
                                  "timeEnabled": timeEnabled,
                                  "timeLimitMs": limit,
                                  "sound": sound,
                                  "haptics": haptics,
                                  "autoWhyOnWrong": autoWhy,
                                  "fontScale": fontScale,
                                });
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
              if (r != null) {
                final p = UiPrefs(
                  autoNext: r["autoNext"] == true,
                  timeEnabled: r["timeEnabled"] == true,
                  timeLimitMs: (r["timeLimitMs"] is int)
                      ? r["timeLimitMs"] as int
                      : _timeLimitMs,
                  sound: r["sound"] == true,
                  haptics: r["haptics"] == true,
                  autoWhyOnWrong: r["autoWhyOnWrong"] == true,
                  autoNextDelayMs: (r["autoNextDelayMs"] is int)
                      ? (r["autoNextDelayMs"] as int).clamp(300, 800)
                      : _prefs.autoNextDelayMs,
                  fontScale: (r["fontScale"] is num)
                      ? (r["fontScale"] as num).toDouble()
                      : _prefs.fontScale,
                );
                await saveUiPrefs(p);
                if (!mounted) return;
                setState(() {
                  _prefs = p;
                  _autoNext = p.autoNext;
                  _timeEnabled = p.timeEnabled;
                  _timeLimitMs = p.timeLimitMs;
                  if (_chosen == null) _startTimebar();
                  if (!_autoNext) _cancelAutoNextAnim();
                });
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _paused,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: player,
            ),
          ),
          if (_autoNextAnim?.isAnimating == true)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _autoNextAnim!.value,
                minHeight: 2,
              ),
            ),
          if (_paused)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pause_circle_filled,
                            size: 56, color: Colors.white70),
                        SizedBox(height: 8),
                        Text('Paused',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpotCard(UiSpot spot) {
    final actions = _actionsFor(spot.kind);
    final jamFoldHotkeys = _showHotkeys &&
        spot.kind.name.contains('_jam_vs_') &&
        listEquals(actions, const ['jam', 'fold']);
    final correctCnt = _answers.where((a) => a.correct).length;
    final acc = _answers.isEmpty ? 0.0 : correctCnt / _answers.length;
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final vx = details.primaryVelocity ?? 0;
        if (vx > 350 && _answers.isNotEmpty) {
          _undo();
        } else if (vx < -350 && _chosen == null) {
          _skip();
        }
      },
      child: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: (event) {
          if (event is! RawKeyDownEvent || _paused) return;
          if (_showHotkeys && event.logicalKey == LogicalKeyboardKey.keyO) {
            _loadJsonlSpots();
            return;
          }
          if (_showHotkeys && event.logicalKey == LogicalKeyboardKey.keyP) {
            _loadClipboardJsonlSpots();
            return;
          }
          if (_showHotkeys && event.logicalKey == LogicalKeyboardKey.keyR) {
            if (_lastLoadedSpots != null && _lastLoadedSpots!.isNotEmpty) {
              _restart(_lastLoadedSpots!);
            }
            return;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyA) {
            final v = !_autoNext;
            final p = _prefs.copyWith(autoNext: v);
            setState(() {
              _autoNext = v;
              if (!v) _cancelAutoNextAnim();
              _prefs = p;
            });
            saveUiPrefs(p);
            return;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyT) {
            final v = !_timeEnabled;
            final p = _prefs.copyWith(timeEnabled: v);
            setState(() {
              _timeEnabled = v;
              if (_chosen == null) _startTimebar();
              _prefs = p;
            });
            saveUiPrefs(p);
            return;
          }
          if (_showHotkeys && event.logicalKey == LogicalKeyboardKey.keyY) {
            final p =
                _prefs.copyWith(autoWhyOnWrong: !_prefs.autoWhyOnWrong);
            setState(() {
              _prefs = p;
            });
            saveUiPrefs(p);
            return;
          }
          if (_chosen == null) {
            if (event.logicalKey == LogicalKeyboardKey.digit1 &&
                actions.length > 0) {
              _onAction(actions[0]);
            } else if (event.logicalKey == LogicalKeyboardKey.digit2 &&
                actions.length > 1) {
              _onAction(actions[1]);
            } else if (event.logicalKey == LogicalKeyboardKey.digit3 &&
                actions.length > 2) {
              _onAction(actions[2]);
            } else if (_showHotkeys &&
                spot.kind.name.contains('_jam_vs_') &&
                actions.length == 2 &&
                actions[0] == 'jam' &&
                actions[1] == 'fold') {
              if (event.logicalKey == LogicalKeyboardKey.keyJ) {
                _onAction('jam');
              } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
                _onAction('fold');
              }
            }
          } else {
            if (event.logicalKey == LogicalKeyboardKey.keyH) {
              setState(() => _showExplain = !_showExplain);
            } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space) {
              _next();
            }
          }
      },
      child: Padding(
        key: ValueKey('spot$_index'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Spot ${_index + 1}/${_spots.length}'),
                Text(
                    't=${(_timer.elapsedMilliseconds / 1000).toStringAsFixed(1)}s'),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (_index + 1) / _spots.length,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Accuracy ${(acc * 100).toStringAsFixed(0)}%'),
                const SizedBox(width: 12),
                Text('Streak ${_streak()}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Answer timer'),
                const Spacer(),
                Switch(
                  value: _timeEnabled,
                  onChanged: (v) {
                    final p = _prefs.copyWith(timeEnabled: v);
                    setState(() {
                      _timeEnabled = v;
                      if (_chosen == null) _startTimebar();
                      _prefs = p;
                    });
                    saveUiPrefs(p);
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            if (_chosen == null && _timeEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ActiveTimebar(
                  totalMs: _timeLimitMs,
                  startMs: _timeLeftMs,
                  running: true,
                  onTimeout: null,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Auto-next'),
                Switch(
                  value: _autoNext,
                  onChanged: (v) {
                    final p = _prefs.copyWith(autoNext: v);
                    setState(() {
                      _autoNext = v;
                      if (!_autoNext) _cancelAutoNextAnim();
                      _prefs = p;
                    });
                    saveUiPrefs(p);
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            Expanded(
              child: ScaleTransition(
                scale: _answerPulse,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _answerFlashColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        spot.hand,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _buildSubTitle(spot),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ...actions.map(
                          (a) => _buildActionButton(a, spot, jamFoldHotkeys)),
                      if (_chosen != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _answers[_index].correct
                              ? 'Correct!'
                              : 'Try again next time',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _answers[_index].correct
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showExplain = !_showExplain),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Why?'),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(spot.explain ?? 'No explanation'),
                          ),
                          crossFadeState: _showExplain
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _next,
                          child: const Text('Next'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubTitle(UiSpot spot) {
    final parts = <String>[spot.pos];
    if (spot.vsPos != null) parts.add('vs ${spot.vsPos}');
    if (spot.limpers != null) parts.add('limpers ${spot.limpers}');
    parts.add(spot.stack);
    final core = parts.join(' • ');
    if (spot.kind == SpotKind.callVsJam) {
      return 'Call vs Jam • $core';
    }
    if (spot.kind == SpotKind.l3_postflop_jam) {
      return 'Postflop Jam • $core';
    }
    if (spot.kind == SpotKind.l3_checkraise_jam) {
      return 'Check-Raise Jam • $core';
    }
    if (spot.kind == SpotKind.l3_check_jam_vs_cbet) {
      return 'Check-Jam vs C-bet • $core';
    }
    if (spot.kind == SpotKind.l3_donk_jam) {
      return 'Donk Jam • $core';
    }
    if (spot.kind == SpotKind.l3_overbet_jam) {
      return 'Overbet Jam • $core';
    }
    if (spot.kind == SpotKind.l3_raise_jam_vs_donk) {
      return 'Raise Jam vs Donk • $core';
    }
    if (spot.kind == SpotKind.l3_bet_jam_vs_raise) {
      return 'Bet Jam vs Raise • $core';
    }
    if (spot.kind == SpotKind.l3_raise_jam_vs_cbet) {
      return 'Raise Jam vs C-bet • $core';
    }
    if (spot.kind == SpotKind.l3_probe_jam_vs_raise) {
      return 'Probe Jam vs Raise • $core';
    }
    if (spot.kind == SpotKind.l3_flop_jam_vs_bet) {
      return 'Flop Jam vs Bet • ' + core;
    }
    if (spot.kind == SpotKind.l3_flop_jam_vs_raise) {
      return 'Flop Jam vs Raise • ' + core;
    }
    if (spot.kind == SpotKind.l3_turn_jam_vs_bet) {
      return 'Turn Jam vs Bet • ' + core;
    }
    if (spot.kind == SpotKind.l3_turn_jam_vs_raise) {
      return 'Turn Jam vs Raise • ' + core;
    }
    if (spot.kind == SpotKind.l3_river_jam_vs_bet) {
      return 'River Jam vs Bet • ' + core;
    }
    if (spot.kind == SpotKind.l3_river_jam_vs_raise) {
      return 'River Jam vs Raise • ' + core;
    }
    return core;
  }

  List<String> _actionsFor(SpotKind kind) {
    switch (kind) {
      case SpotKind.l2_open_fold:
        return ['open', 'fold'];
      case SpotKind.l2_threebet_push:
        return ['jam', 'fold'];
      case SpotKind.l2_limped:
        return ['iso', 'overlimp', 'fold'];
      case SpotKind.l4_icm:
        return ['jam', 'fold'];
      case SpotKind.callVsJam:
        return ['Call', 'Fold'];
      case SpotKind.l3_postflop_jam:
        return ['jam', 'fold'];
      case SpotKind.l3_checkraise_jam:
        return ['jam', 'fold'];
      case SpotKind.l3_check_jam_vs_cbet:
        return ['jam', 'fold'];
      case SpotKind.l3_donk_jam:
        return ['jam', 'fold'];
      case SpotKind.l3_overbet_jam:
        return ['jam', 'fold'];
      case SpotKind.l3_raise_jam_vs_donk:
        return ['jam', 'fold'];
      case SpotKind.l3_bet_jam_vs_raise:
        return ['jam', 'fold'];
      case SpotKind.l3_raise_jam_vs_cbet:
        return ['jam', 'fold'];
      case SpotKind.l3_probe_jam_vs_raise:
        return ['jam', 'fold'];
      case SpotKind.l3_flop_jam_vs_bet:
        return ['jam', 'fold'];
      case SpotKind.l3_flop_jam_vs_raise:
        return ['jam', 'fold'];
      case SpotKind.l3_river_jam_vs_bet:
        return ['jam', 'fold'];
      case SpotKind.l3_turn_jam_vs_bet:
        return ['jam', 'fold'];
      case SpotKind.l3_river_jam_vs_raise:
        return ['jam', 'fold'];
      case SpotKind.l3_turn_jam_vs_raise:
        return ['jam', 'fold'];
    }
  }

  Widget _buildActionButton(String action, UiSpot spot, bool jamFoldHotkeys) {
    final correct = action == spot.action;
    Color? color;
    if (_chosen != null) {
      if (action == _chosen) {
        color = correct ? Colors.green : Colors.red;
      } else if (correct) {
        color = Colors.green;
      }
    }
    var label = action;
    if (jamFoldHotkeys) {
      if (action == 'jam') {
        label = 'jam [J]';
      } else if (action == 'fold') {
        label = 'fold [F]';
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: _chosen == null ? () => _onAction(action) : null,
        style: color != null
            ? ElevatedButton.styleFrom(backgroundColor: color)
            : null,
        child: Text(label),
      ),
    );
  }
}
