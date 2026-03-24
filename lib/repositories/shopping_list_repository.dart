import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/services.dart';

class ShoppingListRepository {
  final ShoppingListApiService _listService;
  final ItemApiService _itemService;
  // ignore: unused_field
  final SharedPreferences _prefs;

  ShoppingListRepository({
    required ShoppingListApiService listService,
    required ItemApiService itemService,
    required SharedPreferences prefs,
  }) : _listService = listService,
       _itemService = itemService,
       _prefs = prefs;

  // --- Shopping List API ---

  Future<List<ShoppingListSummaryModel>> getMyLists() async {
    return _listService.getMyLists();
  }

  Future<ShoppingListModel> createList(String name) async {
    return _listService.createList(name);
  }

  Future<ShoppingListModel> getListById(String listId) async {
    return _listService.getListById(listId);
  }

  Future<void> inviteUser(String listId, String userId, {String? role}) async {
    await _listService.inviteUser(listId, userId, role: role);
  }

  // --- Item API ---

  Future<ItemModel> addItem(
    String listId, {
    required String name,
    String? quantity,
    String? category,
    String? createdBy,
  }) async {
    return _itemService.addItem(
      listId,
      name: name,
      quantity: quantity,
      category: category,
      createdBy: createdBy,
    );
  }

  Future<ItemModel> updateItem(
    String itemId, {
    String? name,
    String? quantity,
    bool? isCompleted,
    String? category,
  }) async {
    return _itemService.updateItem(
      itemId,
      name: name,
      quantity: quantity,
      isCompleted: isCompleted,
      category: category,
    );
  }

  Future<void> deleteItem(String itemId) async {
    await _itemService.deleteItem(itemId);
  }
}
