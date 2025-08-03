part of '../poker_analyzer_screen.dart';

class _SaveLoadControlsSection extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onLoadLast;
  final VoidCallback onLoadByName;
  final VoidCallback onExportLast;
  final VoidCallback onExportAll;
  final VoidCallback onImport;
  final VoidCallback onImportAll;
  final bool disabled;
  const _SaveLoadControlsSection({
    required this.onSave,
    required this.onLoadLast,
    required this.onLoadByName,
    required this.onExportLast,
    required this.onExportAll,
    required this.onImport,
    required this.onImportAll,
    this.disabled = false,
  });
  @override
  Widget build(BuildContext context) {
    final Color iconColor = disabled ? Colors.grey : Colors.white;
    return Row(
      children: [
        IconButton(icon: Icon(Icons.save, color: iconColor), onPressed: disabled ? null : onSave),
        IconButton(icon: Icon(Icons.folder_open, color: iconColor), onPressed: disabled ? null : onLoadLast),
        IconButton(icon: Icon(Icons.list, color: iconColor), onPressed: disabled ? null : onLoadByName),
        IconButton(icon: Icon(Icons.upload, color: iconColor), onPressed: disabled ? null : onExportLast),
        IconButton(icon: Icon(Icons.file_upload, color: iconColor), onPressed: disabled ? null : onExportAll),
        IconButton(icon: Icon(Icons.download, color: iconColor), onPressed: disabled ? null : onImport),
        IconButton(icon: Icon(Icons.file_download, color: iconColor), onPressed: disabled ? null : onImportAll),
      ],
    );
  }
}

class _PlaybackControlsSection extends StatelessWidget {
  final bool isPlaying;
  final int playbackIndex;
  final int actionCount;
  final Duration elapsedTime;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onPlayAll;
  final VoidCallback onStepBackward;
  final VoidCallback onStepForward;
  final VoidCallback onPlaybackReset;
  final ValueChanged<double> onSeek;
  final VoidCallback onReset;
  final VoidCallback onBack;
  final bool focusOnHero;
  final ValueChanged<bool> onFocusChanged;
  final bool backDisabled;
  final bool disabled;
  const _PlaybackControlsSection({
    required this.isPlaying,
    required this.playbackIndex,
    required this.actionCount,
    required this.elapsedTime,
    required this.onPlay,
    required this.onPause,
    required this.onPlayAll,
    required this.onStepBackward,
    required this.onStepForward,
    required this.onPlaybackReset,
    required this.onSeek,
    required this.onReset,
    required this.onBack,
    required this.focusOnHero,
    required this.onFocusChanged,
    this.backDisabled = false,
    this.disabled = false,
  });
  @override
  Widget build(BuildContext context) {
    final Color iconColor = disabled ? Colors.grey : Colors.white;
    return Column(
      children: [
        Row(
          children: [
            IconButton(icon: Icon(Icons.skip_previous, color: iconColor), onPressed: disabled ? null : onStepBackward),
            IconButton(icon: Icon(Icons.replay, color: iconColor), onPressed: disabled ? null : onPlaybackReset),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: iconColor),
              onPressed: disabled ? null : (isPlaying ? onPause : onPlay),
            ),
            IconButton(icon: Icon(Icons.skip_next, color: iconColor), onPressed: disabled ? null : onStepForward),
            Expanded(
              child: Slider(
                value: playbackIndex.toDouble(),
                min: 0,
                max: actionCount > 0 ? actionCount.toDouble() : 1,
                onChanged: disabled ? null : onSeek,
                inactiveColor: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: actionCount > 0 ? playbackIndex / actionCount : 0.0,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(height: 4),
              Text(
                "Step $playbackIndex / $actionCount${isPlaying ? " - " + formatDuration(elapsedTime) : ""}",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: disabled ? null : (isPlaying ? onPause : onPlayAll), child: Text(isPlaying ? 'Pause' : 'Play All')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: disabled ? null : onStepBackward, child: const Text('Step Back')),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: disabled ? null : onStepForward, child: const Text('Step Forward')),
          ],
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: backDisabled ? null : onBack, child: const Text('Назад')),
        const SizedBox(height: 10),
        TextButton(onPressed: onReset, child: const Text('Сбросить раздачу')),
        SwitchListTile(
          title: const Text('Focus on Hero', style: TextStyle(color: Colors.white)),
          value: focusOnHero,
          onChanged: disabled ? null : onFocusChanged,
          activeColor: Colors.deepPurple,
        ),
      ],
    );
  }
}

class PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final int playbackIndex;
  final int actionCount;
  final Duration elapsedTime;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onPlayAll;
  final VoidCallback onStepBackward;
  final VoidCallback onStepForward;
  final VoidCallback onPlaybackReset;
  final ValueChanged<double> onSeek;
  final VoidCallback onSave;
  final VoidCallback onLoadLast;
  final VoidCallback onLoadByName;
  final VoidCallback onExportLast;
  final VoidCallback onExportAll;
  final VoidCallback onImport;
  final VoidCallback onImportAll;
  final VoidCallback onReset;
  final VoidCallback onBack;
  final bool focusOnHero;
  final ValueChanged<bool> onFocusChanged;
  final bool backDisabled;
  final bool disabled;
  const PlaybackControls({
    required this.isPlaying,
    required this.playbackIndex,
    required this.actionCount,
    required this.elapsedTime,
    required this.onPlay,
    required this.onPause,
    required this.onPlayAll,
    required this.onStepBackward,
    required this.onStepForward,
    required this.onPlaybackReset,
    required this.onSeek,
    required this.onSave,
    required this.onLoadLast,
    required this.onLoadByName,
    required this.onExportLast,
    required this.onExportAll,
    required this.onImport,
    required this.onImportAll,
    required this.onReset,
    required this.onBack,
    required this.focusOnHero,
    required this.onFocusChanged,
    this.backDisabled = false,
    this.disabled = false,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SaveLoadControlsSection(
          onSave: onSave,
          onLoadLast: onLoadLast,
          onLoadByName: onLoadByName,
          onExportLast: onExportLast,
          onExportAll: onExportAll,
          onImport: onImport,
          onImportAll: onImportAll,
          disabled: disabled,
        ),
        const SizedBox(height: 10),
        _PlaybackControlsSection(
          isPlaying: isPlaying,
          playbackIndex: playbackIndex,
          actionCount: actionCount,
          elapsedTime: elapsedTime,
          onPlay: onPlay,
          onPause: onPause,
          onPlayAll: onPlayAll,
          onStepBackward: onStepBackward,
          onStepForward: onStepForward,
          onPlaybackReset: onPlaybackReset,
          onSeek: onSeek,
          onReset: onReset,
          onBack: onBack,
          focusOnHero: focusOnHero,
          onFocusChanged: onFocusChanged,
          backDisabled: backDisabled,
          disabled: disabled,
        ),
      ],
    );
  }
}

