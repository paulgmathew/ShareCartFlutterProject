import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/canonical_item_model.dart';
import '../../../models/item_model.dart';
import '../../../providers/list_detail_provider.dart';
import '../../../services/api_client.dart';
import '../../../widgets/canonical_item_picker.dart';

class AddItemSheet extends StatefulWidget {
  final ItemModel? editItem;

  const AddItemSheet({super.key, this.editItem});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _categoryController;
  CanonicalItemModel? _selectedCanonicalItem;
  bool _isSubmitting = false;
  String? _error;

  bool get _isEditing => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.editItem?.name);
    _quantityController = TextEditingController(
      text: widget.editItem?.quantity,
    );
    _categoryController = TextEditingController(
      text: widget.editItem?.category,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Item name is required');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final provider = context.read<ListDetailProvider>();
      if (_isEditing) {
        await provider.updateItem(
          widget.editItem!.id,
          name: _nameController.text.trim(),
          quantity:
              _quantityController.text.trim().isNotEmpty
                  ? _quantityController.text.trim()
                  : null,
          category:
              _categoryController.text.trim().isNotEmpty
                  ? _categoryController.text.trim()
                  : null,
        );
      } else {
        await provider.addItem(
          name: _nameController.text.trim(),
          canonicalItemId: _selectedCanonicalItem?.id,
          quantity:
              _quantityController.text.trim().isNotEmpty
                  ? _quantityController.text.trim()
                  : null,
          category:
              _categoryController.text.trim().isNotEmpty
                  ? _categoryController.text.trim()
                  : null,
        );
      }
      if (mounted) Navigator.pop(context);
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
              _isEditing ? 'Edit Item' : 'Add Item',
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
            CanonicalItemPicker(
              controller: _nameController,
              initialSearchText: widget.editItem?.name,
              labelText: 'Item Name',
              hintText: 'e.g. Milk',
              onSelected: (item) {
                setState(() => _selectedCanonicalItem = item);
              },
            ),
            if (_selectedCanonicalItem != null) ...[
              const SizedBox(height: 8),
              Text(
                'Selected catalog item: ${_selectedCanonicalItem!.name}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity (optional)',
                hintText: 'e.g. 2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                hintText: 'e.g. Dairy',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
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
                      : Text(_isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
