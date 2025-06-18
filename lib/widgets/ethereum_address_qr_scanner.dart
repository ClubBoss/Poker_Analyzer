import 'dart:io';

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
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

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
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Point camera at QR code',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
