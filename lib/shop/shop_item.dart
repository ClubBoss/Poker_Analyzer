import 'package:flutter/material.dart';

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final Future<void> Function(BuildContext context) onPurchase;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.onPurchase,
  });
}
