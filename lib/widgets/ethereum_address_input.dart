import 'package:flutter/material.dart';

import '../utils/eth_utils.dart';
import '../screens/qr_code_scanner_screen.dart';

/// Widget allowing input and validation of an Ethereum address.
class EthereumAddressInput extends StatefulWidget {
  const EthereumAddressInput({super.key});

  @override
  State<EthereumAddressInput> createState() => _EthereumAddressInputState();
}

class _EthereumAddressInputState extends State<EthereumAddressInput> {
  final TextEditingController _controller = TextEditingController();

  bool? _valid;
  String? _checksum;

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QRCodeScannerScreen()),
    );
    if (result != null) {
      final text = result.trim();
      if (isValidAddress(text)) {
        _controller.text = text;
        _validate();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scanned value is not a valid address')),
          );
        }
      }
    }
  }

  void _validate() {
    final text = _controller.text.trim();
    final isAddrValid = isValidAddress(text);
    setState(() {
      _valid = isAddrValid;
      _checksum = isAddrValid ? toChecksumAddress(text) : null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Ethereum Address',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: _validate,
              child: const Text('Validate'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _scanQr,
              icon: const Icon(Icons.camera_alt),
              tooltip: 'Scan QR code',
            ),
          ],
        ),
        if (_valid != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _valid! ? 'Valid address: $_checksum' : 'Invalid address',
              style: TextStyle(color: _valid! ? Colors.green : Colors.red),
            ),
          ),
      ],
    );
  }
}
