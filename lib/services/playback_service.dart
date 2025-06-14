import 'dart:async';
import 'package:flutter/foundation.dart';

class PlaybackService extends ChangeNotifier {
  int playbackIndex = 0;
  bool isPlaying = false;
  Timer? _timer;

  void play(int actionCount) {
    pause();
    isPlaying = true;
    if (playbackIndex == actionCount) {
      playbackIndex = 0;
    }
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (playbackIndex < actionCount) {
        playbackIndex++;
        notifyListeners();
      } else {
        pause();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    isPlaying = false;
    notifyListeners();
  }

  void stepForward(int actionCount) {
    pause();
    if (playbackIndex < actionCount) {
      playbackIndex++;
      notifyListeners();
    }
  }

  void stepBackward() {
    pause();
    if (playbackIndex > 0) {
      playbackIndex--;
      notifyListeners();
    }
  }

  void seek(int index, int actionCount) {
    pause();
    playbackIndex = index.clamp(0, actionCount);
    notifyListeners();
  }

  void reset() {
    pause();
    playbackIndex = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
