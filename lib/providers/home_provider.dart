import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/shopping_list_repository.dart';
import '../services/api_client.dart';

class HomeProvider extends ChangeNotifier {
  final ShoppingListRepository _repository;

  HomeProvider(this._repository) {
    _loadSavedLists();
  }

  List<ShoppingListModel> _lists = [];
  List<ShoppingListModel> get lists => _lists;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> _loadSavedLists() async {
    final ids = _repository.getSavedListIds();
    if (ids.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final loaded = <ShoppingListModel>[];
    for (final id in ids) {
      try {
        loaded.add(await _repository.getListById(id));
      } on ApiException {
        // List may have been deleted on backend; skip it
      }
    }
    _lists = loaded;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadSavedLists();
  }

  Future<ShoppingListModel> createList(String name, {String? ownerId}) async {
    try {
      final list = await _repository.createList(name, ownerId: ownerId);
      _lists.add(list);
      notifyListeners();
      return list;
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> openListById(String listId) async {
    try {
      final list = await _repository.getListById(listId);
      await _repository.saveListId(listId);
      if (!_lists.any((l) => l.id == listId)) {
        _lists.add(list);
        notifyListeners();
      }
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeList(String listId) async {
    await _repository.removeListId(listId);
    _lists.removeWhere((l) => l.id == listId);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
