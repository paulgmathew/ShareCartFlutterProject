import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/best_store_option_model.dart';
import '../../providers/best_store_provider.dart';
import '../../services/price_api_service.dart';

class BestStoreScreen extends StatelessWidget {
  final String canonicalItemId;
  final String itemName;

  const BestStoreScreen({
    super.key,
    required this.canonicalItemId,
    required this.itemName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => BestStoreProvider(ctx.read<PriceApiService>()),
      child: _BestStoreBody(
        canonicalItemId: canonicalItemId,
        itemName: itemName,
      ),
    );
  }
}

class _BestStoreBody extends StatefulWidget {
  final String canonicalItemId;
  final String itemName;

  const _BestStoreBody({required this.canonicalItemId, required this.itemName});

  @override
  State<_BestStoreBody> createState() => _BestStoreBodyState();
}

class _BestStoreBodyState extends State<_BestStoreBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BestStoreProvider>().loadBestStores(widget.canonicalItemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BestStoreProvider>(
      builder: (context, provider, _) {
        _showErrorIfAny(provider);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.itemName.trim().isEmpty
                  ? 'Best Store'
                  : 'Best Store for ${widget.itemName}',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed:
                    () => provider.loadBestStores(widget.canonicalItemId),
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => provider.loadBestStores(widget.canonicalItemId),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (provider.loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (provider.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No prices captured for this item yet.'),
                      ),
                    )
                  else
                    ...provider.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final store = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _BestStoreTile(
                          store: store,
                          highlight: index == 0,
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showErrorIfAny(BestStoreProvider provider) {
    final message = provider.errorMessage;
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      provider.clearError();
    });
  }
}

class _BestStoreTile extends StatelessWidget {
  final BestStoreOptionModel store;
  final bool highlight;

  const _BestStoreTile({required this.store, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: highlight ? 3 : 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              highlight ? Theme.of(context).colorScheme.primary : null,
          foregroundColor:
              highlight ? Theme.of(context).colorScheme.onPrimary : null,
          child: Text(highlight ? '1' : '•'),
        ),
        title: Text(store.storeName),
        subtitle: Text(highlight ? 'Cheapest result' : 'Ranked result'),
        trailing: Text(
          '\$${store.lowestPrice.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
