import 'package:flutter/material.dart';

import '../widgets/ethereum_address_input.dart';

class EthereumToolsScreen extends StatelessWidget {
  static const routeName = '/ethereum-tools';

  const EthereumToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Ethereum Tools'),
        centerTitle: true,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: EthereumAddressInput(),
        ),
      ),
    );
  }
}
