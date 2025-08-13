import 'package:flutter/material.dart';
import '../services/connectivity_sync_controller.dart';
import '../services/cloud_sync_service.dart';
import '../main.dart';

class SyncStatusIcon extends InheritedWidget {
  const SyncStatusIcon({required this.icon, required super.child, super.key});

  final Widget icon;

  static Widget of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SyncStatusIcon>()!.icon;

  @override
  bool updateShouldNotify(covariant SyncStatusIcon oldWidget) =>
      icon != oldWidget.icon;
}

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget(
      {required this.child,
      required this.sync,
      required this.cloud,
      super.key});

  final Widget child;
  final ConnectivitySyncController sync;
  final CloudSyncService cloud;

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  late IconData _icon;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    _icon = Icons.cloud_off;
    widget.sync.online.addListener(_update);
    widget.cloud.progress.addListener(_update);
    widget.cloud.lastSync.addListener(_update);
    widget.cloud.syncMessage.addListener(_onMessage);
    _update();
  }

  void _update() {
    setState(() {
      if (!widget.sync.online.value) {
        _icon = Icons.cloud_off;
      } else if (widget.cloud.progress.value < 0) {
        _icon = Icons.cloud_error;
      } else if (widget.cloud.progress.value > 0) {
        _icon = Icons.cloud_sync;
      } else {
        _icon = Icons.cloud_done;
      }
    });
  }

  void _onMessage() {
    final msg = widget.cloud.syncMessage.value;
    if (msg == null || _showing) return;
    final ctx = navigatorKey.currentState?.context;
    if (ctx == null || !ctx.mounted) return;
    _showing = true;
    ScaffoldMessenger.of(ctx)
        .showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        )
        .closed
        .then((_) => _showing = false);
  }

  @override
  void dispose() {
    widget.sync.online.removeListener(_update);
    widget.cloud.progress.removeListener(_update);
    widget.cloud.lastSync.removeListener(_update);
    widget.cloud.syncMessage.removeListener(_onMessage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SyncStatusIcon(
      icon: Icon(_icon, color: Colors.greenAccent),
      child: widget.child,
    );
  }
}
