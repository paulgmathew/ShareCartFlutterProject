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
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  final _storeController = TextEditingController();
  ReceiptScanType _scanType = ReceiptScanType.receipt;

  @override
  void dispose() {
    _itemNameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _storeController.dispose();
    super.dispose();
  }

  Future<void> _captureAndScan() async {
    final provider = context.read<PriceProvider>();
    await provider.scanImage(scanType: _scanType);
    if (!mounted) return;

    _itemNameController.text = provider.itemNameGuess;
    _priceController.text =
        provider.detectedPrice != null
            ? provider.detectedPrice!.toStringAsFixed(2)
            : '';
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
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PriceProvider>();
    await provider.confirmPrice(
      itemName: _itemNameController.text,
      priceText: _priceController.text,
      unit: _unitController.text,
      storeName: _storeController.text,
      compareAfterConfirm: true,
    );
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
                      'Extracted Items',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.extractedItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = provider.extractedItems[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                              [
                                if (item.quantity != null &&
                                    item.quantity!.trim().isNotEmpty)
                                  'Qty: ${item.quantity!.trim()}',
                                if (item.unit != null &&
                                    item.unit!.trim().isNotEmpty)
                                  'Unit: ${item.unit!.trim()}',
                                if (item.confidence != null)
                                  'Confidence: ${item.confidence!.toStringAsFixed(2)}',
                              ].join(' · '),
                            ),
                            trailing:
                                item.price == null
                                    ? null
                                    : Text(
                                      '\$${item.price!.toStringAsFixed(2)}',
                                    ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _itemNameController,
                          decoration: const InputDecoration(
                            labelText: 'Item Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Item name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            hintText: 'e.g. 3.49',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            final parsed = double.tryParse(
                              (value ?? '').trim(),
                            );
                            if (parsed == null) {
                              return 'Enter a valid numeric price';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            hintText: 'e.g. 1L, 500g, each',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Unit is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value:
                              stores.any(
                                    (s) =>
                                        s.name == _storeController.text.trim(),
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
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Store name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: provider.loading ? null : _confirm,
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
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
}
