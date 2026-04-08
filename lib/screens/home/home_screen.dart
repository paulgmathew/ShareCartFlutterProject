import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../list_detail/list_detail_screen.dart';
import 'widgets/create_list_dialog.dart';
import 'widgets/open_list_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Cart'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(auth.name ?? auth.email ?? ''),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<HomeProvider>().refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No shopping lists yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a new list or open an existing one',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.lists.length,
              itemBuilder: (context, index) {
                final list = provider.lists[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: Text(list.name),
                    subtitle: Text(_listSubtitle(list)),
                    onTap: () => _navigateToDetail(context, list.id),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'open',
            onPressed: () => _showOpenListDialog(context),
            child: const Icon(Icons.link),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: () => _showCreateListDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('New List'),
          ),
        ],
      ),
    );
  }

  void _showCreateListDialog(BuildContext context) {
    final homeProvider = context.read<HomeProvider>();
    showDialog(
      context: context,
      builder: (_) => CreateListDialog(homeProvider: homeProvider),
    ).then((listId) {
      if (listId != null && context.mounted) {
        _navigateToDetail(context, listId as String);
      }
    });
  }

  void _showOpenListDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const OpenListDialog()).then((
      listId,
    ) {
      if (listId != null && context.mounted) {
        _navigateToDetail(context, listId as String);
      }
    });
  }

  void _navigateToDetail(BuildContext context, String listId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ListDetailScreen(listId: listId)));
  }

  String _listSubtitle(ShoppingListSummaryModel list) {
    final role = list.memberRole;
    if (role == 'OWNER') return 'Your list';
    if (role == 'MEMBER') return 'Shared with you';
    if (list.ownerName != null) return 'by ${list.ownerName}';
    return '';
  }
}
