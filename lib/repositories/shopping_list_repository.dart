import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/services.dart';

class ShoppingListRepository {
  final ShoppingListApiService _listService;
  final ItemApiService _itemService;
  final SharedPreferences _prefs;

  static const _savedListIdsKey = 'saved_list_ids';

  ShoppingListRepository({
    required ShoppingListApiService listService,
    required ItemApiService itemService,
    required SharedPreferences prefs,
  }) : _listService = listService,
       _itemService = itemService,
       _prefs = prefs;

  // --- Local list ID persistence ---

  List<String> getSavedListIds() {
    return _prefs.getStringList(_savedListIdsKey) ?? [];
  }

  Future<void> saveListId(String listId) async {
    final ids = getSavedListIds();
    if (!ids.contains(listId)) {
      ids.add(listId);
      await _prefs.setStringList(_savedListIdsKey, ids);
    }
  }

  Future<void> removeListId(String listId) async {
    final ids = getSavedListIds();
    ids.remove(listId);
    await _prefs.setStringList(_savedListIdsKey, ids);
  }

  // --- Shopping List API ---

  Future<ShoppingListModel> createList(String name, {String? ownerId}) async {
    final list = await _listService.createList(name, ownerId: ownerId);
    await saveListId(list.id);
    return list;
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
