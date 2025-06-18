import 'package:flutter/material.dart';

import '../widgets/ethereum_address_input.dart';
import '../utils/eth_utils.dart';
import 'package:flutter/services.dart';
import 'qr_code_scanner_screen.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';
import 'dart:math';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class EthereumToolsScreen extends StatefulWidget {
  static const routeName = '/ethereum-tools';

  const EthereumToolsScreen({super.key});

  @override
  State<EthereumToolsScreen> createState() => _EthereumToolsScreenState();
}

class _EthereumToolsScreenState extends State<EthereumToolsScreen> {
  String? _generatedPrivateKey;
  String? _generatedAddress;
  final TextEditingController _keyController = TextEditingController();
  bool? _keyValid;

  void _generate() {
    final credentials = EthPrivateKey.createRandom(Random.secure());
    final pkHex = bytesToHex(credentials.privateKey,
        include0x: false, forcePadLength: 64);
    setState(() {
      _generatedPrivateKey = pkHex;
      _generatedAddress = credentials.address.hexEip55;
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

  Future<bool> _ensurePermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  Future<void> _exportToFile() async {
    if (_generatedPrivateKey == null || _generatedAddress == null) return;
    final allowed = await _ensurePermission();
    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Storage permission denied')));
      }
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final file = File('${dir.path}/wallet_$timestamp.txt');
    final content =
        'Private Key: $_generatedPrivateKey\nAddress: $_generatedAddress\n';
    await file.writeAsString(content, flush: true);
    if (mounted) {
      final name = file.path.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Файл сохранён: $name')));
    }
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
              if (_generatedPrivateKey != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _generatedPrivateKey!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white70),
                      onPressed: () => _copy(_generatedPrivateKey!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _generatedAddress!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white70),
                      onPressed: () => _copy(_generatedAddress!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _exportToFile,
                  child: const Text('Сохранить в файл'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
