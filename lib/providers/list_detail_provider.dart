import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/shopping_list_repository.dart';
import '../services/api_client.dart';

class ListDetailProvider extends ChangeNotifier {
  final ShoppingListRepository _repository;

  ListDetailProvider(this._repository);

  ShoppingListModel? _shoppingList;
  ShoppingListModel? get shoppingList => _shoppingList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadList(String listId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _shoppingList = await _repository.getListById(listId);
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
    }

    _isLoading = false;
    notifyListeners();
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
      notifyListeners();
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
      notifyListeners();
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
      notifyListeners();
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
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
