import 'package:flutter/material.dart';

import '../widgets/ethereum_address_input.dart';
import '../utils/eth_utils.dart';
import 'package:flutter/services.dart';
import 'qr_code_scanner_screen.dart';

class EthereumToolsScreen extends StatefulWidget {
  static const routeName = '/ethereum-tools';

  const EthereumToolsScreen({super.key});

  @override
  State<EthereumToolsScreen> createState() => _EthereumToolsScreenState();
}

class _EthereumToolsScreenState extends State<EthereumToolsScreen> {
  String? _generated;
  String? _checksum;
  final TextEditingController _keyController = TextEditingController();
  bool? _keyValid;

  void _generate() {
    final addr = generateRandomAddress();
    setState(() {
      _generated = addr;
      _checksum = toChecksumAddress(addr);
    });
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }

  Future<void> _scanKey() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QRCodeScannerScreen()),
    );
    if (result != null) {
      final text = result.trim();
      if (isValidPrivateKey(text)) {
        _keyController.text = text;
        _validateKey();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scanned value is not a valid private key')),
          );
        }
      }
    }
  }

  void _validateKey() {
    final text = _keyController.text.trim();
    setState(() {
      _keyValid = isValidPrivateKey(text);
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Ethereum Tools'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EthereumAddressInput(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keyController,
                      decoration: const InputDecoration(
                        labelText: 'Private Key',
                      ),
                      obscureText: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white70),
                    onPressed: _scanKey,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _validateKey,
                child: const Text('Проверить'),
              ),
              if (_keyValid != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _keyValid! ? 'Valid private key' : 'Invalid private key',
                    style:
                        TextStyle(color: _keyValid! ? Colors.green : Colors.red),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _generate,
                child: const Text('Сгенерировать новый адрес'),
              ),
              if (_generated != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _generated!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white70),
                      onPressed: () => _copy(_generated!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _checksum!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white70),
                      onPressed: () => _copy(_checksum!),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
