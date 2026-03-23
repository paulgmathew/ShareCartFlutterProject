import '../models/shopping_list_model.dart';
import '../models/shopping_list_summary_model.dart';
import 'api_client.dart';

class ShoppingListApiService {
  final ApiClient _apiClient;

  ShoppingListApiService(this._apiClient);

  Future<List<ShoppingListSummaryModel>> getMyLists() async {
    final list = await _apiClient.getList('/lists/me');
    return list
        .map(
          (e) => ShoppingListSummaryModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ShoppingListModel> createList(String name) async {
    final body = <String, dynamic>{'name': name};
    final json = await _apiClient.post('/lists', body: body);
    return ShoppingListModel.fromJson(json);
  }

  Future<ShoppingListModel> getListById(String listId) async {
    final json = await _apiClient.get('/lists/$listId');
    return ShoppingListModel.fromJson(json);
  }

  Future<void> inviteUser(String listId, String userId, {String? role}) async {
    final body = <String, dynamic>{'userId': userId};
    if (role != null) body['role'] = role;

    await _apiClient.post('/lists/$listId/invite', body: body);
  }
}
