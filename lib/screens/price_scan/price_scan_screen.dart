import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/canonical_item_model.dart';
import '../../models/confirm_prices_request_model.dart';
import '../../models/receipt_extraction_model.dart';
import '../../providers/price_provider.dart';
import '../../services/price_api_service.dart';
import '../../services/receipt_extraction_api_service.dart';
import '../../widgets/canonical_item_picker.dart';

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

    setState(() {
      _rebuildEditableItems(provider.extractedItems);
      _storeController.text = provider.storeName ?? '';
    });

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

    final confirmedItems = <ConfirmPriceItem>[];
    for (var index = 0; index < _editableItems.length; index++) {
      final item = _editableItems[index];
      if (item.isBlank) {
        continue;
      }

      final validationMessage = item.validationMessage();
      if (validationMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item ${index + 1}: $validationMessage')),
        );
        return;
      }

      confirmedItems.add(item.toConfirmPriceItem());
    }

    if (confirmedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one item before confirming'),
        ),
      );
      return;
    }

    final provider = context.read<PriceProvider>();
    await provider.confirmPrices(storeName: storeName, items: confirmedItems);

    if (!mounted) return;

    if (provider.errorMessage != null) {
      _showErrorIfAny(provider);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prices confirmed successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PriceProvider>(
      builder: (context, provider, _) {
        final canEditItems =
            provider.imagePath != null || _editableItems.isNotEmpty;

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
                  if (canEditItems) ...[
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
                                Row(
                                  children: [
                                    Text(
                                      'Item ${index + 1}',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.labelLarge,
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Delete item',
                                      onPressed: () => _removeItemAt(index),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                CanonicalItemPicker(
                                  controller: item.itemNameController,
                                  initialSearchText:
                                      item.itemNameController.text,
                                  labelText: 'Item Name',
                                  hintText: 'e.g. Milk',
                                  onSelected: (selected) {
                                    setState(() {
                                      item.selectedCanonicalItem = selected;
                                    });
                                  },
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
                                        controller: item.quantityController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: const InputDecoration(
                                          labelText: 'Quantity',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: item.unitController,
                                  decoration: const InputDecoration(
                                    labelText: 'Unit',
                                    border: OutlineInputBorder(),
                                  ),
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
                      TextFormField(
                        controller: _storeController,
                        decoration: const InputDecoration(
                          labelText: 'Store Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: provider.loading ? null : _confirm,
                        child: const Text('Confirm Prices'),
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

  void _removeItemAt(int index) {
    final item = _editableItems[index];
    item.dispose();
    setState(() {
      final updatedItems = List<_EditableExtractedItem>.from(_editableItems);
      updatedItems.removeAt(index);
      _editableItems = updatedItems;
    });
  }
}

class _EditableExtractedItem {
  CanonicalItemModel? selectedCanonicalItem;
  final TextEditingController itemNameController;
  final TextEditingController priceController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final String helperText;
  final double? confidence;
  final bool manuallyAdded;
  final String _initialItemName;
  final double? _initialPrice;
  final int _initialQuantity;
  final String _initialUnit;

  _EditableExtractedItem({
    required this.itemNameController,
    required this.priceController,
    required this.quantityController,
    required this.unitController,
    required this.helperText,
    required this.confidence,
    required this.manuallyAdded,
    required String initialItemName,
    required double? initialPrice,
    required int initialQuantity,
    required String initialUnit,
  }) : _initialItemName = initialItemName,
       _initialPrice = initialPrice,
       _initialQuantity = initialQuantity,
       _initialUnit = initialUnit;

  factory _EditableExtractedItem.fromExtraction(
    ReceiptExtractionItemModel item,
  ) {
    final quantity = _parseQuantity(item.quantity) ?? 1;
    final unit =
        (item.unit == null || item.unit!.trim().isEmpty)
            ? 'each'
            : item.unit!.trim();
    final helperBits = <String>[];
    if (item.confidence != null) {
      helperBits.add('Confidence: ${item.confidence!.toStringAsFixed(2)}');
    }

    return _EditableExtractedItem(
      itemNameController: TextEditingController(text: item.name),
      priceController: TextEditingController(
        text: item.price == null ? '' : item.price!.toStringAsFixed(2),
      ),
      quantityController: TextEditingController(
        text: _formatQuantity(quantity),
      ),
      unitController: TextEditingController(text: unit),
      helperText: helperBits.join(' · '),
      confidence: item.confidence,
      manuallyAdded: false,
      initialItemName: item.name,
      initialPrice: item.price,
      initialQuantity: quantity,
      initialUnit: unit,
    );
  }

  factory _EditableExtractedItem.empty() {
    return _EditableExtractedItem(
      itemNameController: TextEditingController(),
      priceController: TextEditingController(),
      quantityController: TextEditingController(text: '1'),
      unitController: TextEditingController(text: 'each'),
      helperText: '',
      confidence: null,
      manuallyAdded: true,
      initialItemName: '',
      initialPrice: null,
      initialQuantity: 1,
      initialUnit: 'each',
    );
  }

  bool get isBlank =>
      itemNameController.text.trim().isEmpty &&
      priceController.text.trim().isEmpty;

  String? validationMessage() {
    if (isBlank) return null;

    if (itemNameController.text.trim().isEmpty) {
      return 'Item name is required';
    }

    final price = double.tryParse(priceController.text.trim());
    if (price == null) {
      return 'Enter a valid price';
    }

    final quantity = _parseQuantity(quantityController.text);
    if (quantity == null || quantity <= 0) {
      return 'Enter a valid quantity';
    }

    if (quantityController.text.trim().contains('.')) {
      return 'Quantity must be a whole number';
    }

    if (unitController.text.trim().isEmpty) {
      return 'Unit is required';
    }

    return null;
  }

  ConfirmPriceItem toConfirmPriceItem() {
    final price = double.parse(priceController.text.trim());
    final quantity = _parseQuantity(quantityController.text) ?? 1;
    return ConfirmPriceItem(
      itemName: itemNameController.text.trim(),
      canonicalItemId: selectedCanonicalItem?.id,
      price: price,
      quantity: quantity,
      unit: unitController.text.trim(),
      confidence: confidence,
      edited: manuallyAdded || _hasChanges(price, quantity),
    );
  }

  bool _hasChanges(double currentPrice, int currentQuantity) {
    if (itemNameController.text.trim() != _initialItemName.trim()) return true;
    if (unitController.text.trim() != _initialUnit.trim()) return true;
    if ((_initialPrice ?? -1) != currentPrice) return true;
    return _initialQuantity != currentQuantity;
  }

  void dispose() {
    itemNameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    unitController.dispose();
  }

  static int? _parseQuantity(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  static String _formatQuantity(int quantity) {
    return quantity.toString();
  }
}
