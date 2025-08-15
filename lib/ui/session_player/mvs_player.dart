// Example:
// Navigator.of(context).push(MaterialPageRoute(
//   builder: (_) => Scaffold(body: MvsSessionPlayer(spots: demoSpots())),
// ));

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb & defaultTargetPlatform
import 'package:flutter/services.dart';

import '../../widgets/active_timebar.dart';
import 'hotkeys_sheet.dart';
import 'mini_toast.dart';
import 'models.dart';
import 'result_summary.dart';
import 'ui_prefs.dart';

class MvsSessionPlayer extends StatefulWidget {
  final List<UiSpot> spots;
  const MvsSessionPlayer({super.key, required this.spots});

  @override
  State<MvsSessionPlayer> createState() => _MvsSessionPlayerState();
}

class _MvsSessionPlayerState extends State<MvsSessionPlayer>
    with SingleTickerProviderStateMixin {
  late List<UiSpot> _spots;
  int _index = 0;
  final _answers = <UiAnswer>[];
  final _timer = Stopwatch();
  final _focusNode = FocusNode();
  Timer? _ticker;
  Timer? _autoNextTimer;
  String? _chosen;
  bool _showExplain = false;
  UiPrefs _prefs = const UiPrefs(
      autoNext: false, timeEnabled: true, timeLimitMs: 10000, sound: false);
  bool _autoNext = false;
  int _timeLimitMs = 10000; // 10s default
  bool _timeEnabled = true; // can toggle
  int _timeLeftMs = 10000;
  Timer? _timebarTicker; // separate from _ticker
  late final AnimationController _answerPulseCtrl;
  late final Animation<double> _answerPulse;
  Color? _answerFlashColor;
  Timer? _answerFlashTimer;

  bool get _showHotkeys =>
      kIsWeb ||
      const {TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux}
          .contains(defaultTargetPlatform);

  @override
  void initState() {
    super.initState();
    _spots = widget.spots;
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
          try { HapticFeedback.vibrate(); } catch (_) {}
        }
      });
    });
  }

  void _onAction(String action) {
    if (_chosen != null) return;
    _timer.stop();
    _ticker?.cancel();
    _timebarTicker?.cancel();
    final spot = _spots[_index];
    final correct = action == spot.action;
    // mobile haptics
    try {
      if (correct) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    } catch (_) {}
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
    });
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
      _autoNextTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (_chosen != null && _answers[_index].correct) _next();
      });
    }
  }

  void _undo() {
    if (_answers.isEmpty) return;
    _autoNextTimer?.cancel();
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
    try { HapticFeedback.selectionClick(); } catch (_) {}
    unawaited(showMiniToast(context, 'Undo'));
  }

  void _skip() {
    if (_index >= _spots.length || _chosen != null) return;
    _autoNextTimer?.cancel();
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
    try { HapticFeedback.selectionClick(); } catch (_) {}
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
    _answerFlashTimer?.cancel();
    _answerFlashColor = null;
    if (_index + 1 >= _spots.length) {
      setState(() => _index++);
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
    _startTicker();
    _startTimebar();
    _focusNode.requestFocus();
  }

  void _restart(List<UiSpot> spots) {
    _autoNextTimer?.cancel();
    _answerFlashTimer?.cancel();
    _answerFlashColor = null;
    setState(() {
      _spots = spots;
      _index = 0;
      _answers.clear();
      _chosen = null;
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
      );
    } else {
      child = _buildSpotCard(_spots[_index]);
    }
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
                  bool sound = _prefs.sound;
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
                                  "timeEnabled": timeEnabled,
                                  "timeLimitMs": limit,
                                  "sound": sound
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
                );
                await saveUiPrefs(p);
                if (!mounted) return;
                setState(() {
                  _prefs = p;
                  _autoNext = p.autoNext;
                  _timeEnabled = p.timeEnabled;
                  _timeLimitMs = p.timeLimitMs;
                  if (_chosen == null) _startTimebar();
                });
              }
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: child,
      ),
    );
  }

  Widget _buildSpotCard(UiSpot spot) {
    final actions = _actionsFor(spot.kind);
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
          if (event is! RawKeyDownEvent) return;
          if (event.logicalKey == LogicalKeyboardKey.keyA) {
            setState(() => _autoNext = !_autoNext);
          return;
        }
        if (event.logicalKey == LogicalKeyboardKey.keyT) {
          setState(() {
            _timeEnabled = !_timeEnabled;
            if (_chosen == null) _startTimebar();
          });
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
                    setState(() {
                      _timeEnabled = v;
                      if (_chosen == null) _startTimebar();
                    });
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
                  onChanged: (v) => setState(() => _autoNext = v),
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
                      ...actions.map((a) => _buildActionButton(a, spot)),
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
    return parts.join(' • ');
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
    }
  }

  Widget _buildActionButton(String action, UiSpot spot) {
    final correct = action == spot.action;
    Color? color;
    if (_chosen != null) {
      if (action == _chosen) {
        color = correct ? Colors.green : Colors.red;
      } else if (correct) {
        color = Colors.green;
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: _chosen == null ? () => _onAction(action) : null,
        style: color != null
            ? ElevatedButton.styleFrom(backgroundColor: color)
            : null,
        child: Text(action),
      ),
    );
  }
}
