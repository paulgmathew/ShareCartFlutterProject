import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/best_price_summary_model.dart';
import '../../models/item_price_model.dart';
import '../../providers/best_price_summary_provider.dart';
import '../../providers/price_history_provider.dart';
import '../../services/price_api_service.dart';
import '../best_store/best_store_screen.dart';
import '../settings/settings_screen.dart';

class PriceHistoryScreen extends StatelessWidget {
  const PriceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => PriceHistoryProvider(ctx.read<PriceApiService>()),
        ),
        ChangeNotifierProvider(
          create:
              (ctx) => BestPriceSummaryProvider(ctx.read<PriceApiService>()),
        ),
      ],
      child: const _PriceInsightsBody(),
    );
  }
}

class _PriceInsightsBody extends StatefulWidget {
  const _PriceInsightsBody();

  @override
  State<_PriceInsightsBody> createState() => _PriceInsightsBodyState();
}

class _PriceInsightsBodyState extends State<_PriceInsightsBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _historyFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BestPriceSummaryProvider>().loadSummary();
      context.read<PriceHistoryProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openHistoryForItem(BestPriceSummaryModel item) {
    setState(() {
      _historyFilter = item.itemName;
    });
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Insights'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Best Prices'), Tab(text: 'History')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BestPricesTab(onOpenHistoryForItem: _openHistoryForItem),
          _HistoryTab(
            key: ValueKey(_historyFilter ?? 'all'),
            initialFilter: _historyFilter,
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatefulWidget {
  final String? initialFilter;

  const _HistoryTab({super.key, this.initialFilter});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  final _filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null &&
        widget.initialFilter!.trim().isNotEmpty) {
      _filterController.text = widget.initialFilter!.trim();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyFilter();
    });
  }

  @override
  void didUpdateWidget(covariant _HistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      _filterController.text = widget.initialFilter?.trim() ?? '';
      _applyFilter();
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _applyFilter() {
    final filter = _filterController.text.trim();
    return context.read<PriceHistoryProvider>().loadHistory(
      itemNameFilter: filter.isEmpty ? null : filter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PriceHistoryProvider>(
      builder: (context, provider, _) {
        _showErrorIfAny(provider);

        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _applyFilter,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              TextField(
                controller: _filterController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _applyFilter(),
                decoration: InputDecoration(
                  labelText: 'Filter by item name',
                  hintText: 'e.g. Milk',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _applyFilter,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (provider.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('No prices captured yet.')),
                )
              else
                ...provider.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PriceHistoryTile(
                      item: item,
                      onDelete: () => _deleteItem(context, item),
                      onConfirmDelete: () => _confirmDelete(context, item),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, ItemPriceModel item) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Price Entry'),
            content: Text('Delete "${item.itemName}" from your price history?'),
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

  Future<void> _deleteItem(BuildContext context, ItemPriceModel item) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await context.read<PriceHistoryProvider>().deleteItem(
      item.id,
    );
    if (!mounted || !success) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Deleted "${item.itemName}"')),
    );
  }

  void _showErrorIfAny(PriceHistoryProvider provider) {
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

class _BestPricesTab extends StatefulWidget {
  final ValueChanged<BestPriceSummaryModel> onOpenHistoryForItem;

  const _BestPricesTab({required this.onOpenHistoryForItem});

  @override
  State<_BestPricesTab> createState() => _BestPricesTabState();
}

class _BestPricesTabState extends State<_BestPricesTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BestPriceSummaryProvider>(
      builder: (context, provider, _) {
        _showErrorIfAny(provider);

        return RefreshIndicator(
          onRefresh: provider.loadSummary,
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
                  child: Center(child: Text('No prices captured yet.')),
                )
              else
                ...provider.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        title: Text(item.itemName),
                        subtitle: Text(item.storeName ?? 'Unknown store'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_formatCurrency(item.lowestPrice)),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Best store details',
                              onPressed:
                                  item.canonicalItemId == null ||
                                          item.canonicalItemId!.trim().isEmpty
                                      ? null
                                      : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (_) => BestStoreScreen(
                                                canonicalItemId:
                                                    item.canonicalItemId!,
                                                itemName: item.itemName,
                                              ),
                                        ),
                                      ),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        onTap: () => widget.onOpenHistoryForItem(item),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorIfAny(BestPriceSummaryProvider provider) {
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

String _formatCurrency(double value) {
  return '\$${value.toStringAsFixed(2)}';
}

class _PriceHistoryTile extends StatelessWidget {
  final ItemPriceModel item;
  final Future<bool> Function() onConfirmDelete;
  final VoidCallback onDelete;

  const _PriceHistoryTile({
    required this.item,
    required this.onConfirmDelete,
    required this.onDelete,
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
      confirmDismiss: (_) => onConfirmDelete(),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: ListTile(
          title: Text(item.itemName),
          subtitle: Text(
            '${item.storeName ?? 'Unknown store'}'
            ' • ${item.unit ?? 'unit n/a'}'
            ' • ${_formatCapturedAt(item.capturedAt)}',
          ),
          trailing: Text(
            _formatCurrency(item.price),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  String _formatCapturedAt(DateTime capturedAt) {
    final now = DateTime.now();
    final localTime = capturedAt.toLocal();
    final diff = now.difference(localTime);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    final month = _monthName(localTime.month);
    final day = localTime.day.toString().padLeft(2, '0');
    final year = localTime.year.toString();
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  String _monthName(int month) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final idx = (month - 1).clamp(0, 11);
    return months[idx];
  }
}
