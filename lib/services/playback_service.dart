import 'dart:async';
import 'package:flutter/foundation.dart';

class PlaybackService extends ChangeNotifier {
  int _playbackIndex = 0;
  bool _isPlaying = false;
  Timer? _playbackTimer;
  final Duration stepDuration;

  PlaybackService({this.stepDuration = const Duration(seconds: 1)});

  int get playbackIndex => _playbackIndex;
  bool get isPlaying => _isPlaying;

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

  void startPlayback(int actionCount) {
    pausePlayback();
    _isPlaying = true;
    if (_playbackIndex == actionCount) {
      _playbackIndex = 0;
    }
    updatePlaybackState();
    _playbackTimer =
        Timer.periodic(stepDuration, (_) => _playStepForward(actionCount));
  }

  void pausePlayback() {
    _playbackTimer?.cancel();
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
    updatePlaybackState();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}
