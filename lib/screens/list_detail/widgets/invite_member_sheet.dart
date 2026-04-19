import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/list_detail_provider.dart';
import '../../../services/api_client.dart';
import '../../../services/invite_api_service.dart';
import '../../invite/invite_qr_widget.dart';

class InviteMemberSheet extends StatefulWidget {
  const InviteMemberSheet({super.key});

  @override
  State<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<InviteMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _roleController = TextEditingController();
  bool _isSubmitting = false;
  bool _isGeneratingLink = false;
  String? _error;

  @override
  void dispose() {
    _userIdController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  bool _isOwner(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().userId;
    final list = context.read<ListDetailProvider>().shoppingList;
    if (list == null || currentUserId == null) return false;
    return list.members.any(
      (m) => m.userId == currentUserId && m.role == 'OWNER',
    );
  }

  Future<String?> _generateLink(BuildContext context) async {
    final listId = context.read<ListDetailProvider>().shoppingList?.id;
    if (listId == null) return null;
    setState(() => _isGeneratingLink = true);
    try {
      return await context.read<InviteApiService>().generateInviteLink(listId);
    } on ApiException catch (e) {
      if (!mounted) return null;
      final msg =
          e.error.status == 403
              ? 'Only the list owner can share this list'
              : 'Could not generate invite link. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return null;
    } on TimeoutException {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server is waking up — please try again in a moment.'),
        ),
      );
      return null;
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Check your connection and try again.'),
        ),
      );
      return null;
    } finally {
      if (mounted) setState(() => _isGeneratingLink = false);
    }
  }

  Future<void> _shareInviteLink() async {
    final url = await _generateLink(context);
    if (url == null) return;
    await SharePlus.instance.share(ShareParams(text: url));
  }

  Future<void> _showQrCode() async {
    final url = await _generateLink(context);
    if (url == null || !mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Invite via QR'),
            content: SizedBox(
              width: 280,
              child: InviteQrWidget(inviteUrl: url),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final provider = context.read<ListDetailProvider>();
      await provider.inviteUser(
        _userIdController.text.trim(),
        role:
            _roleController.text.trim().isNotEmpty
                ? _roleController.text.trim()
                : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member invited successfully')),
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Invite Member',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextFormField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                hintText: 'UUID of the user to invite',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'User ID is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Role (optional)',
                hintText: 'e.g. MEMBER (default)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Invite by User ID'),
            ),
            if (_isOwner(context)) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 4),
              Text(
                'Or share a link',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share Invite Link'),
                onPressed: _isGeneratingLink ? null : _shareInviteLink,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code),
                label: const Text('Show QR Code'),
                onPressed: _isGeneratingLink ? null : _showQrCode,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
