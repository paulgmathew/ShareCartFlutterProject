import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/list_detail_provider.dart';
import '../../repositories/shopping_list_repository.dart';
import 'widgets/add_item_sheet.dart';
import 'widgets/invite_member_sheet.dart';
import 'widgets/item_tile.dart';
import 'widgets/members_sheet.dart';

class ListDetailScreen extends StatelessWidget {
  final String listId;

  const ListDetailScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (ctx) =>
              ListDetailProvider(ctx.read<ShoppingListRepository>())
                ..loadList(listId),
      child: _ListDetailBody(listId: listId),
    );
  }
}

class _ListDetailBody extends StatelessWidget {
  final String listId;

  const _ListDetailBody({required this.listId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ListDetailProvider>(
      builder: (context, provider, _) {
        final list = provider.shoppingList;

        return Scaffold(
          appBar: AppBar(
            title: Text(list?.name ?? 'Loading...'),
            actions: [
              if (list != null) ...[
                IconButton(
                  icon: const Icon(Icons.people),
                  tooltip: 'Members',
                  onPressed: () => _showMembersSheet(context),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Invite Member',
                  onPressed: () => _showInviteMemberSheet(context),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.loadList(listId),
                ),
              ],
            ],
          ),
          body: _buildBody(context, provider),
          floatingActionButton:
              list != null
                  ? FloatingActionButton.extended(
                    onPressed: () => _showAddItemSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  )
                  : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ListDetailProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.shoppingList == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(provider.errorMessage!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => provider.loadList(listId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final list = provider.shoppingList;
    if (list == null) return const SizedBox.shrink();

    if (list.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_box_outline_blank,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No items yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Item" to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    // Group items by category
    final categorized = <String, List<int>>{};
    for (var i = 0; i < list.items.length; i++) {
      final category = list.items[i].category ?? 'Uncategorized';
      categorized.putIfAbsent(category, () => []).add(i);
    }
    final sortedCategories = categorized.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () => provider.loadList(listId),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: sortedCategories.length,
        itemBuilder: (context, sectionIndex) {
          final category = sortedCategories[sectionIndex];
          final itemIndices = categorized[category]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  category,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...itemIndices.map((i) {
                final item = list.items[i];
                return ItemTile(
                  item: item,
                  onToggle: () => provider.toggleItemCompleted(item),
                  onDelete: () => provider.deleteItem(item.id),
                  onEdit: () => _showEditItemSheet(context, item),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => ChangeNotifierProvider.value(
            value: context.read<ListDetailProvider>(),
            child: const AddItemSheet(),
          ),
    );
  }

  void _showEditItemSheet(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => ChangeNotifierProvider.value(
            value: context.read<ListDetailProvider>(),
            child: AddItemSheet(editItem: item),
          ),
    );
  }

  void _showInviteMemberSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => ChangeNotifierProvider.value(
            value: context.read<ListDetailProvider>(),
            child: const InviteMemberSheet(),
          ),
    );
  }

  void _showMembersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => ChangeNotifierProvider.value(
            value: context.read<ListDetailProvider>(),
            child: const MembersSheet(),
          ),
    );
  }
}
