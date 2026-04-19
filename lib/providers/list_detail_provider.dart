import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/shopping_list_repository.dart';
import '../services/api_client.dart';
import '../services/realtime_sync_service.dart';

class ListDetailProvider extends ChangeNotifier {
  final ShoppingListRepository _repository;
  final RealtimeSyncService _realtimeSyncService;

  StreamSubscription<ListRealtimeEventModel>? _eventSubscription;
  StreamSubscription<String>? _resyncSubscription;
  bool _isDisposed = false;
  String? _activeListId;

  ListDetailProvider(this._repository, this._realtimeSyncService);

  ShoppingListModel? _shoppingList;
  ShoppingListModel? get shoppingList => _shoppingList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadList(String listId) async {
    _activeListId = listId;
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _shoppingList = await _repository.getListById(listId);
      await _startRealtimeForList(listId);
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
    }

    _isLoading = false;
    _safeNotifyListeners();
  }

  Future<void> addItem({
    required String name,
    String? quantity,
    String? category,
    String? createdBy,
  }) async {
    if (_shoppingList == null) return;

    try {
      await _repository.addItem(
        _shoppingList!.id,
        name: name,
        quantity: quantity,
        category: category,
        createdBy: createdBy,
      );
      await loadList(_shoppingList!.id);
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
      _safeNotifyListeners();
      rethrow;
    }
  }

  Future<void> updateItem(
    String itemId, {
    String? name,
    String? quantity,
    bool? isCompleted,
    String? category,
  }) async {
    if (_shoppingList == null) return;

    try {
      await _repository.updateItem(
        itemId,
        name: name,
        quantity: quantity,
        isCompleted: isCompleted,
        category: category,
      );
      await loadList(_shoppingList!.id);
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
      _safeNotifyListeners();
      rethrow;
    }
  }

  Future<void> toggleItemCompleted(ItemModel item) async {
    await updateItem(item.id, isCompleted: !item.isCompleted);
  }

  Future<void> deleteItem(String itemId) async {
    if (_shoppingList == null) return;

    try {
      await _repository.deleteItem(itemId);
      await loadList(_shoppingList!.id);
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
      _safeNotifyListeners();
      rethrow;
    }
  }

  Future<void> inviteUser(String userId, {String? role}) async {
    if (_shoppingList == null) return;

    try {
      await _repository.inviteUser(_shoppingList!.id, userId, role: role);
      await loadList(_shoppingList!.id);
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
      _safeNotifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    final listId = _activeListId;
    if (listId != null) {
      _realtimeSyncService.unsubscribeFromList(listId);
    }
    _eventSubscription?.cancel();
    _resyncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startRealtimeForList(String listId) async {
    try {
      await _realtimeSyncService.subscribeToList(listId);
    } catch (_) {
      return;
    }

    _eventSubscription ??= _realtimeSyncService.events.listen((event) {
      if (event.listId != _activeListId) return;
      _applyRealtimeEvent(event);
    });

    _resyncSubscription ??= _realtimeSyncService.resyncRequests.listen((id) {
      if (id != _activeListId) return;
      unawaited(loadList(id));
    });
  }

  void _applyRealtimeEvent(ListRealtimeEventModel event) {
    final current = _shoppingList;
    if (current == null) return;

    final items = List<ItemModel>.from(current.items);
    final itemIndex = items.indexWhere((i) => i.id == event.item.id);

    switch (event.eventType) {
      case 'ITEM_ADDED':
        if (itemIndex == -1) {
          items.add(event.item);
        }
        break;
      case 'ITEM_UPDATED':
        if (itemIndex == -1) {
          unawaited(loadList(event.listId));
          return;
        }
        items[itemIndex] = event.item;
        break;
      case 'ITEM_DELETED':
        if (itemIndex == -1) {
          return;
        }
        items.removeAt(itemIndex);
        break;
      default:
        unawaited(loadList(event.listId));
        return;
    }

    _shoppingList = ShoppingListModel(
      id: current.id,
      name: current.name,
      ownerId: current.ownerId,
      ownerName: current.ownerName,
      items: items,
      members: current.members,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
    );
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (_isDisposed) return;
    notifyListeners();
  }
}
