import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/canonical_item_model.dart';
import '../services/catalog_api_service.dart';

class CanonicalItemPicker extends StatefulWidget {
  final TextEditingController controller;
  final String? initialSearchText;
  final String labelText;
  final String? hintText;
  final ValueChanged<CanonicalItemModel?> onSelected;

  const CanonicalItemPicker({
    super.key,
    required this.controller,
    required this.onSelected,
    this.initialSearchText,
    this.labelText = 'Item Name',
    this.hintText,
  });

  @override
  State<CanonicalItemPicker> createState() => _CanonicalItemPickerState();
}

class _CanonicalItemPickerState extends State<CanonicalItemPicker> {
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<CanonicalItemModel> _matches = const [];
  bool _loading = false;
  String? _errorMessage;
  CanonicalItemModel? _selectedItem;

  @override
  void initState() {
    super.initState();
    if (widget.controller.text.isEmpty &&
        widget.initialSearchText != null &&
        widget.initialSearchText!.trim().isNotEmpty) {
      widget.controller.text = widget.initialSearchText!.trim();
    }
    widget.controller.addListener(_onTextChanged);
    if (widget.controller.text.trim().isNotEmpty) {
      _search(widget.controller.text.trim());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text.trim();
    if (_selectedItem != null && _selectedItem!.name.trim() != text) {
      _selectedItem = null;
      widget.onSelected(null);
    }
    _debounce?.cancel();
    if (text.isEmpty) {
      setState(() {
        _matches = const [];
        _errorMessage = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _search(text);
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final rawResults = await context.read<CatalogApiService>().searchCatalog(
        query,
      );
      final results = rawResults
          .map((json) => CanonicalItemModel.fromJson(json))
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _matches = results;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not search catalog.';
        _matches = const [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _selectExisting(CanonicalItemModel item) async {
    setState(() {
      _selectedItem = item;
      widget.controller.text = item.name;
      widget.controller.selection = TextSelection.collapsed(
        offset: item.name.length,
      );
      _matches = const [];
      _errorMessage = null;
    });
    widget.onSelected(item);
  }

  Future<void> _addNew(String query) async {
    final rawResults = await context
        .read<CatalogApiService>()
        .createCatalogItem(query, null);
    final created = CanonicalItemModel.fromJson(rawResults);
    if (!mounted) return;
    await _selectExisting(created);
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.controller.text.trim();
    final showAddNew = query.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText ?? 'e.g. Milk',
            border: const OutlineInputBorder(),
            suffixIcon:
                _loading
                    ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _search(query),
                    ),
          ),
          onFieldSubmitted: (_) => _search(widget.controller.text.trim()),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_matches.isNotEmpty || showAddNew) ...[
          const SizedBox(height: 8),
          Card(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ..._matches.map(
                    (item) => ListTile(
                      title: Text(item.name),
                      subtitle:
                          item.category != null && item.category!.isNotEmpty
                              ? Text(item.category!)
                              : null,
                      onTap: () => _selectExisting(item),
                    ),
                  ),
                  if (showAddNew)
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: Text('+ Add "$query" as new item'),
                      onTap: () => _addNew(query),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
