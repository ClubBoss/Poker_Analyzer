import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../utils/eth_utils.dart';

/// Camera-based QR code scanner that returns a valid Ethereum address.
class EthereumAddressQRScanner extends StatefulWidget {
  const EthereumAddressQRScanner({super.key});

  @override
  State<EthereumAddressQRScanner> createState() => _EthereumAddressQRScannerState();
}

class _EthereumAddressQRScannerState extends State<EthereumAddressQRScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'qr');
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller!.scannedDataStream.listen((scanData) async {
      final code = scanData.code?.trim();
      if (code == null) return;

      controller?.pauseCamera();
      if (isValidAddress(code)) {
        Navigator.pop(context, code);
      } else {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Invalid Address'),
            content: const Text('The scanned QR code is not a valid Ethereum address.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        controller?.resumeCamera();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Ethereum Address'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }
}
