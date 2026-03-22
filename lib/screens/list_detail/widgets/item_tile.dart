import 'package:flutter/material.dart';

import '../../../models/item_model.dart';

class ItemTile extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          item.name,
          style:
              item.isCompleted
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
        ),
        subtitle: item.quantity != null ? Text('Qty: ${item.quantity}') : null,
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: onEdit,
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Item'),
            content: Text('Delete "${item.name}" from this list?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    return result ?? false;
  }
}
