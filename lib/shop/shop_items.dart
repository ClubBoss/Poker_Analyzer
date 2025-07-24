import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/xp_tracker_service.dart';
import '../services/theme_service.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';
import 'shop_item.dart';

final List<ShopItem> shopItems = [
  ShopItem(
    id: 'xp_booster',
    name: 'Бустер XP',
    description: '+100 XP',
    price: 50,
    icon: Icons.flash_on,
    onPurchase: (context) async {
      await context.read<XPTrackerService>().add(xp: 100, source: 'shop');
    },
  ),
  ShopItem(
    id: 'avatar_color',
    name: 'Цвет аватара',
    description: 'Изменить цвет профиля',
    price: 30,
    icon: Icons.brush,
    onPurchase: (context) async {
      final colors = [Colors.orange, Colors.pinkAccent, Colors.lightBlueAccent];
      final color = colors[Random().nextInt(colors.length)];
      await context.read<ThemeService>().setAccentColor(color);
    },
  ),
  ShopItem(
    id: 'bonus_pack',
    name: 'Бонусный пак',
    description: 'Случайный YAML',
    price: 40,
    icon: Icons.card_giftcard,
    onPurchase: (context) async {
      await TrainingPackLibraryV2.instance.loadFromFolder();
      final packs = TrainingPackLibraryV2.instance.packs;
      if (packs.isEmpty) return;
      final pack = packs[Random().nextInt(packs.length)];
      await context.read<TrainingSessionService>().startSession(pack);
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
      );
    },
  ),
];
