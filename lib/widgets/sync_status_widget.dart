import 'package:flutter/material.dart';
import '../services/connectivity_sync_controller.dart';
import '../services/cloud_sync_service.dart';

class SyncStatusIcon extends InheritedWidget {
  const SyncStatusIcon({required this.icon, required super.child, super.key});

  final Widget icon;

  static Widget of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SyncStatusIcon>()!.icon;

  @override
  bool updateShouldNotify(covariant SyncStatusIcon oldWidget) => icon != oldWidget.icon;
}

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({required this.child, required this.sync, required this.cloud, super.key});

  final Widget child;
  final ConnectivitySyncController sync;
  final CloudSyncService cloud;

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  late IconData _icon;

  @override
  void initState() {
    super.initState();
    _icon = Icons.cloud_off;
    widget.sync.online.addListener(_update);
    widget.cloud.progress.addListener(_update);
    widget.cloud.lastSync.addListener(_update);
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

  @override
  void dispose() {
    widget.sync.online.removeListener(_update);
    widget.cloud.progress.removeListener(_update);
    widget.cloud.lastSync.removeListener(_update);
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
