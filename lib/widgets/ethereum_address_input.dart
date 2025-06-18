import 'package:flutter/material.dart';

import '../utils/eth_utils.dart';

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
        ElevatedButton(
          onPressed: _validate,
          child: const Text('Validate'),
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
