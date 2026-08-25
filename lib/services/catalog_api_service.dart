import 'api_client.dart';

class CatalogApiService {
  final ApiClient _apiClient;

  CatalogApiService(this._apiClient);

  Future<List<Map<String, dynamic>>> searchCatalog(String query) async {
    final trimmedQuery = query.trim();
    final path =
        trimmedQuery.isEmpty
            ? '/catalog/items'
            : '/catalog/items?query=${Uri.encodeQueryComponent(trimmedQuery)}';
    final response = await _apiClient.getList(path);
    return response
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> createCatalogItem(
    String name,
    String? description,
  ) async {
    final body = <String, dynamic>{'name': name};
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }

    return _apiClient.post('/catalog/items', body: body);
  }
}
