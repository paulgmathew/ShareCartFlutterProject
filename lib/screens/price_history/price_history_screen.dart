import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/price_history_provider.dart';
import '../../services/price_api_service.dart';

class PriceHistoryScreen extends StatelessWidget {
  const PriceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => PriceHistoryProvider(ctx.read<PriceApiService>()),
      child: const _PriceHistoryBody(),
    );
  }
}

class _PriceHistoryBody extends StatefulWidget {
  const _PriceHistoryBody();

  @override
  State<_PriceHistoryBody> createState() => _PriceHistoryBodyState();
}

class _PriceHistoryBodyState extends State<_PriceHistoryBody> {
  final _filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PriceHistoryProvider>().loadHistory();
    });
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

        return Scaffold(
          appBar: AppBar(title: const Text('Price History')),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
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
                ),
                Expanded(child: _buildContent(provider)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(PriceHistoryProvider provider) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.items.isEmpty) {
      return const Center(child: Text('No prices captured yet'));
    }

    return RefreshIndicator(
      onRefresh: _applyFilter,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: provider.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = provider.items[index];
          return Card(
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
          );
        },
      ),
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
