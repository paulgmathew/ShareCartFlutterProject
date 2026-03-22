import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/list_detail_provider.dart';
import '../../../services/api_client.dart';

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
  String? _error;

  @override
  void dispose() {
    _userIdController.dispose();
    _roleController.dispose();
    super.dispose();
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
                      : const Text('Invite'),
            ),
          ],
        ),
      ),
    );
  }
}
