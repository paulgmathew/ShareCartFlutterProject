import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/price_comparison_model.dart';
import '../../providers/price_optimization_provider.dart';
import 'price_location_settings_screen.dart';

class BestStoreScreen extends StatefulWidget {
  final String itemName;

  const BestStoreScreen({super.key, required this.itemName});

  @override
  State<BestStoreScreen> createState() => _BestStoreScreenState();
}

class _BestStoreScreenState extends State<BestStoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<PriceOptimizationProvider>();
      if (widget.itemName.trim().isNotEmpty) {
        provider.comparePrices(widget.itemName);
      }
      provider.loadNearbyStores();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PriceOptimizationProvider>();
    final comparison = provider.comparison;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.itemName.isEmpty
              ? 'Best Store'
              : 'Best Store for ${widget.itemName}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Location Settings',
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PriceLocationSettingsScreen(),
                  ),
                ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (widget.itemName.trim().isNotEmpty) {
                provider.comparePrices(widget.itemName);
              }
              provider.loadNearbyStores();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (widget.itemName.trim().isNotEmpty) {
              await provider.comparePrices(widget.itemName);
            }
            await provider.loadNearbyStores();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (provider.errorMessage != null) ...[
                MaterialBanner(
                  content: Text(provider.errorMessage!),
                  actions: [
                    TextButton(
                      onPressed: provider.clearError,
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              _buildComparisonCard(
                context,
                comparison,
                provider.comparisonLoading,
              ),
              const SizedBox(height: 16),
              Text(
                'Nearby Stores',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (provider.nearbyLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.nearbyStores.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No nearby stores found.'),
                )
              else
                ...provider.nearbyStores.map(
                  (store) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(store.name),
                      subtitle: Text(
                        [
                          if (store.address != null &&
                              store.address!.isNotEmpty)
                            store.address!,
                          store.distanceLabel,
                        ].join(' • '),
                      ),
                      trailing:
                          store.price == null
                              ? null
                              : Text(
                                '\$${store.price!.toStringAsFixed(2)}${store.unit == null || store.unit!.isEmpty ? '' : ' / ${store.unit}'}',
                              ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonCard(
    BuildContext context,
    PriceComparisonModel? comparison,
    bool loading,
  ) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (comparison == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            widget.itemName.isEmpty
                ? 'Search an item in the Best Prices tab to compare stores.'
                : 'No comparison has been loaded yet.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              comparison.itemName ?? widget.itemName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(comparison.message ?? 'Comparison loaded successfully.'),
            const SizedBox(height: 12),
            if (comparison.bestStoreName != null ||
                comparison.bestPrice != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Best: ${comparison.bestStoreName ?? 'Unknown store'}'
                  '${comparison.bestPrice == null ? '' : ' at \$${comparison.bestPrice!.toStringAsFixed(2)}'}'
                  '${comparison.bestUnit == null || comparison.bestUnit!.isEmpty ? '' : ' / ${comparison.bestUnit}'}',
                ),
              ),
            if (comparison.hasStores) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => BestStoreScreen(
                            itemName: comparison.itemName ?? widget.itemName,
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Open Best Store Drill-Down'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
