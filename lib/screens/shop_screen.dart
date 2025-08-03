import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/coins_service.dart';
import '../shop/shop_items.dart';
import '../shop/shop_item.dart';
import '../utils/snackbar_util.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  Future<void> _buy(BuildContext context, ShopItem item) async {
    final coins = context.read<CoinsService>();
    if (coins.coins < item.price) {
      SnackbarUtil.showMessage(context, 'Недостаточно монет');
      return;
    }
    final ok = await coins.spendCoins(item.price);
    if (!ok) return;
    await item.onPurchase(context);
    if (context.mounted) {
      SnackbarUtil.showMessage(context, 'Куплено: ${item.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<CoinsService>().coins;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Монеты: $balance',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (final item in shopItems)
            Card(
              color: Colors.grey[850],
              child: ListTile(
                leading: Icon(item.icon, color: Colors.orange),
                title: Text(item.name),
                subtitle: Text('${item.description}\nЦена: ${item.price}'),
                isThreeLine: true,
                onTap: () => _buy(context, item),
              ),
            ),
        ],
      ),
    );
  }
}
