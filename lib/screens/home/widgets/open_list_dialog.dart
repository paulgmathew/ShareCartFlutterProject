import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/home_provider.dart';
import '../../../services/api_client.dart';

class OpenListDialog extends StatefulWidget {
  const OpenListDialog({super.key});

  @override
  State<OpenListDialog> createState() => _OpenListDialogState();
}

class _OpenListDialogState extends State<OpenListDialog> {
  final _formKey = GlobalKey<FormState>();
  final _listIdController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _listIdController.dispose();
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
      await provider.openListById(_listIdController.text.trim());
      if (mounted) Navigator.pop(context, _listIdController.text.trim());
    } on ApiException catch (e) {
      setState(() => _error = e.error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Open Existing List'),
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
              controller: _listIdController,
              decoration: const InputDecoration(
                labelText: 'List ID',
                hintText: 'Paste the UUID of the list',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'List ID is required';
                }
                return null;
              },
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
                  : const Text('Open'),
        ),
      ],
    );
  }
}
