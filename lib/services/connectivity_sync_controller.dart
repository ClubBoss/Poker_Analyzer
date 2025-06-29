import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'cloud_sync_service.dart';

class ConnectivitySyncController with WidgetsBindingObserver {
  ConnectivitySyncController({required this.cloud}) {
    WidgetsBinding.instance.addObserver(this);
    _sub = Connectivity().onConnectivityChanged.listen(_onResult);
  }

  final CloudSyncService cloud;
  late final StreamSubscription<ConnectivityResult> _sub;

  void _onResult(ConnectivityResult result) {
    if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
      _sync();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sync();
    }
  }

  Future<void> _sync() async {
    await cloud.syncUp();
    await cloud.syncDown();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub.cancel();
  }
}
