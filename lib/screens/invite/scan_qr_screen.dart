import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/invite_api_service.dart';
import 'invite_preview_screen.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _processing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final url = capture.barcodes.firstOrNull?.rawValue;
    if (url == null) return;

    // Validate: must be a sharecart invite link
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.host != 'sharecart.app' ||
        !uri.pathSegments.contains('invite')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid QR code')));
      return;
    }

    setState(() => _processing = true);

    final token = extractInviteToken(url);

    // Navigate to InvitePreviewScreen — it handles auth check, preview,
    // acceptInvite call, and all error cases.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => InvitePreviewScreen(token: token)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          if (_processing)
            const ColoredBox(
              color: Color(0x88000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Point the camera at a ShareCart QR code',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
