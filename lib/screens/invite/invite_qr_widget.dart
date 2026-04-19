import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class InviteQrWidget extends StatelessWidget {
  final String inviteUrl;

  const InviteQrWidget({super.key, required this.inviteUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QrImageView(data: inviteUrl, version: QrVersions.auto, size: 220.0),
        const SizedBox(height: 12),
        Text(
          'Scan to join this list',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.share, size: 18),
          label: const Text('Share Link'),
          onPressed:
              () => SharePlus.instance.share(ShareParams(text: inviteUrl)),
        ),
      ],
    );
  }
}
