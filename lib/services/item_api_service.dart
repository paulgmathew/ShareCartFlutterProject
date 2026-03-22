import '../models/item_model.dart';
import 'api_client.dart';

class ItemApiService {
  final ApiClient _apiClient;

  ItemApiService(this._apiClient);

  Future<ItemModel> addItem(
    String listId, {
    required String name,
    String? quantity,
    String? category,
    String? createdBy,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (quantity != null) body['quantity'] = quantity;
    if (category != null) body['category'] = category;
    if (createdBy != null) body['createdBy'] = createdBy;

    final json = await _apiClient.post('/lists/$listId/items', body: body);
    return ItemModel.fromJson(json);
  }

  Future<ItemModel> updateItem(
    String itemId, {
    String? name,
    String? quantity,
    bool? isCompleted,
    String? category,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (quantity != null) body['quantity'] = quantity;
    if (isCompleted != null) body['isCompleted'] = isCompleted;
    if (category != null) body['category'] = category;

    final json = await _apiClient.put('/items/$itemId', body: body);
    return ItemModel.fromJson(json);
  }

  Future<void> deleteItem(String itemId) async {
    await _apiClient.delete('/items/$itemId');
  }
}
