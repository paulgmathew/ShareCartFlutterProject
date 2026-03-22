import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/home_provider.dart';
import '../../../services/api_client.dart';

class CreateListDialog extends StatefulWidget {
  const CreateListDialog({super.key});

  @override
  State<CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<CreateListDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerIdController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _ownerIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final provider = context.read<HomeProvider>();
      final list = await provider.createList(
        _nameController.text.trim(),
        ownerId:
            _ownerIdController.text.trim().isNotEmpty
                ? _ownerIdController.text.trim()
                : null,
      );
      if (mounted) Navigator.pop(context, list.id);
    } on ApiException catch (e) {
      setState(() => _error = e.error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Shopping List'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'List Name',
                hintText: 'e.g. Weekend Groceries',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'List name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerIdController,
              decoration: const InputDecoration(
                labelText: 'Owner ID (optional)',
                hintText: 'UUID of the owner',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Create'),
        ),
      ],
    );
  }
}
