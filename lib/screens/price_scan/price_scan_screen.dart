import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/receipt_extraction_model.dart';
import '../../providers/price_provider.dart';
import '../../services/price_api_service.dart';
import '../../services/receipt_extraction_api_service.dart';

class PriceScanScreen extends StatelessWidget {
  const PriceScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (ctx) => PriceProvider(
            ctx.read<ReceiptExtractionApiService>(),
            ctx.read<PriceApiService>(),
          ),
      child: const _PriceScanBody(),
    );
  }
}

class _PriceScanBody extends StatefulWidget {
  const _PriceScanBody();

  @override
  State<_PriceScanBody> createState() => _PriceScanBodyState();
}

class _PriceScanBodyState extends State<_PriceScanBody> {
  final _storeController = TextEditingController();
  ReceiptScanType _scanType = ReceiptScanType.receipt;
  List<_EditableExtractedItem> _editableItems = const [];

  @override
  void dispose() {
    for (final item in _editableItems) {
      item.dispose();
    }
    _storeController.dispose();
    super.dispose();
  }

  Future<void> _captureAndScan() async {
    final provider = context.read<PriceProvider>();
    await provider.scanImage(scanType: _scanType);
    if (!mounted) return;

    _rebuildEditableItems(provider.extractedItems);
    _storeController.text = provider.selectedStore ?? '';

    _showErrorIfAny(provider);
  }

  Future<void> _fetchStores() async {
    final provider = context.read<PriceProvider>();
    await provider.fetchNearbyStores();
    if (!mounted) return;

    if (_storeController.text.trim().isEmpty &&
        provider.selectedStore != null) {
      _storeController.text = provider.selectedStore!;
    }

    _showErrorIfAny(provider);
  }

  Future<void> _confirm() async {
    final storeName = _storeController.text.trim();
    if (storeName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Store name is required')));
      return;
    }

    final validItems = <_EditableExtractedItem>[];
    for (final item in _editableItems) {
      final name = item.itemNameController.text.trim();
      final priceText = item.priceController.text.trim();
      final unit = item.unitController.text.trim();

      if (name.isEmpty || unit.isEmpty || double.tryParse(priceText) == null) {
        continue;
      }
      validItems.add(item);
    }

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least one valid item with name, price, and unit',
          ),
        ),
      );
      return;
    }

    final provider = context.read<PriceProvider>();
    for (var index = 0; index < validItems.length; index++) {
      final item = validItems[index];
      await provider.confirmPrice(
        itemName: item.itemNameController.text,
        priceText: item.priceController.text,
        unit: item.unitController.text,
        storeName: storeName,
        compareAfterConfirm: index == validItems.length - 1,
      );

      if (provider.errorMessage != null) {
        break;
      }
    }

    if (!mounted) return;

    if (provider.errorMessage != null) {
      _showErrorIfAny(provider);
      return;
    }

    final compareText = provider.compareMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          compareText == null
              ? 'Price confirmed successfully.'
              : 'Price confirmed. $compareText',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PriceProvider>(
      builder: (context, provider, _) {
        final stores = provider.nearbyStores;

        return Scaffold(
          appBar: AppBar(title: const Text('Capture Price')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<ReceiptScanType>(
                    value: _scanType,
                    decoration: const InputDecoration(
                      labelText: 'Scan Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ReceiptScanType.receipt,
                        child: Text('Receipt'),
                      ),
                      DropdownMenuItem(
                        value: ReceiptScanType.priceTag,
                        child: Text('Price Tag'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _scanType = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: provider.loading ? null : _captureAndScan,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capture with AI'),
                  ),
                  const SizedBox(height: 12),
                  if (provider.imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(provider.imagePath!),
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (provider.imagePath != null) const SizedBox(height: 12),
                  if (provider.loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  Text(
                    'AI Extracted Summary',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(minHeight: 90),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      provider.extractedText.isEmpty
                          ? 'No image processed yet. Capture a receipt or price tag to begin.'
                          : provider.extractedText,
                    ),
                  ),
                  if (provider.extractedItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Extracted Items (Editable)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _editableItems.length,
                        itemBuilder: (context, index) {
                          final item = _editableItems[index];
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Item ${index + 1}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: item.itemNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Item Name',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: item.priceController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: const InputDecoration(
                                          labelText: 'Price',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: item.unitController,
                                        decoration: const InputDecoration(
                                          labelText: 'Unit',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.helperText.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    item.helperText,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                                if (index < _editableItems.length - 1)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Divider(height: 1),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _editableItems = [
                            ..._editableItems,
                            _EditableExtractedItem.empty(),
                          ];
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item Row'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value:
                            stores.any(
                                  (s) => s.name == _storeController.text.trim(),
                                )
                                ? _storeController.text.trim()
                                : null,
                        items:
                            stores
                                .map(
                                  (store) => DropdownMenuItem(
                                    value: store.name,
                                    child: Text(
                                      store.distanceLabel == null
                                          ? store.name
                                          : '${store.name} (${store.distanceLabel})',
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          provider.setSelectedStore(value);
                          _storeController.text = value ?? '';
                        },
                        decoration: const InputDecoration(
                          labelText: 'Nearby Store (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: provider.loading ? null : _fetchStores,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Refresh Nearby Stores'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _storeController,
                        decoration: const InputDecoration(
                          labelText: 'Store (manual)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: provider.loading ? null : _confirm,
                        child: const Text('Confirm All Valid Items'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showErrorIfAny(PriceProvider provider) {
    final message = provider.errorMessage;
    if (message == null || message.isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    provider.clearError();
  }

  void _rebuildEditableItems(List<ReceiptExtractionItemModel> items) {
    for (final item in _editableItems) {
      item.dispose();
    }
    _editableItems = items
        .map(_EditableExtractedItem.fromExtraction)
        .toList(growable: false);
  }
}

class _EditableExtractedItem {
  final TextEditingController itemNameController;
  final TextEditingController priceController;
  final TextEditingController unitController;
  final String helperText;

  _EditableExtractedItem({
    required this.itemNameController,
    required this.priceController,
    required this.unitController,
    required this.helperText,
  });

  factory _EditableExtractedItem.fromExtraction(
    ReceiptExtractionItemModel item,
  ) {
    final helperBits = <String>[];
    if (item.quantity != null && item.quantity!.trim().isNotEmpty) {
      helperBits.add('Qty: ${item.quantity!.trim()}');
    }
    if (item.confidence != null) {
      helperBits.add('Confidence: ${item.confidence!.toStringAsFixed(2)}');
    }

    return _EditableExtractedItem(
      itemNameController: TextEditingController(text: item.name),
      priceController: TextEditingController(
        text: item.price == null ? '' : item.price!.toStringAsFixed(2),
      ),
      unitController: TextEditingController(text: item.unit ?? 'each'),
      helperText: helperBits.join(' · '),
    );
  }

  factory _EditableExtractedItem.empty() {
    return _EditableExtractedItem(
      itemNameController: TextEditingController(),
      priceController: TextEditingController(),
      unitController: TextEditingController(text: 'each'),
      helperText: '',
    );
  }

  void dispose() {
    itemNameController.dispose();
    priceController.dispose();
    unitController.dispose();
  }
}
