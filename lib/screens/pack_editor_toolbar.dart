part of 'pack_editor_core.dart';

class PackEditorToolbar extends StatelessWidget {
  final PackEditorCore core;
  const PackEditorToolbar({super.key, required this.core});

  @override
  Widget build(BuildContext context) {
    final toolbar = Row(
      children: [
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed: core.snapshots.isNotEmpty ? core.saveSnapshot : null,
        ),
      ],
    );
    return PackEditorShortcuts(core: core, child: toolbar);
  }
}

class PackEditorShortcuts extends StatelessWidget {
  final PackEditorCore core;
  final Widget child;
  const PackEditorShortcuts({
    super.key,
    required this.core,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final shortcuts = <LogicalKeySet, Intent>{
      for (final c in core.commands)
        if (c.shortcut != null) c.shortcut!: _CommandIntent(c.id),
    };
    final actions = <Type, Action<Intent>>{
      _CommandIntent: CallbackAction<_CommandIntent>(
        onInvoke: (intent) {
          final cmd = core.commands.firstWhere(
            (c) => c.id == intent.id,
            orElse: () => throw ArgumentError('Unknown command'),
          );
          cmd.action();
          return null;
        },
      ),
    };
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(actions: actions, child: child),
    );
  }
}

class _CommandIntent extends Intent {
  final String id;
  const _CommandIntent(this.id);
}
