import 'dart:async';
import 'package:flutter/foundation.dart';

class PlaybackService extends ChangeNotifier {
  int _playbackIndex = 0;
  bool _isPlaying = false;
  Timer? _playbackTimer;
  Duration stepDuration;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;

  PlaybackService({this.stepDuration = const Duration(seconds: 1)});

  int get playbackIndex => _playbackIndex;
  bool get isPlaying => _isPlaying;
  Duration get elapsedTime =>
      _elapsed +
      ((_isPlaying && _startTime != null)
          ? DateTime.now().difference(_startTime!)
          : Duration.zero);

  void updatePlaybackState() {
    notifyListeners();
  }

  void _playStepForward(int actionCount) {
    if (_playbackIndex < actionCount) {
      _playbackIndex++;
      updatePlaybackState();
    } else {
      pausePlayback();
    }
  }

  void startPlayback(
    int actionCount, {
    Duration? delay,
    bool Function()? canAdvance,
  }) {
    pausePlayback();
    _isPlaying = true;
    if (_playbackIndex == actionCount) {
      _playbackIndex = 0;
      _elapsed = Duration.zero;
    }
    _startTime = DateTime.now();
    updatePlaybackState();
    final d = delay ?? stepDuration;
    _playbackTimer = Timer.periodic(d, (_) {
      if (canAdvance == null || canAdvance()) {
        _playStepForward(actionCount);
      }
    });
  }

  void pausePlayback() {
    _playbackTimer?.cancel();
    if (_isPlaying && _startTime != null) {
      _elapsed += DateTime.now().difference(_startTime!);
    }
    _startTime = null;
    _isPlaying = false;
    notifyListeners();
  }

  void stepForward(int actionCount) {
    pausePlayback();
    _playStepForward(actionCount);
  }

  void stepBackward() {
    pausePlayback();
    if (_playbackIndex > 0) {
      _playbackIndex--;
      updatePlaybackState();
    }
  }

  void seek(int index) {
    pausePlayback();
    _playbackIndex = index;
    updatePlaybackState();
  }

  void resetHand() {
    pausePlayback();
    _playbackIndex = 0;
    _elapsed = Duration.zero;
    _startTime = null;
    updatePlaybackState();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}
