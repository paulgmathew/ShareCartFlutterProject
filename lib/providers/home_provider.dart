import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/shopping_list_repository.dart';
import '../services/api_client.dart';

class HomeProvider extends ChangeNotifier {
  final ShoppingListRepository _repository;

  HomeProvider(this._repository) {
    _loadMyLists();
  }

  List<ShoppingListSummaryModel> _lists = [];
  List<ShoppingListSummaryModel> get lists => _lists;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> _loadMyLists() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lists = await _repository.getMyLists();
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _loadMyLists();
  }

  Future<String> createList(String name) async {
    try {
      final list = await _repository.createList(name);
      await _loadMyLists();
      return list.id;
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> openListById(String listId) async {
    try {
      await _repository.getListById(listId);
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
