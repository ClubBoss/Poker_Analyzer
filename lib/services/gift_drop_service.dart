import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'coins_service.dart';
import '../utils/snackbar_util.dart';

class GiftDropService {
  GiftDropService({this.interval = const Duration(hours: 24)});

  final Duration interval;

  static const _lastKey = 'gift_drop_last';

  bool _canDrop(DateTime now, DateTime? last) {
    if (last == null) return true;
    return now.difference(last) >= interval;
  }

  Future<void> checkAndDropGift({required BuildContext context}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    final now = DateTime.now();
    if (!_canDrop(now, last)) return;

    final amount = 20 + Random().nextInt(31); // 20..50
    await prefs.setString(_lastKey, now.toIso8601String());
    await CoinsService.instance.addCoins(amount);

    if (context.mounted) {
      SnackbarUtil.showMessage(context, '🎁 Подарок: +$amount монет!');
    }
  }
}
